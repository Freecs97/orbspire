extends Node
## Developer tool: opens fight 1 and the boss fight of every Act through the REAL
## game flow (main scene, star map PLAY) and saves a screenshot of each.
## Run:  Godot_v4.7.2-stable_win64_console.exe --path . res://tests/act_gallery.tscn
## Output: tests/screenshots/gallery_actNN_fight1.png / _boss.png

const MainScene := preload("res://scenes/main.tscn")


func _ready() -> void:
	GameSettings.path = "user://test_settings.json"   # never touch the player's settings
	GameSettings.skill_cut_ins = false   # cut-ins are tested in friends_test; keep these timings as they were
	Profile.friend_drops = false   # no random 1-in-400 friend joining this test's teams
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/screenshots"))
	var main := MainScene.instantiate()
	main.save_path = "user://gallery_save.json"
	add_child(main)
	await _frames(5)
	main.save["intro_seen"] = true
	main.save["slot4_notice"] = true
	if main.profile.needs_starter():
		main.profile.choose_starter(Profile.STARTERS[0])
	for n in range(1, 11):
		main.save["cleared_acts"].append(n)
	for n in range(1, 11):
		main.start_act(n, 0, false)
		await _settle(main)
		await _shot("gallery_act%02d_fight1" % n)
		main.battle._start_battle(7, main.battle.StartMode.NEW_ACT)
		await _frames(4)
		if main.battle.story_beat.is_open():
			await get_tree().create_timer(0.6).timeout
			await _shot("gallery_act%02d_boss_taunt" % n)   # Stage 6: every boss has a taunt
		await _settle(main)
		await _shot("gallery_act%02d_boss" % n)
		main.show_map()
		await _frames(3)
	await _shot("gallery_star_map_all_cleared")
	if FileAccess.file_exists("user://gallery_save.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://gallery_save.json"))
	get_tree().quit()


func _settle(main: Node) -> void:
	await _frames(3)
	if main.battle and main.battle.story_beat.is_open():
		main.battle.story_beat.close()
	await get_tree().create_timer(0.8).timeout


func _shot(n: String) -> void:
	await _frames(1)
	if not DisplayServer.window_can_draw():
		RenderingServer.force_draw(false)
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://tests/screenshots/%s.png" % n))


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
