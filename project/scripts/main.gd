extends Node
## The game's front door: title screen -> introduction -> Act 1 -> home screens.
##
## Plain English:
##   - First time: TAP TO START shows the Introduction once, then the STARTER
##     screen (pick ONE of 3 Berserkers: Fire, Water or Wood), then Act 1 starts
##     with its 2-line intro, then fight 1 (the tutorial). Everyone else is earned.
##   - After that: CONTINUE goes to the home screens. The bottom nav switches
##     between PLAY (the universe map), TEAM, ROSTER (+ Lab) and RECRUIT.
##   - The main story is Galaxy 1, Systems 1-3 (Acts 1-10, each Act one world).
##     After Reaper-0 the rest of the universe opens, ring by ring (Cosmos, Journey).
##     From Act 2 team slot 4 opens (a one-time notice).
##   - NEW GAME asks "Are you sure? This wipes your save" first.
## Everything you own lives in a Profile, saved to user://save.json after every change.

const BATTLE := preload("res://scenes/battle.tscn")
const STORY: StoryData = preload("res://data/story/story.tres")
const NEW_SAVE := {"intro_seen": false, "cleared_acts": [], "act_fight": {}, "codex": [], "slot4_notice": false, "act_intros": []}

## Tests point this somewhere else so they never touch your real save.
var save_path := "user://save.json"
var save: Dictionary = {}
var profile: Profile
var journey: Journey
var title: TitleScreen
var map: CosmosMap
var team_screen: TeamScreen
var roster_screen: RosterScreen
var recruit_screen: RecruitScreen
var intro: StoryBeat
var codex: CodexScreen
var starter_screen: StarterScreen
var battle: Node2D
var current_act: ActData
var _unsaved_time := 0.0


func _ready() -> void:
	GameSettings.load_settings()
	_load()
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	map = CosmosMap.new()
	team_screen = TeamScreen.new()
	roster_screen = RosterScreen.new()
	recruit_screen = RecruitScreen.new()
	for page in [map, team_screen, roster_screen, recruit_screen]:
		page.visible = false
		ui.add_child(page)
		page.tab_pressed.connect(show_page)
	for page in [team_screen, roster_screen, recruit_screen]:
		page.profile = profile
		page.changed.connect(_write)
	title = TitleScreen.new()
	ui.add_child(title)
	starter_screen = StarterScreen.new()
	starter_screen.visible = false
	ui.add_child(starter_screen)
	intro = StoryBeat.new()
	ui.add_child(intro)
	codex = CodexScreen.new()
	ui.add_child(codex)
	title.start_pressed.connect(_on_start)
	title.new_game_confirmed.connect(_on_new_game)
	map.play_world.connect(play_world)
	if "--map-test-state" in OS.get_cmdline_user_args():
		_set_map_test_state()
	show_title()


## Lifetime play time (Profile / Stats), saved about once a minute.
func _process(delta: float) -> void:
	if journey == null or (title and title.visible):
		return
	journey.add_play_time(delta)
	_unsaved_time += delta
	if _unsaved_time > 60.0:
		_write()


func show_title() -> void:
	_close_battle()
	_hide_pages()
	title.visible = true
	title.set_has_save(save["intro_seen"])


## Show a home page by its nav tab: PLAY, TEAM, ROSTER or RECRUIT.
func show_page(tab: String) -> void:
	_close_battle()
	title.visible = false
	_hide_pages()
	match tab:
		"TEAM":
			team_screen.visible = true
			team_screen.refresh()
		"ROSTER":
			roster_screen.visible = true
			roster_screen.showing_lab = false
			roster_screen.refresh()
		"RECRUIT":
			recruit_screen.visible = true
			recruit_screen.refresh()
		_:
			map.journey = journey
			map.profile = profile
			map.visible = true
			map.refresh()


## The PLAY screen (the universe map, at the level you were last on).
func show_map() -> void:
	show_page("PLAY")


func _hide_pages() -> void:
	for page in [map, team_screen, roster_screen, recruit_screen]:
		page.visible = false


func _close_battle() -> void:
	if battle:
		battle.queue_free()
		battle = null
	codex.visible = false


func _on_start() -> void:
	if intro.is_open() or battle or starter_screen.visible:
		return
	var first_time: bool = not save["intro_seen"]
	if first_time:
		title.visible = false
		await intro.play([STORY.introduction], 0.0, "", true)
		save["intro_seen"] = true
		_write()
	if profile.needs_starter():
		title.visible = false
		var id: String = await starter_screen.choose()
		profile.choose_starter(id)
		_write()
		start_act(1, 0, true)
	elif first_time:
		start_act(1, 0, true)
	else:
		show_map()


func _on_new_game() -> void:
	save = NEW_SAVE.duplicate(true)
	_make_profile()
	map.cur_g = 1
	map.level = "universe"
	_write()
	title.set_has_save(false)
	_on_start()


## PLAY from the map (after the danger warning): a story Act world or a generated one.
func play_world(key: String, stage: int) -> void:
	var w := Cosmos.world_by_key(key)
	if int(w["act"]) > 0:
		var n := int(w["act"])
		start_act(n, stage, stage == 0 and not n in save.get("act_intros", []))
	else:
		start_world(key, stage)


## Start Act `n` at fight index `fight`. with_intro plays its 2-line intro first.
func start_act(n: int, fight: int, with_intro: bool) -> void:
	var a: ActData = Cosmos.ACTS[n - 1]
	if not a.is_built():
		return
	journey.c["last_world"] = Cosmos.act_world_key(n)
	if with_intro:
		if not save.has("act_intros"):
			save["act_intros"] = []
		if not n in save["act_intros"]:
			save["act_intros"].append(n)
	var show_notice := false
	if n >= 2 and not save.get("slot4_notice", save.get("spectre_joined", false)):
		show_notice = true
		save["slot4_notice"] = true
	_start_battle_for(a, fight, with_intro, show_notice)


## Start a generated world (Cosmos) at stage index `stage`.
func start_world(key: String, stage: int) -> void:
	var w := Cosmos.world_by_key(key)
	var a := Cosmos.build_world(int(w["g"]), int(w["s"]), int(w["w"]))
	journey.c["last_world"] = key
	# Entering a farther galaxy raises the level ceiling (Training Cores too).
	profile.data["level_ceiling"] = maxi(int(profile.data["level_ceiling"]), Cosmos.galaxy_cap(int(w["g"])))
	_start_battle_for(a, stage, false, false)


func _start_battle_for(a: ActData, fight: int, with_intro: bool, show_notice: bool) -> void:
	current_act = a
	title.visible = false
	_hide_pages()
	battle = BATTLE.instantiate()
	battle.act = a
	battle.has_home = true
	battle.profile = profile
	battle.start_fight = clampi(fight, 0, a.fights.size() - 1)
	battle.play_act_intro = with_intro
	battle.show_join_notice = show_notice
	_write()
	add_child(battle)
	battle.fight_won.connect(_on_fight_won)
	battle.act_won.connect(_on_act_won)
	battle.progress_changed.connect(_write)
	battle.codex_requested.connect(open_codex)
	battle.home_requested.connect(show_map)
	battle.turn_combos.connect(func(n: int) -> void: journey.note_combo(n))


func open_codex() -> void:
	codex.open(current_act, current_act.singularity_name in save["codex"], STORY)


## Where CONTINUE / PLAY resumes inside an Act (fight index; 0 after a clear).
func _act_fight(n: int) -> int:
	return int(save["act_fight"].get(str(n), 0))


func _on_fight_won(index: int) -> void:
	if current_act.is_world():
		journey.world_fight_won(current_act, index)
	else:
		save["act_fight"][str(current_act.act_number)] = (index + 1) % current_act.fights.size()
		journey.story_fight_won(current_act, index)
	_write()


func _on_act_won(a: ActData) -> void:
	if a.is_world():
		journey.world_cleansed_now(a)
		_write()
		return
	if not a.act_number in save["cleared_acts"]:
		save["cleared_acts"].append(a.act_number)
	if not a.singularity_name in save["codex"]:
		save["codex"].append(a.singularity_name)
	_write()


## The map test state: Act 1 completed, Act 2 unlocked.
func _set_map_test_state() -> void:
	save["intro_seen"] = true
	if profile.needs_starter():
		profile.choose_starter(Profile.STARTERS[0])
	if not 1 in save["cleared_acts"]:
		save["cleared_acts"].append(1)
	if not "Emberfang-9" in save["codex"]:
		save["codex"].append("Emberfang-9")


func _make_profile() -> void:
	profile = Profile.new(save)
	journey = Journey.new(save)
	for page in [team_screen, roster_screen, recruit_screen]:
		if page:
			page.profile = profile
	if map:
		map.journey = journey
		map.profile = profile


func _load() -> void:
	save = NEW_SAVE.duplicate(true)
	if FileAccess.file_exists(save_path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if data is Dictionary:
			for k in data:
				save[k] = data[k]
			# Older saves (before the star map) used act1_* fields.
			if data.get("act1_cleared", false) and not 1 in save["cleared_acts"]:
				save["cleared_acts"].append(1)
			if data.has("act1_fight"):
				save["act_fight"]["1"] = int(data["act1_fight"])
			# Saves from before Stage 6: Acts already started or cleared skip their intro.
			if not data.has("act_intros"):
				var seen := []
				if save["intro_seen"]:
					seen.append(1)
				for a in save["cleared_acts"]:
					seen.append(int(a))
				for k in save["act_fight"]:
					seen.append(int(k))
				save["act_intros"] = seen
	var ints: Array = []
	for n in save["cleared_acts"]:
		ints.append(int(n))
	save["cleared_acts"] = ints
	var seen_ints: Array = []
	for n in save.get("act_intros", []):
		seen_ints.append(int(n))
	save["act_intros"] = seen_ints
	_make_profile()


func _write() -> void:
	_unsaved_time = 0.0
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save))
		f.close()
