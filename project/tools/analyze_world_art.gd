extends SceneTree
## Developer tool: measures Bailey's World_Building art so the map code can use it
## without guessing (planet circle size, main colour of each picture, where the sun
## is in each solar-system picture, where the 10 painted galaxies are).
## Run:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/analyze_world_art.gd
## Prints numbers to paste into scripts/meta/map_art.gd.

const DIR := "res://assets/maps/"
const WORLDS := ["world_desert", "world_forest", "world_ice", "world_ocean", "world_volcanic"]
const BACKS := ["universe_01", "galaxy_a_barred_spiral", "galaxy_b_spiral", "system_a", "system_b", "system_c"]
## First guesses (in 1024 px) for the painted galaxies in universe_01, refined below.
const GALAXY_GUESS := [Vector2(515, 497), Vector2(640, 150), Vector2(885, 652), Vector2(322, 862),
	Vector2(110, 412), Vector2(255, 170), Vector2(138, 684), Vector2(922, 372), Vector2(748, 866), Vector2(915, 188)]


func _init() -> void:
	for n in WORLDS:
		var img := _img(n)
		var c := _planet_circle(img)
		print("%s  centre=(%.3f, %.3f) radius=%.3f  hue=%.3f" % [n, c.x, c.y, c.z, _main_hue(img, Vector2(c.x, c.y), c.z)])
	for n in BACKS:
		var img := _img(n)
		var line := "%s  hue=%.3f" % [n, _main_hue(img, Vector2(0.5, 0.5), 2.0)]
		if n.begins_with("system"):
			var s := _sun(img)
			line += "  sun=(%.3f, %.3f)" % [s.x, s.y]
		print(line)
	var uni := _img("universe_01")
	var w := float(uni.get_width())
	for g in GALAXY_GUESS:
		var p := _bright_centre(uni, g * w / 1024.0, 60.0 * w / 1024.0)
		var hue := _main_hue(uni, p / w, 75.0 / 1024.0)
		print("galaxy at (%.3f, %.3f)  dist=%.3f  hue=%.3f" % [p.x / w, p.y / w, (p / w).distance_to(Vector2(0.5, 0.5)), hue])
	quit()


func _img(n: String) -> Image:
	var tex: Texture2D = load(DIR + n + ".jpg")
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


## Checkerboard (fake transparency) pixels are pale grey with almost no colour.
func _is_checker(c: Color) -> bool:
	return c.s < 0.1 and c.v > 0.78


## Planet circle in 0-1 units: scan in from the 4 edges along the middle lines.
func _planet_circle(img: Image) -> Vector3:
	var w := img.get_width()
	var h := img.get_height()
	var left := _scan(img, Vector2i(0, h / 2), Vector2i(1, 0), w)
	var right := w - 1 - _scan(img, Vector2i(w - 1, h / 2), Vector2i(-1, 0), w)
	var top := _scan(img, Vector2i(w / 2, 0), Vector2i(0, 1), h)
	var bottom := h - 1 - _scan(img, Vector2i(w / 2, h - 1), Vector2i(0, -1), h)
	var cx := (left + right) * 0.5 / w
	var cy := (top + bottom) * 0.5 / h
	var r := ((right - left) / float(w) + (bottom - top) / float(h)) * 0.25
	return Vector3(cx, cy, r)


## Steps from `start` until 6 non-checker pixels in a row; returns the steps taken.
func _scan(img: Image, start: Vector2i, step: Vector2i, n: int) -> int:
	var run := 0
	for i in n:
		var p := start + step * i
		if _is_checker(img.get_pixelv(p)):
			run = 0
		else:
			run += 1
			if run >= 6:
				return i - 5
	return 0


## Main colour: the circular average of the hue, weighted by saturation x brightness.
func _main_hue(img: Image, centre: Vector2, radius: float) -> float:
	var w := img.get_width()
	var h := img.get_height()
	var sx := 0.0
	var sy := 0.0
	for y in range(0, h, 4):
		for x in range(0, w, 4):
			if Vector2(float(x) / w, float(y) / h).distance_to(centre) > radius:
				continue
			var c := img.get_pixel(x, y)
			if _is_checker(c):
				continue
			var wt := c.s * c.v
			sx += cos(c.h * TAU) * wt
			sy += sin(c.h * TAU) * wt
	return fposmod(atan2(sy, sx) / TAU, 1.0)


## Centre of the brightest pixels in the top-right quarter (the sun).
func _sun(img: Image) -> Vector2:
	var w := img.get_width()
	var h := img.get_height()
	var sum := Vector2.ZERO
	var n := 0.0
	for y in range(0, h / 2, 2):
		for x in range(w / 2, w, 2):
			var c := img.get_pixel(x, y)
			if c.v > 0.97 and c.s < 0.6:
				sum += Vector2(x, y)
				n += 1.0
	if n == 0.0:
		return Vector2(0.88, 0.1)
	return Vector2(sum.x / n / w, sum.y / n / h)


## Brightness-weighted centre of the pixels near a guess (a galaxy core).
func _bright_centre(img: Image, guess: Vector2, radius: float) -> Vector2:
	var sum := Vector2.ZERO
	var n := 0.0
	for y in range(int(guess.y - radius), int(guess.y + radius)):
		for x in range(int(guess.x - radius), int(guess.x + radius)):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			if Vector2(x, y).distance_to(guess) > radius:
				continue
			var v := img.get_pixel(x, y).v
			if v > 0.85:
				var wt := pow(v, 4.0)
				sum += Vector2(x, y) * wt
				n += wt
	return guess if n == 0.0 else sum / n
