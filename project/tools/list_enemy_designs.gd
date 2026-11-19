extends SceneTree
## Developer tool: lists all 50 enemy designs (assets/enemies) with the size they
## are drawn at in the Acts (figure_height / width), so the exploration generator
## can use every design without scanning folders at run time.
## Run:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/list_enemy_designs.gd
## Paste the printed block into scripts/meta/enemy_designs.gd.

const ELEMENTS := {"fire": 0, "water": 1, "wood": 2, "light": 5, "dark": 6}


func _init() -> void:
	var sizes := {}
	for a in range(1, 11):
		var dir := "res://data/enemies/act%02d/" % a
		for f in DirAccess.get_files_at(dir):
			if not f.ends_with(".tres"):
				continue
			var d: FighterData = load(dir + f)
			if d.art == null or d.is_boss:
				continue
			var key := d.art.resource_path.get_file().get_basename()
			sizes[key] = Vector2(d.figure_height, d.figure_width)
	var lines := PackedStringArray()
	for f in DirAccess.get_files_at("res://assets/enemies/"):
		if not f.ends_with(".png"):
			continue
		var key := f.get_basename()
		var parts := key.split("_")
		var el: int = ELEMENTS[parts[1]]
		var name := " ".join(parts.slice(2)).to_upper()
		var sz: Vector2 = sizes.get(key, Vector2.ZERO)
		if sz == Vector2.ZERO:
			var tex: Texture2D = load("res://assets/enemies/" + f)
			var r := ArtBounds.opaque_rect(tex)
			sz = Vector2(260.0, roundf(260.0 * r.size.x / maxf(r.size.y, 1.0)))
		lines.append('\t"%s": [%d, "%s", %.0f, %.0f],' % [key, el, name, sz.x, sz.y])
	print("const DESIGNS := {\n" + "\n".join(lines) + "\n}")
	quit()
