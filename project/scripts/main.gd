extends Node
## The game's front door: title screen -> introduction -> Act 1 -> home screens.
##
## Plain English:
##   - First time: TAP TO START shows the Introduction once, then the STARTER
##     screen (pick ONE of 3 Berserkers: Fire, Water or Wood), then Act 1 starts
##     with its 2-line intro, then fight 1 (the tutorial). Everyone else is earned.
##   - After that: CONTINUE goes to the home screens. The bottom nav switches
##     between PLAY (star map), TEAM, ROSTER (+ Lab) and RECRUIT.
##   - An Act unlocks when the one before it is cleared. From Act 2 team slot 4
##     opens (a one-time notice).
##   - NEW GAME asks "Are you sure? This wipes your save" first.
## Everything you own lives in a Profile, saved to user://save.json after every change.

const BATTLE := preload("res://scenes/battle.tscn")
const STORY: StoryData = preload("res://data/story/story.tres")
const NEW_SAVE := {"intro_seen": false, "cleared_acts": [], "act_fight": {}, "codex": [], "slot4_notice": false, "act_intros": []}

## Tests point this somewhere else so they never touch your real save.
var save_path := "user://save.json"
var save: Dictionary = {}
var profile: Profile
var title: TitleScreen
var star_map: StarMap
var team_screen: TeamScreen
var roster_screen: RosterScreen
var recruit_screen: RecruitScreen
var intro: StoryBeat
var codex: CodexScreen
var starter_screen: StarterScreen
var battle: Node2D
var current_act: ActData


func _ready() -> void:
	GameSettings.load_settings()
	_load()
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	star_map = StarMap.new()
	team_screen = TeamScreen.new()
	roster_screen = RosterScreen.new()
	recruit_screen = RecruitScreen.new()
	for page in [star_map, team_screen, roster_screen, recruit_screen]:
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
	# An Act's 2-line intro plays once: the first time you start it at fight 1.
	star_map.play_pressed.connect(func(n: int) -> void:
		var fight := _act_fight(n)
		start_act(n, fight, fight == 0 and not n in save.get("act_intros", [])))
	if "--map-test-state" in OS.get_cmdline_user_args():
		_set_map_test_state()
	show_title()


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
			star_map.cleared = save["cleared_acts"]
			star_map.credits = save["credits"]
			star_map.training_cores = save["cores"]
			star_map.player_level = profile.highest_level()
			star_map.refresh()
			star_map.visible = true


func show_star_map() -> void:
	show_page("PLAY")


func _hide_pages() -> void:
	for page in [star_map, team_screen, roster_screen, recruit_screen]:
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
		show_star_map()


func _on_new_game() -> void:
	save = NEW_SAVE.duplicate(true)
	_make_profile()
	_write()
	title.set_has_save(false)
	_on_start()


## Start Act `n` at fight index `fight`. with_intro plays its 2-line intro first.
func start_act(n: int, fight: int, with_intro: bool) -> void:
	var a: ActData = StarMap.ACTS[n - 1]
	if not a.is_built():
		return
	current_act = a
	title.visible = false
	_hide_pages()
	battle = BATTLE.instantiate()
	battle.act = a
	battle.has_home = true
	battle.profile = profile
	battle.start_fight = clampi(fight, 0, a.fights.size() - 1)
	battle.play_act_intro = with_intro
	if with_intro:
		if not save.has("act_intros"):
			save["act_intros"] = []
		if not n in save["act_intros"]:
			save["act_intros"].append(n)
	if n >= 2 and not save.get("slot4_notice", save.get("spectre_joined", false)):
		battle.show_join_notice = true
		save["slot4_notice"] = true
	_write()
	add_child(battle)
	battle.fight_won.connect(_on_fight_won)
	battle.act_won.connect(_on_act_won)
	battle.progress_changed.connect(_write)
	battle.codex_requested.connect(open_codex)
	battle.home_requested.connect(show_star_map)


func open_codex() -> void:
	codex.open(current_act, current_act.singularity_name in save["codex"], STORY)


## Where CONTINUE / PLAY resumes inside an Act (fight index; 0 after a clear).
func _act_fight(n: int) -> int:
	return int(save["act_fight"].get(str(n), 0))


func _on_fight_won(index: int) -> void:
	save["act_fight"][str(current_act.act_number)] = (index + 1) % current_act.fights.size()
	_write()


func _on_act_won(a: ActData) -> void:
	if not a.act_number in save["cleared_acts"]:
		save["cleared_acts"].append(a.act_number)
	if not a.singularity_name in save["codex"]:
		save["codex"].append(a.singularity_name)
	_write()


## The star map test state: Act 1 completed, Act 2 unlocked.
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
	for page in [team_screen, roster_screen, recruit_screen]:
		if page:
			page.profile = profile


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
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save))
		f.close()
