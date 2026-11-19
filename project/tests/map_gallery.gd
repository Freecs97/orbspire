extends Node
## Developer tool: screenshots of every map level for calibration (numbered markers
## + each node's colour and hue shift), through the REAL main scene.
## Run:  Godot_v4.7.2-stable_win64_console.exe --path . res://tests/map_gallery.tscn
## Output: tests/screenshots/map_*.png

const MainScene := preload("res://scenes/main.tscn")
const SAVE := "user://map_gallery_save.json"


func _ready() -> void:
	GameSettings.path = "user://test_settings.json"
	GameSettings.skill_cut_ins = false
	Profile.friend_drops = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/screenshots"))
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var main := MainScene.instantiate()
	main.save_path = SAVE
	add_child(main)
	await _frames(4)
	main.save["intro_seen"] = true
	main.profile.choose_starter(Profile.STARTERS[0])
	# Story finished (all 10 Acts) and a few worlds cleansed, so states show.
	for n in range(1, 11):
		main.save["cleared_acts"].append(n)
	main.journey.c["cleansed"].append("1-4-1")
	main.journey.c["stage_next"]["1-4-2"] = 2
	main.show_map()
	var m: CosmosMap = main.map
	await _frames(4)
	await _shot("map_1_universe")
	m.show_markers = true
	await _shot("map_1_universe_calibration")
	m.open_galaxy(1)
	await _frames(3)
	await _shot("map_2_galaxy1_calibration")
	m.show_markers = false
	await _shot("map_2_galaxy1")
	m.open_galaxy(2)
	await _frames(3)
	m.show_markers = true
	await _shot("map_2_galaxy2_calibration")
	m.show_markers = false
	m.open_system(1, 1)
	await _frames(3)
	await _shot("map_3_system_1_1_story")
	m.open_system(1, 6)
	await _frames(3)
	await _shot("map_3_system_1_6")
	m.show_markers = true
	await _shot("map_3_system_1_6_calibration")
	m.show_markers = false
	m.open_preview(1)
	await _shot("map_3_system_1_6_preview")
	m.open_world("1-4-2")
	await _frames(3)
	await _shot("map_4_world_1_4_2")
	m.open_world(Cosmos.act_world_key(2))
	await _frames(3)
	await _shot("map_4_world_act2")
	m.open_stats()
	await _shot("map_5_stats")
	m.stats_panel.visible = false
	main.profile.data["units"][0]["level"] = 30
	m.open_universe()
	m.request_play("2-1-1", 0)
	await _shot("map_6_danger_warning")
	m.warn_panel.visible = false
	# Colour versions + a dual-affinity hunter on the Roster, then a world fight.
	var prof: Profile = main.profile
	var kaela: int = prof.data["units"][0]["uid"]
	prof.unit(kaela)["stage"] = 3
	prof.unit(kaela)["level"] = 30
	var team := [kaela]
	for id in ["berserker_01_angel_fire@water", "titan_04_void_dark@light", "biotech_01_medic_water@fire", "enemy_spore_sprout@dark", "spectre_03_sniper_wood@dark", "enemy_nix"]:
		var uid := prof.add_unit(id, 3 if not id.begins_with("enemy") else 1, 28)
		prof.unit(uid)["stage"] = 3 if id == "enemy_nix" else 2
		if team.size() < 4:
			team.append(uid)
	prof.data["team"] = team
	main.show_page("ROSTER")
	await _frames(4)
	await _shot("map_7_roster_colour_versions")
	main.roster_screen.open_detail(kaela)
	await _frames(3)
	await _shot("map_8_dual_affinity_detail")
	main.roster_screen.detail.close()
	main.play_world("1-4-1", 3)
	await _frames(10)
	if main.battle and main.battle.story_beat.is_open():
		main.battle.story_beat.close()
	await get_tree().create_timer(1.0).timeout
	await _shot("map_9_world_fight_warden")
	main.show_map()
	main.queue_free()
	await _frames(2)
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	get_tree().quit()


func _shot(n: String) -> void:
	await _frames(3)
	if not DisplayServer.window_can_draw():
		RenderingServer.force_draw(false)
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://tests/screenshots/%s.png" % n))


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
