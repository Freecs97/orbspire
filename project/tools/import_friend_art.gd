extends SceneTree
## Copies Bailey's friend character art (Friend_Character_Art/Friend_<Name>.png,
## 1024 px, transparent) into the game at 512 px, like every other character:
## res://assets/characters/friend/friend_<name>.png
## Developer tool. Run:  --headless --path . --quit-after 600 -s res://tools/import_friend_art.gd

const SRC := "C:/Users/User/Documents/General_Agent/Orbspire/orbspire-art-organized/characters/Friend_Character_Art/"
const NAMES := ["Jake", "Johnny", "Khoel", "Logan"]
const SIZE := 512


func _init() -> void:
	var out_dir := ProjectSettings.globalize_path("res://assets/characters/friend/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	for n in NAMES:
		var img := Image.load_from_file(SRC + "Friend_%s.png" % n)
		if img == null or img.is_empty():
			print("MISSING ", n)
			continue
		img.convert(Image.FORMAT_RGBA8)
		img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
		var path: String = out_dir + "friend_%s.png" % n.to_lower()
		img.save_png(path)
		print("Friend_%s.png -> %s" % [n, path.get_file()])
	quit()
