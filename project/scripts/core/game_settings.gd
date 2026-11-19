class_name GameSettings
extends RefCounted
## Player settings, kept apart from the save (a New Game keeps them).
## Saved to user://settings.json.
##   skill_cut_ins - the hunter's portrait flashes over the board when a skill is used

const DEFAULT_PATH := "user://settings.json"

static var skill_cut_ins := true
## Tests point this somewhere else so they never touch your real settings.
static var path := DEFAULT_PATH


static func load_settings() -> void:
	if not FileAccess.file_exists(path):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if d is Dictionary:
		skill_cut_ins = bool(d.get("skill_cut_ins", true))


static func save_settings() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"skill_cut_ins": skill_cut_ins}))
		f.close()


static func set_skill_cut_ins(on: bool) -> void:
	skill_cut_ins = on
	save_settings()


static func cut_ins_text() -> String:
	return "SKILL CUT-INS: %s" % ("ON" if skill_cut_ins else "OFF")
