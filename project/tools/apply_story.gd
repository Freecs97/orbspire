extends SceneTree
## Developer tool: copies the approved story (scripts/data/story_text.gd) into the
## 10 Act files (data/acts/act_NN.tres): intro, boss taunt, outro, 4-line codex,
## beat timings, and the Act 9 map-preview fix. Fights and numbers are untouched.
## Run:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/apply_story.gd


func _init() -> void:
	for n in range(1, 11):
		var path := "res://data/acts/act_%02d.tres" % n
		var act: ActData = load(path)
		var fights_before := act.fights.size()
		StoryText.apply_to(act, n)
		act.take_over_path(path)
		var err := ResourceSaver.save(act, path)
		print("Act %2d: %s  (intro %.0f s, taunt %.0f s, outro %.0f s, fights %d -> %d)" % [
			n, "saved" if err == OK else "ERROR %d" % err, act.intro_seconds, act.taunt_seconds, act.outro_seconds, fights_before, act.fights.size()])
	quit()
