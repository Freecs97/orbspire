extends Node
## Automated play-test. Developer tool, not part of the game.
##
## It loads the real battle scene and plays it by sending real mouse events
## (press / drag / release), exactly like your finger would. It reads the
## numbers the game shows and writes PASS / FAIL to tests/report.txt, plus
## screenshots in tests/screenshots/ (screenshots only in a normal window).
##
## Run from a terminal in the project folder:
##   Godot_v4.7.2-stable_win64_console.exe --path . res://tests/loop_test.tscn
## Only some sections (faster while developing), e.g. groundwork + actives:
##   ... res://tests/loop_test.tscn -- --only=G,A
## Layout-only check on a tall phone shape (1080 x 2400):
##   ... --resolution 432x960 res://tests/loop_test.tscn -- --layout-only
##
## Sections: L layout, 1-5 the original loop tests, G groundwork,
##           A active skills, K leader skills, P passives, S stacking numbers.

const BattleScene := preload("res://scenes/battle.tscn")
const BERSERKER := preload("res://data/team/fire_berserker.tres")
const BIOTECH := preload("res://data/team/water_biotech.tres")
const TITAN := preload("res://data/team/wood_titan.tres")
const SPECTRE := preload("res://data/team/dark_spectre.tres")

## Board layouts. F fire, W water, G wood (green), L light, D dark, H heart.
## BASE has no matches at all; the others change only the bottom row.
const BASE := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "FWGLDH"]
const FIRE3 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "FFFLDH"]
const FIRE4 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "FFFFDH"]
const WATER3 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "WWWLDH"]
const WATER4 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "WWWWDH"]
const DARK4 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "DDDDLH"]
const HEART3 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "HHHLDW"]
const DARK3 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "DDDLWH"]
const LIGHT3 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "LLLFWH"]
const LIGHT4 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "LLLLWH"]
const WOOD3 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "GGGLDH"]
const WOOD4 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "GGGGDH"]
const HEART5 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "HHHHHW"]
## Fire, Water and Wood matched in one turn (3 combos, 3 elements).
const THREE_ELEMENTS := ["FWGLDH", "LDHFWG", "GGGLDH", "LDHFWG", "FFFWWW"]
## Exactly 5 separate matches: fire, water, wood, light, dark.
const FIVE_COMBOS := ["FFFWWW", "LDHLDH", "GGGLLL", "DHFWGH", "DDDHFW"]
## A 3x3 square of fire (9 orbs) in the bottom-left corner.
const FIRE_SQUARE := ["LDHWGL", "WGLDHW", "FFFGLD", "FFFHWG", "FFFLDH"]
## Column 0 has 3 fire at the bottom with 2 water above. When the fire clears,
## the water falls next to the 2 water in the bottom row: a guaranteed cascade.
const CASCADE := ["WDGLDH", "WFHFWG", "FWGLDH", "FDHFWG", "FWWLDH"]

var battle: Node2D
var lines := PackedStringArray()
var fails := 0
var last_combos := 0
var last_cleared := {}
var last_groups: Array = []
var texts: Array = []        ## [text, font_size] of every popup number shown
var max_team_hp_seen := 0
var screenshots := true
var only: PackedStringArray = []


func _ready() -> void:
	GameSettings.path = "user://test_settings.json"   # never touch the player's settings
	GameSettings.skill_cut_ins = false   # cut-ins are tested in friends_test; keep these timings as they were
	Profile.friend_drops = false   # no random 1-in-400 friend joining this test's teams
	screenshots = DisplayServer.get_name() != "headless"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/screenshots"))
	battle = BattleScene.instantiate()
	add_child(battle)
	await _frames(3)
	if not "team" in battle:
		_check(false, "battle script failed to load (see the Godot log for the parse error)")
		battle = null
		_finish()
		return
	battle.board.turn_finished.connect(_on_turn_finished)
	battle.world.child_entered_tree.connect(_on_world_child)
	# Sections L, 1-5, G, A, K, P use the old placeholder test fights (fixed numbers).
	battle.act_fights = battle.TEST_FIGHTS
	battle._start_battle(0, battle.StartMode.NEW_ACT)
	await _frames(2)

	_log("Godot %s · window %s · viewport %s" % [Engine.get_version_info().string, DisplayServer.window_get_size(), battle.get_viewport_rect().size])
	if _run("L"):
		await _test_layout()
	if "--layout-only" in OS.get_cmdline_user_args():
		_finish()
		return
	if _run("1"):
		await _test_1_board_and_drag()
	if _run("2"):
		await _test_2_match_gravity_combos()
	if _run("3"):
		await _test_3_damage()
	if _run("4"):
		await _test_4_enemy_attack_heal_win_lose()
	if _run("5"):
		await _test_5_fight_again_next_fight()
	if _run("G"):
		await _test_groundwork()
	if _run("A"):
		await _test_active_skills()
	if _run("K"):
		await _test_leader_skills()
	if _run("P"):
		await _test_passives()
	if _run("S"):
		_test_stacking()
	if _run("B"):
		_test_balance()
	if _run("F"):
		await _test_act1_fights()
	if _run("X"):
		await _test_later_acts()
	_finish()


func _run(section: String) -> bool:
	return only.is_empty() or section in only


func _process(_delta: float) -> void:
	if battle and battle.team:
		max_team_hp_seen = maxi(max_team_hp_seen, battle.team.hp)
	# Acts 2-10 have story beats since Stage 6 (boss taunt, outro): skip them here
	# (they are tested in story_test); the rules are what this test checks.
	if battle and battle.act != null and battle.story_beat.is_open():
		battle.story_beat.close()


# ---------------------------------------------------------------- original loop tests (new numbers)

func _test_layout() -> void:
	_log("\n== Layout ==")
	var view: Vector2 = battle.get_viewport_rect().size
	var board_top: float = battle.board.global_position.y
	var board_bottom := board_top + Board.ROWS * Board.CELL
	var team_bar_y: float = battle.team_bar.global_position.y
	var enemy_y: float = battle.enemy_views[0].global_position.y
	_check(board_bottom <= view.y, "board fits on screen (bottom %d <= %d)" % [board_bottom, view.y])
	_check(view.y - board_bottom < 20.0, "board sits at the bottom edge (gap %d px)" % [view.y - board_bottom])
	_check(team_bar_y < board_top and enemy_y < team_bar_y, "order top->bottom: enemy (%d), team bar (%d), board (%d)" % [enemy_y, team_bar_y, board_top])
	var orb: Orb = battle.board.grid[0][0]
	_check(is_equal_approx(orb.global_transform.get_scale().x, orb.global_transform.get_scale().y), "orbs stay round (scale %s)" % orb.global_transform.get_scale())
	await _shot("layout_%dx%d" % [view.x, view.y])
	# 3 enemies and a team of 4 must also fit side by side.
	battle.set_team([SPECTRE, BERSERKER, BIOTECH, TITAN])
	battle._start_battle(2)
	await _frames(3)
	var left: float = battle.team_views[0].global_position.x - battle.team_views[0].card_size.x * 0.5
	var right: float = battle.team_views[3].global_position.x + battle.team_views[3].card_size.x * 0.5
	var stage_x: float = battle.stage.position.x
	_check(left - stage_x >= 0.0 and right - stage_x <= 1080.0, "team of 4 cards fits the width (%d..%d of 1080)" % [left - stage_x, right - stage_x])
	var e_left: float = battle.enemy_views[0].global_position.x - battle.enemies[0].data.figure_width * 0.5 - stage_x
	var e_right: float = battle.enemy_views[2].global_position.x + battle.enemies[2].data.figure_width * 0.5 - stage_x
	_check(e_left >= 0.0 and e_right <= 1080.0, "3 enemies fit the width (%d..%d of 1080)" % [e_left, e_right])
	await _shot("layout_team4_enemies3_%dx%d" % [view.x, view.y])
	_story_team()


func _test_1_board_and_drag() -> void:
	_log("\n== Test 1: board + drag ==")
	var board: Board = battle.board
	var bad := 0
	var seen := {}
	for i in 300:
		board.fill_new_board()
		if not MatchFinder.find_combos(board._type_grid(), Board.COLS, Board.ROWS).is_empty():
			bad += 1
		for x in Board.COLS:
			for y in Board.ROWS:
				seen[board._type_at(x, y)] = true
	_check(bad == 0, "300 fresh boards, ready-made matches found: %d" % bad)
	var names := PackedStringArray()
	for t in Element.BOARD_TYPES:
		if seen.has(t):
			names.append(Element.display_name(t))
	_check(names.size() == 6, "all 6 orb types appear on the board: %s" % ", ".join(names))

	battle._start_battle(0)
	await _frames(2)
	_check(battle.timer_bar._text.begins_with("DRAG AN ORB"), "before pickup the timer bar says: \"%s\"" % battle.timer_bar._text)
	var g := board.grid
	var o00: Orb = g[0][0]
	var o10: Orb = g[1][0]
	var o20: Orb = g[2][0]
	var o31: Orb = g[3][1]
	var o42: Orb = g[4][2]
	var o52: Orb = g[5][2]
	var o53: Orb = g[5][3]

	_press(_cell_pos(Vector2i(0, 0)))
	await _frames(2)
	_check(board._held == o00 and o00.held, "pressed orb is picked up")
	_check(is_equal_approx(o00.scale.x, 1.15), "held orb scale = %.2f (want 1.15)" % o00.scale.x)
	# Read 2 frames after pickup; a slow frame can already show 4.8, so allow 4.5-5.0.
	var t0 := float(battle.timer_bar._text.trim_suffix(" s"))
	_check(battle.timer_bar._text.ends_with(" s") and t0 >= 4.5 and t0 <= 5.0, "timer starts on pickup: \"%s\" (want 4.5-5.0 s)" % battle.timer_bar._text)

	# Slow drag right across 2 orbs.
	await _drag_path([Vector2(0.75, 0.5), Vector2(1.0, 0.5), Vector2(1.25, 0.5), Vector2(1.5, 0.5), Vector2(1.75, 0.5), Vector2(2.0, 0.5), Vector2(2.5, 0.5)])
	var trail_points: int = board._trail.get_point_count()
	_check(trail_points >= 5, "glowing trail visible while dragging (%d points)" % trail_points)
	await _shot("t1_dragging_trail")
	# Fast diagonal flick: one big jump per frame.
	await _drag_path([Vector2(3.5, 1.5), Vector2(4.5, 2.5)])
	# Sloppy real-thumb diagonal: clips the corner of (5,2) on the way to (5,3).
	await _drag_path([Vector2(5.13, 2.83), Vector2(5.46, 3.16)])

	_check(g[0][0] == o10 and g[1][0] == o20, "sideways swaps: the 2 orbs shifted left one cell")
	_check(g[2][0] == o31 and g[3][1] == o42, "fast diagonal swaps worked: (3,1)->(2,0), (4,2)->(3,1)")
	_check(g[4][2] == o53 and g[5][2] == o52, "sloppy diagonal swapped (5,3) diagonally and left (5,2) alone")
	_check(g[5][3] == o00 and board._held_cell == Vector2i(5, 3), "held orb ended at (5,3)")

	# Keep holding: the timer must run out on its own.
	await get_tree().create_timer(1.0).timeout
	var mid_text: String = battle.timer_bar._text
	var t := 0.0
	while board.state == Board.State.DRAGGING and t < 8.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	_check(board.state != Board.State.DRAGGING, "timer ran out while still holding -> drag locked (counted \"%s\" ~1 s in, ended after ~%.1f s total)" % [mid_text, t + 1.0 + 0.3])
	# Moving after time-out must do nothing.
	_move(_cell_pos(Vector2i(0, 4)))
	await _frames(1)
	_release(_cell_pos(Vector2i(0, 4)))
	_check(board.state != Board.State.DRAGGING, "moving after time-out does nothing (state %s)" % Board.State.keys()[board.state])
	await _await_turn_end()


func _test_2_match_gravity_combos() -> void:
	_log("\n== Test 2: match + gravity + combos ==")
	battle._start_battle(0)
	await _frames(2)
	_set_board(CASCADE)
	texts.clear()
	var initial := MatchFinder.find_combos(battle.board._type_grid(), Board.COLS, Board.ROWS)
	_check(initial.size() == 1, "set-up board has exactly 1 match waiting (3 fire in column 0)")
	var water_top: Orb = battle.board.grid[0][1]
	await _tap(Vector2i(5, 0))
	await _frames(1)
	await get_tree().create_timer(0.5).timeout
	await _shot("t2_cascade")
	await _await_turn_end()
	var combo_popups := texts.filter(func(e: Array) -> bool: return String(e[0]).begins_with("COMBO"))
	var popup_names := PackedStringArray(combo_popups.map(func(e: Array) -> String: return e[0]))
	_check(last_combos >= 2, "cascade chained: %d combos (popups: %s)" % [last_combos, ", ".join(popup_names)])
	_check(last_cleared.get(Element.Type.FIRE, 0) >= 3 and last_cleared.get(Element.Type.WATER, 0) >= 3, "cleared fire %d, water %d" % [last_cleared.get(Element.Type.FIRE, 0), last_cleared.get(Element.Type.WATER, 0)])
	_check(not is_instance_valid(water_top) or water_top.position.y > Board.CELL * 2, "orbs above fell down into the gap")
	var full := true
	for x in Board.COLS:
		for y in Board.ROWS:
			if battle.board.grid[x][y] == null:
				full = false
	_check(full, "new orbs dropped in: board is full again (30 orbs)")
	# Check the combo multiplier through the real damage on that turn.
	var expected := 0
	for m in battle.team.members:
		expected += DamageCalculator.attack_damage(m.atk, last_cleared.get(m.element, 0), last_combos, m.element, Element.Type.WOOD)
	var dealt: int = 800 - battle.enemies[0].hp
	_check(dealt == mini(expected, 800), "damage with %d combos (x%.2f) = %d, formula says %d" % [last_combos, DamageCalculator.combo_multiplier(last_combos), dealt, expected])
	_check(is_equal_approx(DamageCalculator.combo_multiplier(1), 1.0) and is_equal_approx(DamageCalculator.combo_multiplier(2), 1.25) and is_equal_approx(DamageCalculator.combo_multiplier(5), 2.0), "combo multiplier: 1 -> 1.00x, 2 -> 1.25x, 5 -> 2.00x")


func _test_3_damage() -> void:
	_log("\n== Test 3: damage + enemy HP ==")
	# 3 fire vs Wood enemy, exactly 1 combo. Fire Berserker ATK 95 x 1 x 1 x 2 = 190.
	var ok := await _single_combo_turn(FIRE3, 0)
	var hit := _find_text("190!")
	_check(ok and battle.enemies[0].hp == 610, "3 fire vs Wood, 1 combo: 95 x 2 = 190, enemy HP 800 -> %d (want 610)" % battle.enemies[0].hp)
	_check(not hit.is_empty() and hit[1] == 92, "big \"190!\" shown on screen (font size %s, normal is 66)" % [hit[1] if not hit.is_empty() else "missing"])
	await _shot("t3_fire_190")

	# Water Biotech ATK 72 x 0.5 = 36 (Stage 2 buff: was 55).
	ok = await _single_combo_turn(WATER3, 0)
	var weak := _find_text("36")
	_check(ok and battle.enemies[0].hp == 764, "3 water vs Wood, 1 combo: 72 x 0.5 = 36 -> shows %s, enemy HP 800 -> %d (want 36 / 764)" % [weak[0] if not weak.is_empty() else "?", battle.enemies[0].hp])
	_check(not weak.is_empty() and weak[1] == 48, "weak hit shown SMALL (font size %s)" % [weak[1] if not weak.is_empty() else "missing"])


func _test_4_enemy_attack_heal_win_lose() -> void:
	_log("\n== Test 4: enemy attack + team HP + heal + WIN / LOSE ==")
	# Team HP 320 + 350 + 470 = 1140. RCV 10 + 46 + 26 = 82 (Stage 2 Biotech / Titan buff).
	battle._start_battle(0)
	await _frames(2)
	_check(battle.team.max_hp == 1140 and battle.team.total_rcv == 82, "story team: max HP %d (want 1140), RCV %d (want 82)" % [battle.team.max_hp, battle.team.total_rcv])
	_set_board(BASE)
	texts.clear()
	await _tap(Vector2i(5, 0))
	await _await_turn_end()
	_check(battle.team.hp == 1020 and not _find_text("-120").is_empty(), "no match -> enemy hits for 120: team HP 1140 -> %d" % battle.team.hp)

	# Hearts heal 82 (RCV 82 x 3/3), then the enemy hits again.
	var healed_ok := false
	for attempt in 20:
		battle._start_battle(0)
		await _frames(2)
		_set_board(BASE)
		await _tap(Vector2i(5, 0))
		await _await_turn_end()
		_set_board(HEART3)
		texts.clear()
		seed(500 + attempt)
		await _tap(Vector2i(5, 0))
		await _await_turn_end()
		if last_cleared.get(Element.Type.HEART, 0) == 3 and last_combos == 1:
			healed_ok = true
			break
	_check(healed_ok and not _find_text("+82").is_empty() and battle.team.hp == 982, "3 hearts at 1020 HP: \"+82\" -> 1102, then enemy -120 -> %d (want 982)" % battle.team.hp)

	# Heal cap: hearts at full HP.
	max_team_hp_seen = 0
	battle._start_battle(0)
	await _frames(2)
	_set_board(HEART3)
	texts.clear()
	await _tap(Vector2i(5, 0))
	await _await_turn_end()
	_check(not _find_text("+0").is_empty() and max_team_hp_seen == 1140, "hearts at full HP heal +0; highest team HP ever seen = %d (cap 1140)" % max_team_hp_seen)
	var probe := Team.new(_typed([BERSERKER, BIOTECH, TITAN]))
	probe.take_damage(100)
	var got := probe.heal(9999)
	_check(got == 100 and probe.hp == 1140, "Team.heal(9999) at 1040 HP heals only %d -> %d" % [got, probe.hp])

	# WIN.
	var turns := await _play_until_result(0, FIRE3)
	_check(battle.result_panel.visible and battle.result_panel._title.text == "WIN!", "WIN after %d turns of 3-fire matches (800 / 190 = 4.2 -> 5); team HP left %d" % [turns, battle.team.hp])
	await _shot("t4_win")

	# LOSE: never match anything.
	turns = await _play_until_result(0, BASE)
	_check(battle.result_panel.visible and battle.result_panel._title.text == "LOSE", "LOSE after %d turns of no damage (1140 / 120 = 9.5 -> 10 hits); team HP %d" % [turns, battle.team.hp])
	_check(battle.result_panel._retry_button.text == "Retry" and not battle.result_panel._next_button.visible, "LOSE screen shows only \"Retry\"")
	await _shot("t4_lose")


func _test_5_fight_again_next_fight() -> void:
	_log("\n== Test 5: Fight Again / Next Fight ==")
	await _play_until_result(0, FIRE3)
	_check(battle.result_panel._retry_button.text == "Fight Again" and battle.result_panel._next_button.text == "Next Fight", "WIN buttons: \"%s\" + \"%s\"" % [battle.result_panel._retry_button.text, battle.result_panel._next_button.text])
	await _click(battle.result_panel._retry_button)
	_check(not battle.result_panel.visible and battle.fight_index == 0 and battle.enemies[0].hp == 800 and battle.team.hp == 1140 and battle.board.state == Board.State.READY,
		"Fight Again: fight %d, enemy at %d HP, team %d HP, board ready" % [battle.fight_index + 1, battle.enemies[0].hp, battle.team.hp])

	await _play_until_result(0, FIRE3, false)
	await _click(battle.result_panel._next_button)
	var e: FighterData = battle.enemies[0].data
	_check(battle.fight_index == 1 and battle.enemies[0].hp == 1200 and e.atk == 150 and e.element == Element.Type.FIRE,
		"Next Fight: \"%s\" enemy HP %d, ATK %d, element %s" % [battle.enemy_title.text, battle.enemies[0].hp, e.atk, Element.display_name(e.element)])
	_check(battle.enemy_attack_label.text == "Attacks after your turn  ·  ATK 150", "attack label: \"%s\"" % battle.enemy_attack_label.text)
	await _frames(20)
	await _shot("t5_fight2")


# ---------------------------------------------------------------- G: groundwork

func _test_groundwork() -> void:
	_log("\n== G1: Light and Dark ==")
	var T := Element.Type
	_check(Element.multiplier(T.LIGHT, T.DARK) == 2.0 and Element.multiplier(T.DARK, T.LIGHT) == 2.0,
		"Light hits Dark 2x and Dark hits Light 2x")
	_check(Element.multiplier(T.LIGHT, T.FIRE) == 1.0 and Element.multiplier(T.FIRE, T.DARK) == 1.0 and Element.multiplier(T.DARK, T.WOOD) == 1.0,
		"Light/Dark vs Fire/Water/Wood is neutral 1x (both ways)")
	_check(Element.multiplier(T.FIRE, T.WOOD) == 2.0 and Element.multiplier(T.FIRE, T.WATER) == 0.5, "old wheel unchanged: Fire 2x Wood, 0.5x Water")

	_log("\n== G2: type stats (Lv1) ==")
	# Stage 2: Titan and Biotech buffed (were 420/65/22 and 320/55/40).
	var rows := [[BERSERKER, 320, 95, 10], [TITAN, 470, 78, 26], [SPECTRE, 230, 110, 8], [BIOTECH, 350, 72, 46]]
	for r in rows:
		var d: FighterData = r[0]
		_check(d.max_hp == r[1] and d.atk == r[2] and d.rcv == r[3], "%s: %d / %d / %d (want %d / %d / %d)" % [d.display_name, d.max_hp, d.atk, d.rcv, r[1], r[2], r[3]])

	_log("\n== G3: several enemies + tap to target ==")
	_story_team()
	# Fight 3: Drone A (Water), Drone B (Light), Drone C (Dark), 500 HP each.
	var ok := await _single_combo_turn(FIRE3, 2)
	var hp := _enemy_hps()
	_check(ok and hp == [452, 500, 500], "no target chosen: 3 fire hits only the FRONT enemy (Drone A, Water: 95 x 0.5 = 48) -> HP %s" % [hp])
	_check(battle.team.hp == 1140 - 180, "all 3 enemies attack after the turn: 60 x 3 = 180 -> team %d" % battle.team.hp)
	for attempt in 30:
		battle._start_battle(2)
		await _frames(2)
		await _click_enemy(2)
		_set_board(FIRE3)
		seed(1000 + attempt)
		await _tap(Vector2i(5, 0))
		await _await_turn_end()
		if last_combos == 1:
			break
	hp = _enemy_hps()
	_check(battle.target_index == 2 and hp == [500, 500, 405], "tapped Drone C: 3 fire hits it (Fire vs Dark neutral 95) -> HP %s" % [hp])
	_check(battle.enemy_views[2].targeted, "target ring shows on the tapped enemy")
	await _shot("g3_target_ring")
	await _click_enemy(2)
	_check(battle.target_index == -1 and not battle.enemy_views[2].targeted, "tapping the same enemy again clears the target")

	_log("\n== G4: Berserker hits all on 4+ ==")
	ok = await _single_combo_turn(FIRE4, 2)
	hp = _enemy_hps()
	# 95 x 4/3 x 2 (Berserker leader: 4+ fire in one group) = 253.3 -> x0.5 vs Water = 127;
	# neutral vs Light / Dark = 253.
	_check(ok and hp == [373, 247, 247], "4 fire in one group: Berserker hits ALL 3, with its leader x2 (127 / 253 / 253) -> HP %s" % [hp])
	await _shot("g4_berserker_all")
	ok = await _single_combo_turn(FIRE3, 2)
	hp = _enemy_hps()
	_check(ok and hp == [452, 500, 500], "only 3 fire: Berserker hits just one enemy -> HP %s" % [hp])

	_log("\n== G5: Spectre always hits one ==")
	battle.set_team([SPECTRE, BERSERKER, BIOTECH, TITAN])
	ok = await _single_combo_turn(DARK4, 2)
	hp = _enemy_hps()
	# Spectre ATK 110 x 4/3 = 146.7 -> 147 vs Drone A (Water, neutral). 4 dark is NOT "hit all" for a Spectre.
	_check(ok and hp == [353, 500, 500], "4 dark in one group: Spectre still hits only the front enemy (147) -> HP %s" % [hp])
	_check(battle.team.max_hp == 1370, "team of 4 (Spectre + story trio): max HP %d (want 1370)" % battle.team.max_hp)
	await _shot("g5_team_of_4")
	_story_team()

	_log("\n== G6: Shield (Armoured) gimmick ==")
	# Test boss: Fire, 1500 HP, armoured. Water Biotech hits Fire 2x: 72 x 2 = 144.
	ok = await _single_combo_turn(WATER3, 3)
	_check(ok and battle.enemies[0].hp == 1500 - 72 and battle.enemies[0].armor_up, "armour up: 3 water (144) is halved to 72 -> HP %d, armour still up" % battle.enemies[0].hp)
	ok = await _single_combo_turn(WATER4, 3)
	# 72 x 4/3 x 2 = 192, full damage because the 4+ group breaks the armour.
	_check(ok and battle.enemies[0].hp == 1500 - 192 and not battle.enemies[0].armor_up, "a 4+ group breaks the armour and hits in full (192) -> HP %d" % battle.enemies[0].hp)


# ---------------------------------------------------------------- A: active skills

func _test_active_skills() -> void:
	var Mode = battle.StartMode
	_log("\n== A0: skill charging ==")
	_story_team()
	battle._start_battle(0, Mode.NEW_ACT)
	await _frames(2)
	_check(battle.team.skill_turns == [4, 3, 3], "first fight of an Act starts half charged: Overrun 7->4, Mend 5->3, Bulwark 6->3 turns left: %s" % [battle.team.skill_turns])
	_check(battle.team_views[0].skill_turns == 4 and battle.team_views[1].skill_turns == 3, "card badges show the turns left (%d, %d, %d)" % [battle.team_views[0].skill_turns, battle.team_views[1].skill_turns, battle.team_views[2].skill_turns])
	_set_board(BASE)
	await _tap(Vector2i(5, 0))
	await _await_turn_end()
	_check(battle.team.skill_turns == [4, 3, 3], "a turn with NO match does not charge skills: %s" % [battle.team.skill_turns])
	_set_board(FIRE3)
	await _tap(Vector2i(5, 0))
	await _await_turn_end()
	_check(battle.team.skill_turns == [3, 2, 2], "a turn with a match charges every skill by 1: %s" % [battle.team.skill_turns])
	await _play_until_result(0, FIRE3, false)
	var end_turns: Array = battle.team.skill_turns.duplicate()
	await _click(battle.result_panel._next_button)
	_check(battle.fight_index == 1 and battle.team.skill_turns == end_turns, "charge carries over to the next fight in the Act: %s -> %s" % [end_turns, battle.team.skill_turns])
	await _use_skill_by_tapping(1)
	_check(battle.team.skill_turns[1] == 5, "used Mend in fight 2: it needs 5 turns again (%d)" % battle.team.skill_turns[1])
	await _play_until_result(1, BASE, false)
	await _click(battle.result_panel._retry_button)
	_check(battle.team.skill_turns == end_turns, "Retry restores the charge this fight started with: %s" % [battle.team.skill_turns])
	battle.fight_index = battle.act_fights.size() - 1
	battle._on_next_pressed()
	await _frames(2)
	_check(battle.fight_index == 0 and battle.team.skill_turns == [4, 3, 3], "after the last fight a new Act starts half charged again: %s" % [battle.team.skill_turns])

	_log("\n== A1: Overrun (Berserker) ==")
	battle._start_battle(0, Mode.NEW_ACT)
	await _frames(2)
	_set_board(BASE)
	var wood_before: int = battle.board.count_type(Element.Type.WOOD)
	var fire_before: int = battle.board.count_type(Element.Type.FIRE)
	await _click_card(1)
	_check(battle.skill_popup.visible and battle.skill_popup.use_button.disabled, "tapping a card that is still charging opens the pop-up with USE greyed out")
	await _shot("a_popup_charging")
	await _click(battle.skill_popup.close_button)
	_ready_skill(0)
	var turns_before: int = battle.turn_count
	await _use_skill_by_tapping(0)
	var wood_after: int = battle.board.count_type(Element.Type.WOOD)
	var fire_after: int = battle.board.count_type(Element.Type.FIRE)
	_check(wood_after == 0 and fire_after == fire_before + wood_before, "Overrun: all %d Wood orbs became Fire (Fire %d -> %d, Wood %d -> %d)" % [wood_before, fire_before, fire_after, wood_before, wood_after])
	_check(battle.team.skill_turns[0] == 7 and battle.team_views[0].skill_turns == 7, "Overrun goes back to 7 turns after use")
	_check(battle.board.state == Board.State.READY and battle.turn_count == turns_before and battle.team.hp == 1140, "using a skill does NOT end the turn (board ready, enemy did not attack)")
	await _shot("a1_overrun")

	_log("\n== A2: Bulwark (Titan) ==")
	battle._start_battle(0, Mode.NEW_ACT)
	await _frames(2)
	_ready_skill(2)
	await _use_skill_by_tapping(2)
	_check(battle.team.bulwark_attacks == 2 and battle.team_status_label.text.contains("BULWARK"), "Bulwark is up for 2 enemy attacks (status: \"%s\")" % battle.team_status_label.text)
	var hps := []
	for k in 3:
		_set_board(BASE)
		await _tap(Vector2i(5, 0))
		await _await_turn_end()
		hps.append(battle.team.hp)
	_check(hps == [1080, 1020, 900], "enemy ATK 120: hits for 60, 60, then 120 again -> team HP %s (want [1080, 1020, 900])" % [hps])
	battle._start_battle(2, Mode.NEW_ACT)
	await _frames(2)
	_ready_skill(2)
	await _use_skill_by_tapping(2)
	_set_board(BASE)
	await _tap(Vector2i(5, 0))
	await _await_turn_end()
	_check(battle.team.hp == 1140 - 30 - 30 - 60, "vs 3 drones (ATK 60 each): Bulwark covers the first 2 ATTACKS, not 2 turns -> 30 + 30 + 60, team %d (want 1020)" % battle.team.hp)

	_log("\n== A3: Execute (Spectre) ==")
	battle.set_team([SPECTRE, BERSERKER, BIOTECH, TITAN])
	battle.test_fight_override = _dummy_fight(4000, false, false)
	battle._start_battle(0, Mode.NEW_ACT)
	await _frames(2)
	_ready_skill(0)
	await _use_skill_by_tapping(0)
	_check(battle.enemies[0].hp == 4000 - 440, "Shadow Verdict on a healthy enemy: ATK 110 x 4 = 440 -> HP %d (want 3560)" % battle.enemies[0].hp)
	battle.enemies[0].hp = 900   # 22.5% HP
	_ready_skill(0)
	await _use_skill_by_tapping(0)
	_check(battle.enemies[0].hp == 0, "Execute below 25%% HP (900 / 4000): defeated instantly -> HP %d" % battle.enemies[0].hp)
	_check(battle.result_panel.visible, "killing the last enemy with a skill wins the fight")
	battle.test_fight_override = _dummy_fight(4000, true, false)
	battle._start_battle(0, Mode.NEW_ACT)
	await _frames(2)
	battle.enemies[0].hp = 900
	_ready_skill(0)
	await _use_skill_by_tapping(0)
	_check(battle.enemies[0].hp == 900 - 660, "a BOSS below 25%% is not killed instantly: takes ATK x6 = 660 -> HP %d (want 240)" % battle.enemies[0].hp)
	battle.test_fight_override = _dummy_fight(4000, false, true)
	battle._start_battle(0, Mode.NEW_ACT)
	await _frames(2)
	_ready_skill(0)
	await _use_skill_by_tapping(0)
	_check(battle.enemies[0].hp == 4000 - 440 and not battle.enemies[0].armor_up, "Shadow Verdict on an ARMOURED enemy breaks the armour and hits in full (440, not 220) -> HP %d" % battle.enemies[0].hp)
	battle.test_fight_override = null
	battle._start_battle(2, Mode.NEW_ACT)
	await _frames(2)
	await _click_enemy(2)
	_ready_skill(0)
	await _use_skill_by_tapping(0)
	_check(_enemy_hps() == [500, 500, 60], "Shadow Verdict goes to the TAPPED enemy (Drone C: 500 - 440 = 60): HP %s" % [_enemy_hps()])
	await _shot("a3_execute_target")
	_story_team()

	_log("\n== A4: Mend (Biotech) ==")
	battle._start_battle(0, Mode.NEW_ACT)
	await _frames(2)
	_set_board(BASE)
	battle.team.take_damage(500)
	battle.team_bar.set_values(battle.team.hp, battle.team.max_hp, false)
	var hearts_before: int = battle.board.count_type(Element.Type.HEART)
	var others_before: Array = battle.team.skill_turns.duplicate()
	_ready_skill(1)
	await _use_skill_by_tapping(1)
	_check(battle.team.hp == 640 + 342, "Mend heals 30%% of 1140 = 342: 640 -> %d (want 982)" % battle.team.hp)
	_check(battle.board.count_type(Element.Type.HEART) == hearts_before + 3, "Mend turns 3 orbs into Hearts (%d -> %d)" % [hearts_before, battle.board.count_type(Element.Type.HEART)])
	_check(battle.team.skill_turns[0] == others_before[0] and battle.team.skill_turns[2] == others_before[2], "without Field Medic (locked) the other skills don't charge")
	await _shot("a4_mend")


# ---------------------------------------------------------------- K: leader skills

func _test_leader_skills() -> void:
	_log("\n== K1: Berserker leader (slot 1 = Fire Berserker) ==")
	_story_team()
	battle.test_fight_override = _dummy_fight(4000, false, false)   # Wood dummy, ATK 10
	var ok := await _turn_with(FIRE4, 1)
	# 95 x 4/3 x 1 combo x 2 (Fire vs Wood) x 2 (leader) = 506.7 -> 507
	_check(ok and battle.enemies[0].hp == 4000 - 507, "4 fire in one group: leader doubles Fire hunters: 95 x 4/3 x 2 x 2 = 507 -> HP %d" % battle.enemies[0].hp)
	ok = await _turn_with(FIRE3, 1)
	_check(ok and battle.enemies[0].hp == 4000 - 190, "only 3 fire: leader skill does not trigger (190) -> HP %d" % battle.enemies[0].hp)
	battle.set_team([BIOTECH, BERSERKER, TITAN])
	ok = await _turn_with(FIRE4, 1)
	_check(ok and battle.enemies[0].hp == 4000 - 253, "same 4 fire with the Berserker NOT in slot 1: no x2 (253) -> HP %d" % battle.enemies[0].hp)

	_log("\n== K2: Titan leader ==")
	battle.set_team([TITAN, BERSERKER, BIOTECH])
	battle.test_fight_override = null
	battle._start_battle(0, battle.StartMode.NEW_ACT)
	await _frames(2)
	_check(battle.team.max_hp == 1482, "team HP x1.3: 1140 -> %d (want 1482)" % battle.team.max_hp)
	ok = await _turn_with(HEART3, 1, 0)
	_check(ok and battle.team.hp == 1482 - 90, "Hearts matched: the next enemy hit is 25%% weaker (120 -> 90) -> team %d" % battle.team.hp)
	_set_board(BASE)
	await _tap(Vector2i(5, 0))
	await _await_turn_end()
	_check(battle.team.hp == 1482 - 90 - 120, "guard is used up: the hit after that is a full 120 -> team %d" % battle.team.hp)

	_log("\n== K3: Spectre leader ==")
	battle.set_team([SPECTRE, BERSERKER, BIOTECH, TITAN])
	var mults := []
	for c in [4, 5, 6, 7, 9]:
		mults.append(CombatRules.leader_multiplier(SPECTRE, BERSERKER, [], c))
	_check(mults == [1.0, 1.5, 2.0, 2.5, 2.5], "team ATK by combos 4 / 5 / 6 / 7 / 9: %s (6 sits between 5 and 7)" % [mults])
	battle.test_fight_override = _dummy_fight(4000, false, false)
	ok = await _turn_with(FIVE_COMBOS, 5)
	# 5 combos = x2.0 combo, x1.5 leader. Dark 110x2x1.5=330, Fire 95x2x2x1.5=570,
	# Water 72x2x0.5x1.5=108, Wood 78x2x1x1.5=234. Total 1242.
	_check(ok and battle.enemies[0].hp == 4000 - 1242, "a real 5-combo turn with the Spectre leading: 330 + 570 + 108 + 234 = 1242 -> HP %d" % battle.enemies[0].hp)
	await _shot("k3_five_combos")

	_log("\n== K4: Biotech leader ==")
	battle.set_team([BIOTECH, BERSERKER, TITAN])
	ok = await _turn_with(THREE_ELEMENTS, 3, -1, 500)
	# 3 combos = x1.5. Fire 95x1.5x2x1.5=427.5->428, Water 72x1.5x0.5x1.5=81, Wood 78x1.5x1.5=175.5->176
	_check(ok and battle.enemies[0].hp == 4000 - 685, "Fire + Water + Wood matched (needs 2+ elements since Stage 2): team ATK x1.5 -> 428 + 81 + 176 = 685 -> HP %d" % battle.enemies[0].hp)
	_check(battle.team.hp == 500 + 114 - 10, "and heals 10%% of 1140 = 114 with no Hearts: 500 -> 614, dummy hits 10 -> %d (want 604)" % battle.team.hp)
	_check(CombatRules.distinct_attack_types([{"type": Element.Type.FIRE, "cells": []}, {"type": Element.Type.WATER, "cells": []}]) >= Skills.TUNING.leader_biotech_affinities,
		"2 elements are enough for the Biotech leader now (was 3)")
	ok = await _turn_with(FIRE3, 1)
	_check(ok and battle.enemies[0].hp == 4000 - 190, "only 1 element matched: no bonus (190) -> HP %d" % battle.enemies[0].hp)
	battle.test_fight_override = null
	_story_team()


# ---------------------------------------------------------------- P: passives

func _test_passives() -> void:
	battle.test_fight_override = _dummy_fight(4000, false, false)
	_log("\n== P1-P3: Berserker passives ==")
	battle.set_team([BIOTECH, _unlocked(BERSERKER, 1), TITAN])   # Biotech leads: no Berserker leader bonus
	var ok := await _turn_with(FIRE4, 1)
	_check(ok and battle.enemies[0].hp == 4000 - 380, "Cleave (Lv10): 4 fire in one group -> ATK x1.5: 95 x 4/3 x 2 x 1.5 = 380 -> HP %d" % battle.enemies[0].hp)
	battle.set_team([_unlocked(BERSERKER, 2), BIOTECH, TITAN])
	battle._start_battle(0, battle.StartMode.NEW_ACT)
	await _frames(2)
	_check(battle.team.skill_turns[0] == 3 and battle.team.skill_turns[1] == 3, "Skill Boost (Evo 1): Overrun starts the Act at 3 turns instead of 4 (others unchanged): %s" % [battle.team.skill_turns])
	battle.set_team([BIOTECH, _unlocked(BERSERKER, 3), TITAN])
	battle.test_fight_override = _dummy_fight(4000, false, true)   # armoured
	ok = await _turn_with(FIRE_SQUARE, 1)
	# 95 x 9/3 x 2 (vs Wood) x 1.5 (Cleave, 9 >= 4) x 2.5 (Breaker) = 2137.5 -> 2138, full damage through armour.
	_check(ok and battle.enemies[0].hp == 4000 - 2138, "Breaker (Evo 2): 3x3 fire square -> ATK x2.5, full damage through armour: 2138 -> HP %d" % battle.enemies[0].hp)
	await _shot("p3_breaker_square")
	battle.test_fight_override = _dummy_fight(4000, false, false)

	_log("\n== P4-P6: Titan passives ==")
	battle.test_fight_override = null
	battle.set_team([BERSERKER, BIOTECH, _unlocked(TITAN, 1)])
	ok = await _turn_with(BASE, 0, 0)
	_check(ok and battle.enemies[0].hp == 800 - 78 and battle.team.hp == 1140 - 120, "Counter (Lv10): enemy hits 120, Titan strikes back for ATK 78 -> enemy HP %d" % battle.enemies[0].hp)
	battle._start_battle(2, battle.StartMode.NEW_ACT)
	await _frames(2)
	_set_board(BASE)
	await _tap(Vector2i(5, 0))
	await _await_turn_end()
	_check(_enemy_hps() == [500 - 156, 500 - 78, 500 - 78], "Counter vs 3 drones: strikes back at EACH enemy that attacked (Wood vs Water 2x = 156, then 78, 78) -> HP %s" % [_enemy_hps()])
	battle.set_team([BERSERKER, BIOTECH, _unlocked(TITAN, 2)])
	battle._start_battle(0, battle.StartMode.NEW_ACT)
	await _frames(2)
	battle.team.hp = 50   # the enemy's 120 would defeat the team
	_set_board(BASE)
	await _tap(Vector2i(5, 0))
	await _await_turn_end()
	var saved: bool = battle.team.hp == 1 and battle.team.last_stand_used and not battle.result_panel.visible
	_check(saved, "Last Stand (Evo 1, Stage 3 version): a fatal hit (120 vs 50 HP) leaves the team at 1 HP -> team %d" % battle.team.hp)
	_set_board(BASE)
	await _tap(Vector2i(5, 0))
	await _await_turn_end()
	_check(battle.team.is_defeated() and battle.result_panel.visible, "Last Stand works once per fight: the next fatal hit defeats the team")
	var titan3 := _unlocked(TITAN, 3)
	battle.set_team([BERSERKER, BIOTECH, titan3])
	battle._start_battle(0, battle.StartMode.NEW_ACT)
	await _frames(2)
	var full: int = battle.team.hp
	_set_board(BASE)
	await _tap(Vector2i(5, 0))
	await _await_turn_end()
	_check(titan3.has_passive(&"damage_resist") and not titan3.has_passive(&"bind_resist") and full - battle.team.hp == 108,
		"Damage Resist (Evo 2, replaces Bind Resist): enemy 120 hits for 108 -> took %d" % (full - battle.team.hp))

	_log("\n== P7-P9: Spectre passives ==")
	battle.test_fight_override = _dummy_fight(4000, false, false)
	battle.set_team([BIOTECH, _unlocked(SPECTRE, 1), BERSERKER, TITAN])
	battle._start_battle(0, battle.StartMode.NEW_ACT)
	await _frames(2)
	var hp_before: int = battle.enemies[0].hp
	ok = await _turn_with(DARK3, 1, -1, -1, false)
	var first: int = hp_before - battle.enemies[0].hp
	hp_before = battle.enemies[0].hp
	var ok2 := await _turn_with(DARK3, 1, -1, -1, false)
	ok = ok and ok2
	var second: int = hp_before - battle.enemies[0].hp
	_check(ok and first == 220 and second == 110, "Ambush (Lv10): first attack of the fight x2 (220), the next is normal (%d) -> got %d then %d" % [110, first, second])
	var sp2 := _unlocked(SPECTRE, 2)
	var cb6 := CombatRules.passive_multiplier(sp2, [], 6, null, false)
	var cb7 := CombatRules.passive_multiplier(sp2, [], 7, null, false)
	_check(cb6 == 1.0 and cb7 == 2.0, "Combo Boost (Evo 1): x%s at 6 combos, x%s at 7 combos" % [cb6, cb7])
	battle.set_team([BIOTECH, _unlocked(SPECTRE, 3), BERSERKER, TITAN])
	battle._start_battle(0, battle.StartMode.NEW_ACT)
	await _frames(2)
	battle.team.has_attacked[1] = true   # Ambush already used
	battle.enemies[0].hp = 1900          # 47.5% HP
	ok = await _turn_with(DARK3, 1, -1, -1, false)
	_check(ok and battle.enemies[0].hp == 1900 - 165, "Finisher (Evo 2): enemy below 50%% -> x1.5: 110 x 1.5 = 165 -> HP %d" % battle.enemies[0].hp)

	_log("\n== P10-P12: Biotech passives ==")
	battle.test_fight_override = null
	battle.set_team([BERSERKER, _unlocked(BIOTECH, 1), TITAN])
	battle._start_battle(0, battle.StartMode.NEW_ACT)
	await _frames(2)
	_check(is_equal_approx(battle.board.move_time, 6.0) and battle.timer_bar._text.contains("6 s"), "Time Extend (Lv10): move time 6 s (bar says \"%s\")" % battle.timer_bar._text)
	_press(_cell_pos(Vector2i(0, 0)))
	await _frames(1)
	var t := 0.0
	while battle.board.state == Board.State.DRAGGING and t < 10.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	_release(_cell_pos(Vector2i(0, 0)))
	_check(t > 5.6 and t < 6.4, "holding an orb really lasts ~6 s now (%.1f s)" % t)
	await _await_turn_end()
	battle.set_team([BERSERKER, _unlocked(BIOTECH, 2), TITAN])
	battle.test_fight_override = _dummy_fight(4000, false, false)
	ok = await _turn_with(HEART5, 1, -1, 500)
	# RCV 82 x 5/3 = 136.7, x1.5 = 205. 500 + 205 = 705, dummy hits 10 -> 695.
	_check(ok and battle.team.hp == 695, "Overflow Heal (Evo 1): 5 Hearts in one group heal 136.7 x 1.5 = 205 -> team %d (want 695)" % battle.team.hp)
	battle.set_team([BERSERKER, _unlocked(BIOTECH, 3), TITAN])
	battle._start_battle(0, battle.StartMode.NEW_ACT)
	await _frames(2)
	battle.team.skill_turns.assign([4, 0, 4])
	battle._refresh_team_ui()
	await _use_skill_by_tapping(1)
	_check(battle.team.skill_turns == [3, 5, 3], "Field Medic (Evo 2): using Mend charges both allies by 1 turn: [4, 0, 4] -> %s" % [battle.team.skill_turns])
	battle.test_fight_override = null
	_story_team()


# ---------------------------------------------------------------- S: stacking numbers (J1)

func _test_stacking() -> void:
	_log("\n== S: damage stacking (numbers for tuning) ==")
	var boss_hp: int = StarMap.ACTS[0].fights[7].enemies[0].max_hp
	var empty: Array = []
	var fire5 := [{"type": Element.Type.FIRE, "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)]}]
	var b1 := _unlocked(BERSERKER, 1)
	for c in [1, 3, 6]:
		var bonus := CombatRules.leader_multiplier(b1, b1, fire5, c) * CombatRules.passive_multiplier(b1, fire5, c, null, false)
		var neutral := DamageCalculator.attack_damage(95, 5, c, Element.Type.FIRE, Element.Type.NONE, bonus)
		var vs_boss := DamageCalculator.attack_damage(95, 5, c, Element.Type.FIRE, Element.Type.FIRE, bonus)
		_log("INFO  Berserker leads + Cleave, 5-fire group, %d combo(s): x%.2f total bonus -> %d per enemy (Fire vs Fire Emberfang-9 is neutral 1x: %d), hits EVERY enemy" % [c, bonus * DamageCalculator.combo_multiplier(c), neutral, vs_boss])
	var s2 := _unlocked(SPECTRE, 2)
	for c in [5, 7, 9]:
		var bonus := CombatRules.leader_multiplier(s2, s2, empty, c) * CombatRules.passive_multiplier(s2, empty, c, null, false)
		var dmg := DamageCalculator.attack_damage(110, 3, c, Element.Type.DARK, Element.Type.FIRE, bonus)
		_log("INFO  Spectre leads + Combo Boost, 3 dark, %d combos: Spectre alone hits Emberfang-9 for %d (%s)" % [c, dmg, "ONE-TURN KILL" if dmg >= boss_hp else "not a kill"])
	_check(true, "Spectre's Combo Boost needs Evolution 1 (Lv15) and the Spectre joins in Act 2, so the x12 stack cannot happen in Act 1")


# ---------------------------------------------------------------- B: balance simulation, all 10 Acts

## Pure maths through the real damage code (see scripts/tools/balance_sim.gd).
## Each Act's team at each fight's expected level: the story trio, plus the
## Dark Spectre from Act 2.
func _test_balance() -> void:
	_log("\n== B: balance, all 10 Acts (GOOD / AVERAGE turns to win, IDLE turns to lose) ==")
	var p := CombatRules.PROGRESSION
	var xp := 0
	var end_levels := []
	for act in StarMap.ACTS:
		var n: int = act.act_number
		var good_turns := []
		var all_survive := true
		var bosses_hold := true
		_log("INFO  ACT %d · %s" % [n, act.colony_name.to_upper()])
		for f in act.fights:
			var team := BalanceSim.leveled_team(_team_for_act(n), f.expected_level)
			var good := BalanceSim.turns_to_win(f.enemies, team, "GOOD")
			var avg := BalanceSim.turns_to_win(f.enemies, team, "AVERAGE")
			var idle := BalanceSim.idle_turns(f.enemies, team)
			# Regular fights: average play survives. Mini-bosses and bosses: good play survives.
			var great := BalanceSim.great_turn(f.enemies, team)
			var survives := BalanceSim.avg_survives(f.enemies, team, "GOOD" if f.enemies[0].armored else "AVERAGE")
			good_turns.append(good)
			all_survive = all_survive and survives
			if f.enemies[0].armored:
				bosses_hold = bosses_hold and great["left"] > 0
			_log("INFO    %-36s Lv%2d  %d x %5d HP  ATK %3d%s | good %d, avg %2d, idle %2d, avg survives %s, one great turn: %s" % [f.display_name, f.expected_level,
				f.enemies.size(), f.enemies[0].max_hp, f.enemies[0].atk, " ARMOUR" if f.enemies[0].armored else "", good, avg, idle,
				"yes" if survives else "NO", "WINS" if great["left"] == 0 else "%d HP left" % great["left"]])
			xp += f.xp
		end_levels.append(p.level_for_xp(xp))
		_check(all_survive, "Act %d: average play survives every regular fight; good play survives the mini-bosses and the boss" % n)
		# Limit 10 since Stage 3 (Spectre ATK 130 -> 110 makes the Act 2+ test team a bit slower;
		# Acts 2-10 are rebuilt in Stage 6).
		_check(good_turns[7] == good_turns.max() and good_turns.max() <= 10, "Act %d: the boss is the longest fight with good play, 10 turns at most (%s)" % [n, good_turns])
		_check(bosses_hold, "Act %d: mini-bosses and the boss survive one perfect 6-combo turn" % n)
	_check(end_levels == [10, 12, 14, 16, 18, 20, 22, 24, 27, 30], "XP: story team level after each Act's boss: %s (Act 1 -> Lv10 ... Act 10 -> Lv30)" % [end_levels])
	_log("INFO  Stage 1 balance (2026-11-18): Act 1 is tuned for a Scrap / Alloy team; see tools/stage1_playtest_report.txt.")

# ---------------------------------------------------------------- F / X: the 5 loop tests on every fight

func _test_act1_fights() -> void:
	_log("\n== F: Act 1, the 5 loop tests on each fight ==")
	await _test_act_fights(1, 3.0)


## X: Acts 2-10 (or the ones given with --acts=2,5). Animations 6x faster.
func _test_later_acts() -> void:
	var acts := range(2, 11)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--acts="):
			acts = Array(a.trim_prefix("--acts=").split(",")).map(func(s: String) -> int: return int(s))
	for n in acts:
		_log("\n== X: Act %d, the 5 loop tests on each fight ==" % n)
		await _test_act_fights(n, 6.0)


func _test_act_fights(n: int, speed: float) -> void:
	var act: ActData = StarMap.ACTS[n - 1]
	battle.set_team(_team_for_act(n))
	battle.act_fights = act.fights
	# Acts 2-10: the battle knows its Act (titles, "ACT n CLEAR!"); their story beats
	# are skipped by _process. Act 1 runs without one (its beats are story_test's job).
	battle.act = act if n >= 2 else null
	Engine.time_scale = speed   # play animations faster; the rules don't change
	for i in act.fights.size():
		await _test_one_fight(act, i)
	Engine.time_scale = 1.0
	battle.act = null
	battle.act_fights = battle.TEST_FIGHTS
	_story_team()


func _team_for_act(n: int) -> Array:
	return [BERSERKER, BIOTECH, TITAN] if n == 1 else [BERSERKER, BIOTECH, TITAN, SPECTRE]


func _test_one_fight(act: ActData, i: int) -> void:
	var fight: FightData = act.fights[i]
	var Mode = battle.StartMode
	_log("\n-- Act %d fight %s --" % [act.act_number, fight.display_name])
	battle._start_battle(i, Mode.NEW_ACT)
	await _frames(2)
	var team_m := BalanceSim.leveled_team(_team_for_act(act.act_number), fight.expected_level)
	var team_hp := 0
	var team_rcv := 0
	for m in team_m:
		team_hp += m.max_hp
		team_rcv += m.rcv
	var ok_load: bool = battle.enemies.size() == fight.enemies.size() and battle.team.max_hp == team_hp and battle.team_level == fight.expected_level
	for k in battle.enemies.size():
		ok_load = ok_load and battle.enemies[k].hp == fight.enemies[k].max_hp and battle.enemy_views[k].armor_up == fight.enemies[k].armored
	_check(ok_load, "loads: %d enemies at full HP, team of %d at Lv%d with %d HP%s" % [fight.enemies.size(), team_m.size(), battle.team_level, battle.team.max_hp, ", ARMOUR badge shown" if fight.enemies[0].armored else ""])
	if act.act_number == 1 or i == 0 or i == 7:
		await _shot("act%02d_f%d_start" % [act.act_number, i + 1])

	# 1) Board + drag
	_check(MatchFinder.find_combos(battle.board._type_grid(), Board.COLS, Board.ROWS).is_empty() and battle.board.state == Board.State.READY
		and battle.timer_bar._text.contains("5 s"), "1 board: no ready match, board ready, 5 s timer")

	# 2) Match + gravity + combos
	battle._start_battle(i, Mode.NEW_ACT)
	await _frames(2)
	_set_board(CASCADE)
	await _tap(Vector2i(5, 0))
	await _await_turn_end()
	var full := true
	for x in Board.COLS:
		for y in Board.ROWS:
			full = full and battle.board.grid[x][y] != null
	_check(last_combos >= 2 and full, "2 match: cascade chained %d combos and the board refilled" % last_combos)

	# 3) Damage + enemy HP: best colour, 3 orbs, exactly 1 combo.
	var front: FighterData = fight.enemies[0]
	var best: FighterData = BalanceSim.ranked(team_m, front.element)[0]
	var rows3: Array = _rows_for(best.element, 3)
	var ok := false
	for attempt in 30:
		battle._start_battle(i, Mode.NEW_ACT)
		await _frames(2)
		_set_board(rows3)
		seed(3000 + attempt)
		await _tap(Vector2i(5, 0))
		await _await_turn_end()
		if last_combos == 1:
			ok = true
			break
	var want := DamageCalculator.attack_damage(best.atk, 3, 1, best.element, front.element)
	if front.armored:
		want = roundi(want * Enemy.ARMOR_FACTOR)
	var got: int = front.max_hp - battle.enemies[0].hp
	_check(ok and got == want, "3 damage: 3 %s vs %s %s -> %d (want %d%s)" % [Element.display_name(best.element), front.display_name, Element.display_name(front.element), got, want, ", halved by armour" if front.armored else ""])

	# 4) Enemy attack + heal + WIN / LOSE
	battle._start_battle(i, Mode.NEW_ACT)
	await _frames(2)
	var all_atk := 0
	for d in fight.enemies:
		all_atk += d.atk
	_set_board(BASE)
	await _tap(Vector2i(5, 0))
	await _await_turn_end()
	var after_hit: int = battle.team.hp
	_check(after_hit == team_hp - all_atk, "4a enemies hit back: %d -> %d (want -%d)" % [team_hp, after_hit, all_atk])
	ok = false
	for attempt in 20:
		battle._start_battle(i, Mode.NEW_ACT)
		await _frames(2)
		battle.team.hp = after_hit
		_set_board(HEART3)
		seed(4000 + attempt)
		await _tap(Vector2i(5, 0))
		await _await_turn_end()
		if last_combos == 1:
			ok = true
			break
	_check(ok and battle.team.hp == mini(after_hit + team_rcv, team_hp) - all_atk, "4b 3 Hearts heal +%d (team RCV), never above max -> %d" % [team_rcv, battle.team.hp])
	var turns := await _win_fight(i, team_m)
	var clear_title := "ACT %d CLEAR!" % act.act_number
	_check(battle.result_panel.visible and battle.result_panel._title.text in ["WIN!", clear_title] and battle.result_panel._info.text.contains("+%d XP" % fight.xp),
		"4c WIN after %d turns (4 orbs of the best colour + 3 Hearts each turn); win screen says \"%s\"" % [turns, battle.result_panel._info.text])
	if i == act.fights.size() - 1:
		_check(battle.result_panel._title.text == clear_title, "the last fight shows \"%s\"" % clear_title)
	var lose_turns := await _play_until_result(i, BASE)
	_check(battle.result_panel._title.text == "LOSE" and lose_turns == ceili(float(team_hp) / all_atk), "4d LOSE after %d turns of no damage (%d HP / %d per turn)" % [lose_turns, team_hp, all_atk])

	# 5) Fight Again / Next Fight
	var won_turns := await _win_fight(i, team_m)
	var shown: String = battle.result_panel._title.text if battle.result_panel.visible else "(no result screen)"
	await _click(battle.result_panel._retry_button)
	_check(battle.fight_index == i and battle.enemies[0].hp == front.max_hp and battle.team.hp == team_hp,
		"5a Fight Again: same fight, everyone back to full HP (before: \"%s\" after %d turns; now fight %d, enemy %d/%d, team %d/%d)" % [shown, won_turns, battle.fight_index + 1, battle.enemies[0].hp, front.max_hp, battle.team.hp, team_hp])
	await _win_fight(i, team_m, false)
	await _click(battle.result_panel._next_button)
	var next_i: int = (i + 1) % act.fights.size()
	_check(battle.fight_index == next_i, "5b %s -> fight %d" % [battle.result_panel._next_button.text, next_i + 1])


## Win fight i: each turn match 4 orbs of the best colour against the front
## enemy AND 3 Hearts (a simple but sensible player).
func _win_fight(i: int, team_m: Array[FighterData], restart := true) -> int:
	if restart:
		battle._start_battle(i, battle.StartMode.NEW_ACT)
		await _frames(2)
	var turns := 0
	while not battle.result_panel.visible and turns < 30:
		var t := CombatRules.pick_target(battle.enemies, -1)
		var ranked: Array = BalanceSim.ranked(team_m, battle.enemies[t].data.element)
		var best: FighterData = ranked[0]
		var rows: Array = _rows_for(best.element, 4).duplicate()
		rows[3] = "HHHFWG"   # plus 3 Hearts in row 4
		# Mini-bosses and bosses (armoured) need GOOD play since the Stage 1 rework:
		# add a 3-match of the second-best colour (like BalanceSim "GOOD").
		var armoured: bool = battle.enemies.any(func(e: Enemy) -> bool: return e.data.armored and e.hp > 0)
		if armoured:
			var second: int = ranked[1].element if ranked.size() > 1 else best.element
			var c: String = {Element.Type.FIRE: "F", Element.Type.WATER: "W", Element.Type.WOOD: "G", Element.Type.LIGHT: "L"}.get(second, "D")
			# Rows 0 and 2 are "FWGLDH": put the group where it can't join them vertically.
			rows[1] = (c + c + c + "FWG") if c in ["L", "D"] else ("LDH" + c + c + c)
		_set_board(rows)
		await _tap(Vector2i(5, 0))
		await _await_turn_end()
		turns += 1
	await get_tree().create_timer(0.4).timeout
	return turns


func _rows_for(element: int, n: int) -> Array:
	match element:
		Element.Type.FIRE:
			return FIRE3 if n == 3 else FIRE4
		Element.Type.WATER:
			return WATER3 if n == 3 else WATER4
		Element.Type.WOOD:
			return WOOD3 if n == 3 else WOOD4
		Element.Type.LIGHT:
			return LIGHT3 if n == 3 else LIGHT4
	return DARK3 if n == 3 else DARK4


func _unlocked(d: FighterData, n: int) -> FighterData:
	var c: FighterData = d.duplicate()
	c.passives_unlocked = n
	return c


## Play one turn on `rows` (fresh fight each attempt), retrying until the turn
## made exactly `want_combos` combos. Optional: tap enemy `target` first,
## set team HP to `team_hp` first. restart=false keeps the current fight.
func _turn_with(rows: Array, want_combos: int, fight := 0, team_hp := -1, restart := true) -> bool:
	for attempt in 30:
		var enemy_hp := []
		if restart:
			battle._start_battle(maxi(fight, 0), battle.StartMode.NEW_ACT)
			await _frames(2)
		else:
			enemy_hp = _enemy_hps()
		var team_hp_before: int = battle.team.hp
		var attacked: Array = battle.team.has_attacked.duplicate()
		if team_hp >= 0:
			battle.team.hp = team_hp
			battle.team_bar.set_values(team_hp, battle.team.max_hp, false)
		_set_board(rows)
		texts.clear()
		seed(2000 + attempt)
		await _tap(Vector2i(5, 0))
		await _await_turn_end()
		if last_combos == want_combos:
			return true
		if not restart:
			# Undo the unlucky turn and try again from the same state.
			for i in battle.enemies.size():
				battle.enemies[i].hp = enemy_hp[i]
			battle.team.hp = team_hp_before
			battle.team.has_attacked = attacked
	return false


func _ready_skill(i: int) -> void:
	battle.team.skill_turns[i] = 0
	battle._refresh_team_ui()


## Tap card i, check the pop-up, press USE, wait for the skill to finish.
func _use_skill_by_tapping(i: int) -> void:
	await _click_card(i)
	if not battle.skill_popup.visible:
		_check(false, "skill pop-up did not open for card %d" % i)
		return
	await _click(battle.skill_popup.use_button)
	var t := 0.0
	while battle._busy and t < 5.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	await _frames(2)


func _click_card(i: int) -> void:
	var view: FighterView = battle.team_views[i]
	var p := view.get_global_transform_with_canvas() * view.hit_rect().get_center()
	_press(p)
	await _frames(1)
	_release(p)
	await _frames(2)


## A one-enemy test fight with a big dummy (to prove skill maths exactly).
func _dummy_fight(hp: int, boss: bool, armored: bool) -> FightData:
	var d := FighterData.new()
	d.display_name = "TEST DUMMY"
	d.element = Element.Type.WOOD
	d.role = FighterData.Role.ENEMY
	d.max_hp = hp
	d.atk = 10
	d.is_boss = boss
	d.armored = armored
	d.body_color = Color(0.4, 0.4, 0.45)
	d.figure_height = 300.0
	d.figure_width = 280.0
	var f := FightData.new()
	f.display_name = "TEST DUMMY FIGHT"
	f.enemies.append(d)
	return f


# ---------------------------------------------------------------- helpers

func _story_team() -> void:
	battle.set_team([BERSERKER, BIOTECH, TITAN])


func _typed(list: Array) -> Array[FighterData]:
	var out: Array[FighterData] = []
	for d in list:
		out.append(d)
	return out


func _enemy_hps() -> Array:
	var out := []
	for e in battle.enemies:
		out.append(e.hp)
	return out


## Play one turn of fight `fight` on `rows`, retrying with a new random seed
## until the turn was exactly 1 combo (new orbs dropping in can chain by luck).
func _single_combo_turn(rows: Array, fight: int) -> bool:
	for attempt in 30:
		battle._start_battle(fight)
		await _frames(2)
		_set_board(rows)
		texts.clear()
		seed(1000 + attempt)
		await _tap(Vector2i(5, 0))
		await _await_turn_end()
		if last_combos == 1:
			return true
	return false


## Start fight `fight` (if `restart`) and keep playing `rows` until WIN or LOSE.
func _play_until_result(fight: int, rows: Array, restart := true) -> int:
	if restart:
		battle._start_battle(fight)
		await _frames(2)
	var turns := 0
	while not battle.result_panel.visible and turns < 40:
		_set_board(rows)
		await _tap(Vector2i(5, 0))
		await _await_turn_end()
		turns += 1
	await get_tree().create_timer(0.4).timeout
	return turns


func _await_turn_end() -> void:
	var t := 0.0
	await _frames(1)
	while t < 30.0:
		if battle.board.state == Board.State.READY or battle.result_panel.visible:
			return
		await get_tree().process_frame
		t += get_process_delta_time()
	_check(false, "turn did not finish within 30 s")


func _set_board(rows: Array) -> void:
	var map := {"F": Element.Type.FIRE, "W": Element.Type.WATER, "G": Element.Type.WOOD,
		"L": Element.Type.LIGHT, "D": Element.Type.DARK, "H": Element.Type.HEART}
	for y in Board.ROWS:
		for x in Board.COLS:
			var orb: Orb = battle.board.grid[x][y]
			orb.setup(map[rows[y][x]])


func _cell_pos(c: Vector2i) -> Vector2:
	return battle.board.get_global_transform_with_canvas() * battle.board.cell_center(c)


func _board_pos(cells: Vector2) -> Vector2:
	return battle.board.get_global_transform_with_canvas() * (cells * Board.CELL)


## Real tap on enemy i (in the middle of its body).
func _click_enemy(i: int) -> void:
	var view: FighterView = battle.enemy_views[i]
	var p := view.get_global_transform_with_canvas() * Vector2(0, -view.data.figure_height * 0.5)
	_press(p)
	await _frames(1)
	_release(p)
	await _frames(2)


func _drag_path(points: Array) -> void:
	for p in points:
		_move(_board_pos(p))
		await _frames(1)


func _tap(c: Vector2i) -> void:
	var p := _cell_pos(c)
	_press(p)
	await _frames(1)
	_release(p)
	await _frames(1)


func _click(button: Button) -> void:
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


func _move(p: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	e.position = p
	e.global_position = p
	get_viewport().push_input(e, true)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _on_turn_finished(combos: int, cleared: Dictionary, groups: Array) -> void:
	last_combos = combos
	last_cleared = cleared
	last_groups = groups


func _on_world_child(node: Node) -> void:
	if node is FloatingText:
		texts.append([node.text, node.label_settings.font_size])


func _find_text(text: String) -> Array:
	for e in texts:
		if e[0] == text:
			return e
	return []


## Save a screenshot. Never blocks the test: if the window isn't drawing
## (hidden or minimised), it gives up after a few frames and moves on.
func _shot(shot_name: String) -> void:
	if not screenshots:
		return
	await _frames(2)
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		_log("NOTE  screenshot %s skipped (window not drawing)" % shot_name)
		return
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
	var suffix := "_layout" if "--layout-only" in OS.get_cmdline_user_args() else ""
	var f := FileAccess.open(ProjectSettings.globalize_path("res://tests/report%s.txt" % suffix), FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	get_tree().quit(fails)
