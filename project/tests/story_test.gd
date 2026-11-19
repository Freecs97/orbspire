extends Node
## Automated test for the title screen, Introduction, Act 1 story beats and codex.
## Developer tool, not part of the game. Plays the REAL main scene with simulated taps.
## Uses its own save file (user://test_save.json), never your real save.
##
## Run:  Godot_v4.7.2-stable_win64_console.exe --path . res://tests/story_test.tscn
## Results: tests/report_story.txt, screenshots in tests/screenshots/s*.png

const MainScene := preload("res://scenes/main.tscn")
const STORY: StoryData = preload("res://data/story/story.tres")
const ACT1: ActData = preload("res://data/acts/act_01.tres")
const FIRE4 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "FFFFDH"]

## The Introduction, word for word from the story prompt.
const INTRO_EXACT := "Humanity left Earth to survive.\nTo survive new worlds, we spliced life with technology.\nWe called it technomancy.\n\nIt worked too well.\n\nThe splices kept evolving. They became singularities —\nliving machines that run rampant, and some of them became gods.\n\nThe Progenitors invented technomancy.\nThen they banned it, to hide where it came from.\nThey did not kill the singularities. They could not.\nThey quarantined the colonies, and let them die quietly.\n\nOut here, on the edge, the singularities are still growing.\nSomeone has to hunt them before they become gods."
const ACT_INTRO_EXACT := "Orbspire was built to burn. Its furnace was spliced with a wolf to guard it.\nThe wolf learned to guard something else instead."
const TAUNT_EXACT := "You did not make me. But you made what made me."
const OUTRO_EXACT := "The furnace keeps burning. The colony keeps rationing heat. Killing the wolf did not fix Orbspire. It only proved the wolf could be killed."

var main: Node
var lines := PackedStringArray()
var fails := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/screenshots"))
	if FileAccess.file_exists("user://test_save.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save.json"))
	main = MainScene.instantiate()
	main.save_path = "user://test_save.json"
	add_child(main)
	await _frames(3)
	_log("Godot %s · story / title test" % Engine.get_version_info().string)
	if not "title" in main or main.title == null:
		_check(false, "main scene failed to load (see the Godot log for the script error)")
		_finish()
		return
	await _test_title()
	await _test_intro_and_act_intro()
	await _test_art_in_battle()
	await _test_boss_taunt_and_outro()
	await _test_codex()
	await _test_continue_and_new_game()
	_test_no_ban()
	_finish()


func _test_title() -> void:
	_log("\n== T1: title screen ==")
	var t: TitleScreen = main.title
	_check(t.visible and t.title_label.text == "ORBSPIRE" and t.subtitle.text == "TAP TO START", "title shows ORBSPIRE + TAP TO START")
	_check(t.main_button.text == "TAP TO START" and t.new_game_button.text == "NEW GAME" and t.settings_button.text == "SETTINGS", "first time: TAP TO START button, NEW GAME and SETTINGS underneath")
	var y0: Array = []
	for b in t.party_bodies:
		y0.append(b.position.y)
	await _wait(2.5)
	var moved := 0
	for i in t.party_bodies.size():
		if absf(t.party_bodies[i].position.y - y0[i]) > 0.5:
			moved += 1
	_check(t.party_bodies.size() == 3 and moved == 3, "3 hunters (your art) stand on the floor and idle-bob (%d of 3 moved)" % moved)
	_check(t.orb_count() > 0, "your orb art drifts up the screen (%d orbs floating)" % t.orb_count())
	_check(t.glitch_count >= 1, "title glitch flicker played %d time(s) in 2.5 s" % t.glitch_count)
	await _shot("s1_title")
	await _click(t.settings_button)
	_check(t.settings_panel.visible, "SETTINGS opens a panel")
	await _click(t.settings_close)
	_check(not t.settings_panel.visible, "settings panel closes")


func _test_intro_and_act_intro() -> void:
	_log("\n== T2: Introduction (once) + Act 1 intro beat ==")
	await _click(main.title.main_button)
	await _frames(3)
	var intro: StoryBeat = main.intro
	_check(intro.is_open() and intro.shown_text() == INTRO_EXACT, "Introduction shows the exact text, one screen")
	_check(intro._hint.text == "Tap to continue", "it waits for a tap (\"%s\")" % intro._hint.text)
	await _shot("s2_introduction")
	await _wait(1.0)
	_check(intro.is_open(), "it does not close by itself")
	await _tap_center()
	await _frames(5)
	await _test_starter_screen()
	var battle = main.battle
	_check(not intro.is_open() and battle != null and main.save["intro_seen"], "YES -> Act 1 starts, save remembers the Introduction was seen")
	_check(battle.team.members.size() == 1 and battle.team.members[0].display_name == "KAELA RYNN" and main.profile.data["units"].size() == 1,
		"you start with ONE character only (your starter), nobody else is given")
	var beat: StoryBeat = battle.story_beat
	_check(beat.is_open() and beat.shown_text() == ACT_INTRO_EXACT, "Act 1 intro beat: 2 lines, exact text")
	_check(beat._speaker.text == "ORBSPIRE  ·  FURNACE COLONY", "beat header: \"%s\"" % beat._speaker.text)
	_check(battle.board.state == Board.State.LOCKED, "board is locked while the beat shows")
	await _shot("s3_act_intro")
	var t := 0.0
	while beat.is_open() and t < 15.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	_check(not beat.is_open() and t > 9.0 and t < 11.0, "the beat closes by itself after ~10 s (%.1f s)" % t)
	await _frames(2)
	_check(battle.board.state == Board.State.READY and battle.fight_index == 0, "then fight 1 starts (board ready)")
	_check(battle.enemies.size() == 1 and battle.enemies[0].data.element == Element.Type.LIGHT,
		"tutorial (fight 1) is ONE Light enemy (%s): neutral to Fire, Water and Wood, so every starter has the same fight" % battle.enemies[0].data.display_name)
	await _shot("s3b_tutorial_solo_starter")
	await _test_scrap_flow(battle)


## New Game: the starter screen comes after the Introduction, before the tutorial.
func _test_starter_screen() -> void:
	_log("\n== T2a: starter choice (New Game) ==")
	var s: StarterScreen = main.starter_screen
	_check(s.visible and main.battle == null and main.profile.needs_starter(), "after the Introduction: the STARTER screen, before any fight")
	var names := PackedStringArray()
	var same := true
	var t0 := Catalog.template(Profile.STARTERS[0])
	for id in Profile.STARTERS:
		var t := Catalog.template(id)
		names.append("%s (%s)" % [t.display_name, t.title])
		same = same and t.role == FighterData.Role.BERSERKER and t.max_hp == t0.max_hp and t.atk == t0.atk and t.rcv == t0.rcv \
			and t.active_skill == &"overrun" and (id == Profile.STARTERS[0] or (t.leader_skill != t0.leader_skill and t.passives != t0.passives))
	var els := [Catalog.template(Profile.STARTERS[0]).element, Catalog.template(Profile.STARTERS[1]).element, Catalog.template(Profile.STARTERS[2]).element]
	_check(s.cards.size() == 3 and els == [Element.Type.FIRE, Element.Type.WATER, Element.Type.WOOD], "3 starters, one per element: %s" % ", ".join(names))
	_check(same, "all 3 are Berserkers with IDENTICAL HP / ATK / RCV (%d / %d / %d) and Overrun; each has their OWN leader skill and passives (Stage 3)" % [t0.max_hp, t0.atk, t0.rcv])
	_check(s.start_button.disabled and s.start_button.text == "TAP A STARTER", "nothing is picked for you: START is off until you tap one")
	await _shot("s2b_starter_screen")
	await _click(s.cards[1])
	_check(s.selected == 1 and s.start_button.text == "START AS IRIS VALE", "tap Iris -> \"%s\"" % s.start_button.text)
	await _click(s.cards[0])
	await _click(s.start_button)
	_check(s.confirm.visible and s.confirm_text.text.contains("KAELA RYNN") and s.confirm_text.text.contains("NEW GAME"), "START -> \"Start as KAELA RYNN? ... can't be changed (only with NEW GAME)\"")
	await _shot("s2c_starter_confirm")
	await _click(s.confirm_no)
	_check(not s.confirm.visible and s.visible and main.battle == null, "BACK -> still choosing")
	await _click(s.start_button)
	await _click(s.confirm_yes)
	await _frames(5)
	_check(not s.visible and main.save.get("starter", "") == "berserker_01_angel_fire", "YES -> the choice is saved (starter = %s)" % main.save.get("starter", ""))


## Act 1 Scrap flow: winning fights 1 and 2 the first time each gives a Scrap hunter
## who fills the next team slot.
func _test_scrap_flow(battle) -> void:
	_log("\n== T2b: Act 1 Scrap characters (how the team fills up) ==")
	var team_sizes := [battle.team.members.size()]
	var got := PackedStringArray()
	for k in 2:
		battle.enemies[0].hp = 1
		_set_board(battle, FIRE4)
		await _tap_cell(battle, Vector2i(5, 0))
		var t := 0.0
		while not battle.result_panel.visible and t < 15.0:
			await get_tree().process_frame
			t += get_process_delta_time()
		var nu: Dictionary = battle.last_rewards.get("new_unit", {})
		var info: String = battle.result_panel._info.text
		_check(nu.has("id") and info.contains("NEW HUNTER") and info.contains("(Scrap) joined your team!"),
			"win fight %d (first time): \"%s\"" % [k + 1, info.get_slice("\n", info.get_slice_count("\n") - 1)])
		if nu.has("id"):
			got.append("%s (%s)" % [Catalog.display_name(nu["id"]), Catalog.template(nu["id"]).title])
			_check(main.profile.unit(nu["uid"])["rarity"] == 0, "  ... it is Scrap rarity")
		await _shot("s3c_scrap_drop_fight%d" % (k + 1))
		await _click(battle.result_panel._next_button)
		await _frames(4)
		team_sizes.append(battle.team.members.size())
	_check(team_sizes == [1, 2, 3], "team size: %s (fight 1 solo -> fight 2 with 2 -> fight 3 with 3)" % [team_sizes])
	_check(got.size() == 2 and got[0].contains("Water"), "fight 1's Scrap hunter is Water (strong vs the Fire boss): %s" % ", ".join(got))
	await _shot("s3d_fight3_team_of_3")


func _test_art_in_battle() -> void:
	_log("\n== T3: your art in battle ==")
	var battle = main.battle
	_check(battle.team_views.size() == 3 and battle.team_views.all(func(v: FighterView) -> bool: return v.figure is ArtFigure), "the 3 hunters (starter + 2 Scrap) use your art")
	_check(battle.enemy_views[0].figure is ArtFigure, "the %s uses your art" % battle.enemies[0].data.display_name)
	_check(battle.backdrop.arena != null, "the Act 1 furnace arena is the background")
	_check(Orb.ART.size() == 6, "all 6 orb types (Heart included) use your orb art")
	await _shot("s4_battle_art")
	# Every Act 1 enemy uses its PNG, and its name is the PNG's name.
	var names := PackedStringArray()
	var all_art := true
	for i in ACT1.fights.size():
		battle._start_battle(i, battle.StartMode.NEW_ACT)
		await _frames(2)
		if battle.story_beat.is_open():
			battle.story_beat.close()
		for k in battle.enemies.size():
			var d: FighterData = battle.enemies[k].data
			var file := d.art.resource_path.get_file().get_basename() if d.art else "(none)"
			var from_png := file.trim_prefix("enemy_fire_").trim_prefix("enemy_water_").trim_prefix("enemy_wood_").trim_prefix("enemy_light_").trim_prefix("enemy_dark_").replace("_", " ").to_upper()
			if d.is_boss and d.art and file.begins_with("boss_"):
				from_png = d.display_name   # bosses keep their story names (Emberfang-9)
			var shown_kind := (d.title if d.title != "" else d.display_name).to_upper()
			all_art = all_art and battle.enemy_views[k].figure is ArtFigure and shown_kind == from_png
			if k == 0:
				names.append(d.display_name)
	_check(all_art, "all 8 Act 1 fights: every enemy uses its PNG, named after it (Light/Dark ones by their proper name + PNG title): %s" % ", ".join(names))
	battle._start_battle(4, battle.StartMode.NEW_ACT)
	await _frames(3)
	await _shot("s5_ember_drone")


func _test_boss_taunt_and_outro() -> void:
	_log("\n== T4: boss taunt + outro ==")
	var battle = main.battle
	battle._start_battle(7, battle.StartMode.NEW_ACT)
	await _frames(4)
	var beat: StoryBeat = battle.story_beat
	_check(beat.is_open() and beat.shown_text() == TAUNT_EXACT and beat._speaker.text == "EMBERFANG-9", "boss taunt: \"%s\" from EMBERFANG-9" % beat.shown_text())
	_check(battle.board.state == Board.State.LOCKED and battle.enemy_views[0].figure is ArtFigure, "board locked during the taunt; Emberfang-9 uses your boss art")
	await _shot("s6_boss_taunt")
	await _click(beat._skip)
	await _frames(2)
	_check(not beat.is_open() and battle.board.state == Board.State.READY, "SKIP closes it at once and the fight starts")
	# Win the boss fight: bring it to 1 HP and match 4 fire.
	battle.enemies[0].hp = 1
	_set_board(battle, FIRE4)
	await _tap_cell(battle, Vector2i(5, 0))
	var t := 0.0
	while not beat.is_open() and t < 20.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	_check(beat.is_open() and beat.shown_text() == OUTRO_EXACT, "boss down -> outro line, exact text")
	_check(not battle.result_panel.visible, "the result screen waits until the outro is done")
	await _shot("s7_outro")
	t = 0.0
	while beat.is_open() and t < 15.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	await _frames(3)
	_check(not beat.is_open() and t > 9.0 and t < 11.0, "outro closes by itself after ~10 s (%.1f s)" % t)
	var rp: ResultPanel = battle.result_panel
	_check(rp.visible and rp._title.text == "ACT 1 CLEAR!" and rp.codex_button.visible and rp.codex_button.text == "CODEX UNLOCKED: EMBERFANG-9", "then ACT 1 CLEAR! with \"%s\"" % rp.codex_button.text)
	_check("Emberfang-9" in main.save["codex"] and 1 in main.save["cleared_acts"], "save: codex entry unlocked, Act 1 cleared")
	await _shot("s8_act_clear")


func _test_codex() -> void:
	_log("\n== T5: codex ==")
	var rp: ResultPanel = main.battle.result_panel
	await _click(rp.codex_button)
	var c: CodexScreen = main.codex
	var text := c.page_text()
	_check(c.visible and text.contains("EMBERFANG-9") and text.contains("SPLICED FROM") and text.contains("WHAT IT WANTED") and text.contains("WHAT IT COST"), "Emberfang-9 entry: spliced from / wanted / cost")
	_check(text.contains(ACT1.codex_spliced_from) and text.contains(ACT1.codex_cost), "entry text comes from data/acts/act_01.tres")
	await _shot("s9_codex_entry")
	await _click(c.tab_timeline)
	await _frames(2)
	text = c.page_text()
	var all_years := text.contains("Year 0-80") and text.contains("Year 82") and text.contains("Year 90-120") and text.contains("Year 121") and text.contains("Year 140+")
	_check(all_years and text.contains("The Progenitors splice a wolf with plasma to guard a furnace."), "timeline page: the 5 entries (Year 0-80 ... Year 140+)")
	await _shot("s10_codex_timeline")
	await _click(c.close_button)
	_check(not c.visible, "CLOSE returns to the Act clear screen")


func _test_continue_and_new_game() -> void:
	_log("\n== T6: star map (test state: Act 1 completed, Act 2 unlocked) ==")
	var rp: ResultPanel = main.battle.result_panel
	_check(rp._next_button.text == "Back to Star Map", "after the Act: \"%s\"" % rp._next_button.text)
	await _click(rp._next_button)
	await _frames(4)
	var m: StarMap = main.star_map
	_check(m.visible and main.battle == null, "the star map opens")
	var states := []
	for n in range(1, 11):
		states.append(m.state(n))
	_check(states[0] == "completed" and states[1] == "current" and states.slice(2).all(func(s: String) -> bool: return s == "locked"),
		"Act 1 completed, Act 2 unlocked, Acts 3-10 locked: %s" % [states])
	var labels := PackedStringArray()
	for i in 10:
		labels.append("%s / %s" % [m._labels[i * 2].text, m._labels[i * 2 + 1].text])
	_check(labels[0] == "Orbspire / Emberfang-9" and labels[9] == "The Core / Reaper-0", "10 labels (colony / boss) in Godot text: %s" % ", ".join(labels))
	_check(m._top_labels.size() == 3 and m.settings_button != null and m.nav_buttons.size() == 5 and m.nav_buttons[0].text == "PLAY",
		"top bar (Credits, Cores, level, Settings) and bottom nav (Play, Team, Roster, Recruit, Quests)")
	var inside := true
	for i in 10:
		var p := m.node_pos(i)
		inside = inside and p.y > StarMap.TOP_BAR_H and p.y < m.size.y - StarMap.NAV_H and p.x > 0 and p.x < m.size.x
	_check(inside, "all 10 nodes sit between the top bar and the bottom nav")
	await _shot("m1_star_map")
	m.show_markers = true
	await _frames(2)
	await _shot("m2_star_map_calibration_markers")
	m.show_markers = false
	await _click(m.node_buttons[2])
	_check(not m.panel.visible and m.toast.text == "Finish Act 2 to unlock", "tap locked Act 3: \"%s\"" % m.toast.text)
	await _click(m.node_buttons[0])
	_check(m.panel.visible and m.panel_intel.text == "\n".join(PackedStringArray(ACT1.intel_lines)) and m.play_button.text == "REPLAY", "tap Act 1: intel panel (3 lines) + REPLAY, no fight starts by itself")
	_check(m.rift_button.disabled and m.rift_button.text.begins_with("SIDE RIFT"), "empty \"Side Rift - coming soon\" slot, greyed out")
	await _shot("m3_intel_panel_act1")
	await _click(m.panel_close)
	await _click(m.node_buttons[1])
	_check(m.panel.visible and not m.play_button.disabled and m.play_button.text == "PLAY" and m.panel_intel.text.contains("Tidecoil-7"), "tap Act 2: its intel and PLAY")
	await _shot("m4_intel_panel_act2")
	await _click(m.play_button)
	await _frames(4)
	var b2 = main.battle
	var owned: int = main.profile.data["units"].size()
	_check(b2 != null and b2.act.act_number == 2 and b2.team.members.size() == mini(owned, 4) and b2.backdrop.arena.resource_path.ends_with("bg_act02_drowned_arena.png"),
		"PLAY Act 2: your own team (%d hunters, nobody given for free) in the Drowned Metro arena" % b2.team.members.size())
	_check(b2.story_beat.is_open() and b2.story_beat._speaker.text == "NEW SLOT" and not main.profile.data["units"].any(func(u: Dictionary) -> bool: return u["id"] == "spectre_01_rogue_dark" and u["rarity"] == 2),
		"a one-time \"NEW SLOT\" notice: team slot 4 is open (no free Dark Spectre any more)")
	await _shot("m5_act2_slot4_notice")
	b2.story_beat.close()
	await _frames(2)
	_check(b2.enemies[0].data.display_name == "DROWNED DRIFTER" and b2.enemy_views[0].figure is ArtFigure, "Act 2 fight 1: Drowned Drifters, your art")
	b2._start_battle(7, b2.StartMode.NEW_ACT)
	await _frames(3)
	_check(b2.enemies[0].data.display_name == "TIDECOIL-7" and b2.enemies[0].data.art.resource_path.ends_with("boss_02_tidecoil7_flood_serpent.png"), "Act 2 boss: Tidecoil-7 with your boss art")
	await _shot("m6_act2_boss")
	main.show_star_map()
	await _frames(3)
	await _click(m.nav_buttons[3])
	_check(main.recruit_screen.visible and not m.visible, "the RECRUIT tab opens the Recruit screen")
	await _click(main.recruit_screen.nav_buttons[0])
	_check(m.visible and not main.recruit_screen.visible, "and PLAY brings the star map back")
	await _click(m.node_buttons[0])
	await _click(m.play_button)
	await _frames(4)
	_check(main.battle != null and main.battle.fight_index == 0 and not main.battle.story_beat.is_open(), "Act 1 REPLAY starts at fight 1 (no intro beat)")

	_log("\n== T6a: MENU button in combat (leave the fight) ==")
	var lb = main.battle
	await _frames(2)
	var mb: Button = lb.menu_button
	var vr := get_viewport().get_visible_rect()
	var r := mb.get_global_rect()
	_check(mb.visible and not mb.disabled and mb.text == "MENU" and r.position.y < 100 and r.end.x <= vr.size.x and r.end.x > vr.size.x - 40,
		"MENU button sits in the top-right corner and works on your turn")
	await _click(mb)
	_check(lb.leave_dialog.visible and lb.board.state == Board.State.LOCKED and lb.leave_yes.text == "YES, LEAVE",
		"tap MENU -> \"Leave this fight?\" with YES / NO, board locked underneath")
	await _shot("s11_leave_fight_dialog")
	await _click(lb.leave_no)
	_check(not lb.leave_dialog.visible and lb.board.state == Board.State.READY and main.battle == lb, "NO, STAY -> back to the same fight, board ready again")
	lb._player_turn = false   # pretend the enemies are attacking
	await _frames(2)
	_check(mb.disabled and not lb.open_leave_dialog(), "MENU is greyed out (does nothing) while a turn is playing out")
	lb._player_turn = true
	await _frames(2)
	_check(not mb.disabled, "and lights up again on your turn")
	await _click(mb)
	await _click(lb.leave_yes)
	await _frames(3)
	_check(main.battle == null and m.visible, "YES, LEAVE -> back to the star map")

	_log("\n== T6b: CONTINUE, NEW GAME ==")
	main.show_title()
	await _frames(3)
	var title: TitleScreen = main.title
	_check(title.visible and title.main_button.text == "CONTINUE", "title now says CONTINUE")
	await _click(title.main_button)
	await _frames(4)
	_check(main.star_map.visible and main.battle == null and not main.intro.is_open(), "CONTINUE goes to the star map (no Introduction)")
	main.show_title()
	await _frames(3)
	await _click(title.new_game_button)
	_check(title.confirm_panel.visible and title.confirm_yes.text == "YES, WIPE", "NEW GAME asks \"Are you sure? This wipes your save\"")
	await _click(title.confirm_no)
	_check(not title.confirm_panel.visible and main.save["intro_seen"], "NO keeps the save")
	await _click(title.new_game_button)
	await _click(title.confirm_yes)
	await _frames(3)
	_check(not main.save["intro_seen"] and main.save["codex"].is_empty() and main.intro.is_open() and main.profile.needs_starter(),
		"YES wipes the save (no characters, no starter) and the Introduction plays again")
	main.intro.close()
	await _frames(4)
	_check(main.starter_screen.visible and main.battle == null, "...then the starter choice again (a New Game is the only way to change it)")
	main.starter_screen.visible = false


func _test_no_ban() -> void:
	_log("\n== T7: \"The Ban\" appears nowhere ==")
	var hits := PackedStringArray()
	var re := RegEx.create_from_string("\\bBan\\b")
	for root in ["res://data", "res://scripts"]:
		for path in _files(root):
			var text := FileAccess.get_file_as_string(path)
			if re.search(text):
				hits.append(path)
	_check(hits.is_empty(), "no \"Ban\" in any data or script file %s" % ("" if hits.is_empty() else str(hits)))


# ---------------------------------------------------------------- helpers

func _files(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir_path)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd") or f.ends_with(".tres"):
			out.append(dir_path + "/" + f)
	for sub in d.get_directories():
		out.append_array(_files(dir_path + "/" + sub))
	return out


func _set_board(battle: Node, rows: Array) -> void:
	var map := {"F": Element.Type.FIRE, "W": Element.Type.WATER, "G": Element.Type.WOOD,
		"L": Element.Type.LIGHT, "D": Element.Type.DARK, "H": Element.Type.HEART}
	for y in Board.ROWS:
		for x in Board.COLS:
			(battle.board.grid[x][y] as Orb).setup(map[rows[y][x]])


func _tap_cell(battle: Node, c: Vector2i) -> void:
	var p: Vector2 = battle.board.get_global_transform_with_canvas() * battle.board.cell_center(c)
	_press(p)
	await _frames(1)
	_release(p)
	await _frames(1)


func _tap_center() -> void:
	var p := get_viewport().get_visible_rect().size * 0.5
	_press(p)
	await _frames(1)
	_release(p)
	await _frames(2)


func _click(button: Control) -> void:
	var p := button.get_global_rect().get_center()
	_press(p)
	await _frames(1)
	_release(p)
	await _frames(3)


func _press(p: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	e.position = p
	e.global_position = p
	get_viewport().push_input(e, true)


func _release(p: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = false
	e.position = p
	e.global_position = p
	get_viewport().push_input(e, true)


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await _frames(2)
	var img := get_viewport().get_texture().get_image()
	if img and not img.is_empty():
		img.save_png(ProjectSettings.globalize_path("res://tests/screenshots/%s.png" % shot_name))


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	_log(("PASS  " if ok else "FAIL  ") + what)


func _log(text: String) -> void:
	print(text)
	lines.append(text)


func _finish() -> void:
	_log("\n%s — %d failure(s)" % ["ALL PASSED" if fails == 0 else "SOME FAILED", fails])
	var f := FileAccess.open(ProjectSettings.globalize_path("res://tests/report_story.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	if FileAccess.file_exists("user://test_save.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save.json"))
	get_tree().quit(fails)
