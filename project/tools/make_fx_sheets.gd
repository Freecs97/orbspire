extends SceneTree
## Turns Bailey's 6 attack-animation strips (Attack_Animations/*.png, 1024x1024,
## 4 frames in a row, frames NOT evenly spaced) into the game's FX sheets:
## res://assets/fx/fx_<name>.png = 4 equal cells in a row, half resolution.
## Developer tool. Run:  --headless --path . --quit-after 600 -s res://tools/make_fx_sheets.gd
##
## Plain English, per strip:
##   1. find the 3 empty gaps between the 4 frames (columns with the fewest solid pixels)
##   2. cut each frame out and centre it in its own cell (same cell size for all 4)
##   3. keep every frame's height the same, so effects that grow from the ground stay put
##   4. soften the cut edges and the faint glow so no box edge shows in game
##   5. halve the size (they are drawn about 300 px tall on screen)

const SRC := "C:/Users/User/Documents/General_Agent/Orbspire/orbspire-art-organized/characters/Attack_Animations/"
## source file -> game sheet name (SkillFx.SHEET_FOR_ELEMENT / HEAL_SHEET)
const SHEETS := {
	"Fire_Animation": "fx_fire_slash", "Water_Animation": "fx_water_blast", "Wood_Animation": "fx_wood_thorn",
	"Light_Animation": "fx_light_burst", "Dark_Animation": "fx_dark_slash", "RCV_Animation": "fx_heal",
}
## Where to look for the gap between frames 1|2, 2|3 and 3|4 (source x).
const GAP_WINDOWS := [[110, 270], [370, 530], [730, 870]]
const SOLID := 160      ## alpha (0-255) that counts as "solid" art
const MARGIN := 24      ## px kept above / below the solid art
const FADE := 18.0      ## px of soft edge at every cut
const MAX_CELL := 440   ## widest cell (source px)


func _init() -> void:
	var out_dir := ProjectSettings.globalize_path("res://assets/fx/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	for src in SHEETS:
		var img := Image.load_from_file(SRC + src + ".png")
		if img == null or img.is_empty():
			print("MISSING ", src)
			continue
		img.convert(Image.FORMAT_RGBA8)
		# The heal strip has a faint white band behind it: cut more of the faint glow.
		var glow_cut: Array = [0.35, 0.6] if src.begins_with("RCV") else [0.04, 0.2]
		var sheet := _make_sheet(img, glow_cut)
		sheet.resize(sheet.get_width() / 2, sheet.get_height() / 2, Image.INTERPOLATE_LANCZOS)
		var path: String = out_dir + SHEETS[src] + ".png"
		sheet.save_png(path)
		print("%s -> %s  %dx%d (cell %dx%d)" % [src, SHEETS[src], sheet.get_width(), sheet.get_height(), sheet.get_width() / 4, sheet.get_height()])
	quit()


func _make_sheet(img: Image, glow_cut: Array) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	# Solid pixels per column (smoothed) and the solid rows.
	var cols := PackedFloat32Array()
	cols.resize(w)
	var y_lo := h
	var y_hi := 0
	for y in h:
		var row_n := 0
		for x in w:
			if data[(y * w + x) * 4 + 3] >= SOLID:
				cols[x] += 1.0
				row_n += 1
		if row_n > 3:
			y_lo = mini(y_lo, y)
			y_hi = maxi(y_hi, y)
	var smooth := PackedFloat32Array()
	smooth.resize(w)
	for x in w:
		var s := 0.0
		for k in range(maxi(x - 6, 0), mini(x + 7, w)):
			s += cols[k]
		smooth[x] = s
	# 1) the gaps between frames
	var cuts := [0]
	for win in GAP_WINDOWS:
		var best: int = win[0]
		for x in range(win[0], win[1]):
			if smooth[x] < smooth[best]:
				best = x
		# middle of the flat bottom, if the gap is a run of equal values
		var end := best
		while end + 1 < win[1] and is_equal_approx(smooth[end + 1], smooth[best]):
			end += 1
		cuts.append((best + end) / 2)
	cuts.append(w)
	# 2) each frame's solid centre, and the cell size
	var y0 := maxi(y_lo - MARGIN, 0)
	var y1 := mini(y_hi + MARGIN, h)
	var centers := []
	var cell_w := 0
	for f in 4:
		var x0: int = cuts[f]
		var x1: int = cuts[f + 1]
		var lo := x1
		var hi := x0
		for x in range(x0, x1):
			if cols[x] > 2.0:
				lo = mini(lo, x)
				hi = maxi(hi, x)
		var cx := (lo + hi) / 2 if hi >= lo else (x0 + x1) / 2
		centers.append(cx)
		cell_w = maxi(cell_w, 2 * maxi(cx - x0, x1 - cx))
	cell_w = mini(cell_w, MAX_CELL)
	cell_w += cell_w % 2
	var cell_h := y1 - y0
	var out := Image.create(cell_w * 4, cell_h, false, Image.FORMAT_RGBA8)
	var od := out.get_data()
	# 3+4) copy each frame, centred, with soft edges and less faint glow
	for f in 4:
		var x0: int = cuts[f]
		var x1: int = cuts[f + 1]
		var cx: int = centers[f]
		for y in range(y0, y1):
			var fy := minf(float(y - y0), float(y1 - 1 - y)) / FADE
			for x in range(x0, x1):
				var dx := x - cx + cell_w / 2
				if dx < 0 or dx >= cell_w:
					continue
				var si := (y * w + x) * 4
				var a := data[si + 3] / 255.0
				if a <= 0.0:
					continue
				var fx := minf(float(x - x0), float(x1 - 1 - x)) / FADE
				var edge := clampf(minf(fx, fy), 0.0, 1.0)
				a *= smoothstep(glow_cut[0], glow_cut[1], a) * edge
				var di := ((y - y0) * cell_w * 4 + f * cell_w + dx) * 4
				od[di] = data[si]
				od[di + 1] = data[si + 1]
				od[di + 2] = data[si + 2]
				od[di + 3] = clampi(roundi(a * 255.0), 0, 255)
	return Image.create_from_data(cell_w * 4, cell_h, false, Image.FORMAT_RGBA8, od)
