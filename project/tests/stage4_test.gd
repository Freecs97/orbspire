extends Node
## Stage 4 test: combo display, animation timing, enemy size, head-only plates.
##   4A - the live combo counter on every tick (Combo 1, 3, 5 screenshots), damage
##        and heal numbers carry the multiplier and match the formula
##   4B - FX sheets (used if present) + time per attack / skill / turn
##   4C - enemies x1.20 (x1.15 where they'd overlap) in all 80 fights; head-only plates
## Run:  Godot_v4.7.2-stable_win64_console.exe --path . res://tests/stage4_test.tscn
## Results: tests/report_stage4.txt, screenshots tests/screenshots/s4_*.png

const BattleScene := preload("res://scenes/battle.tscn")
const T := Element.Type
const BASE := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "FWGLDH"]
const FIRE3 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "FFFLDH"]
const THREE_ELEMENTS := ["FWGLDH", "LDHFWG", "GGGLDH", "LDHFWG", "FFFWWW"]
const FIVE_COMBOS := ["FFFWWW", "LDHLDH", "GGGLLL", "DHFWGH", "DDDHFW"]
const HEART_FIRE := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "HHHFFF"]

var battle: Node2D
var lines := PackedStringArray()
var fails := 0
var screenshots := true
var texts: Array = []
var ticks: Array = []
var shot_ticks := {}
var last_combos := 0
var last_cleared := {}
var last_groups: Array = []
var counter_at_enemy_hit := []
var _hp_seen := -1


func _ready() -> void:
	GameSettings.path = "user://test_settings.json"   # never touch the player's settings
	GameSettings.skill_cut_ins = false   # cut-ins are tested in friends_test; keep these timings as they were
	Profile.friend_drops = false   # no random 1-in-400 friend joining this test's teams
	screenshots = DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/screenshots"))
	battle = BattleScene.instantiate()
	add_child(battle)
	await _frames(3)
	if not "combo_counter" in battle:
		_check(false, "battle script failed to load")
		_finish()
		return
	battle.world.child_entered_tree.connect(func(n: Node) -> void:
		if n is FloatingText:
			texts.append(n.text))
	battle.board.combo_made.connect(_on_tick)
	battle.board.turn_finished.connect(func(c: int, cl: Dictionary, g: Array) -> void:
		last_combos = c
		last_cleared = cl
		last_groups = g)
	_log("Godot %s · Stage 4 test" % Engine.get_version_info().string)
	if screenshots:
		# Keep the test window drawing (a hidden / minimised window stops rendering,
		# and then every screenshot is the same stale frame).
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	await _test_combo()
	await _test_enemy_size()
	await _test_head_plates()
	await _test_timing()
	_finish()


func _process(_delta: float) -> void:
	if battle and battle.team:
		if _hp_seen >= 0 and battle.team.hp < _hp_seen:
			counter_at_enemy_hit.append(battle.combo_counter.visible and battle.combo_counter.modulate.a > 0.05)
		_hp_seen = battle.team.hp


func _on_tick(count: int, _type: int, _pos: Vector2) -> void:
	ticks.append(battle.combo_counter.text)
	if shot_ticks.has(count) and not shot_ticks[count]:
		shot_ticks[count] = true
		_snap("s4_combo_%d" % count)


func _snap(shot_name: String) -> void:
	await _frames(2)
	await _shot(shot_name)


# ---------------------------------------------------------------- 4A

func _test_combo() -> void:
	_log("\n== 4A: combo multiplier on every tick ==")
	var team := [Catalog.template("berserker_01_angel_fire"), Catalog.template("biotech_01_medic_water"), Catalog.template("titan_01_shield_wood")]
	for want in [1, 3, 5]:
		var rows: Array = {1: FIRE3, 3: THREE_ELEMENTS, 5: FIVE_COMBOS}[want]
		var ok := false
		for attempt in 25:
			battle.set_team(team)
			battle.test_fight_override = _dummy(99999, 10)
			battle._start_battle(0, battle.StartMode.NEW_ACT)
			await _frames(3)
			_set_board(rows)
			ticks.clear()
			texts.clear()
			counter_at_enemy_hit.clear()
			shot_ticks = {want: false} if attempt < 24 else {}
			seed(3000 + attempt * 7 + want)
			await _tap(Vector2i(5, 0))
			await _await_turn_end()
			if last_combos == want:
				ok = true
				break
		if not ok:
			_check(false, "could not get exactly %d combos" % want)
			continue
		var want_ticks := []
		for k in range(1, want + 1):
			want_ticks.append("COMBO %d   x%.2f" % [k, DamageCalculator.combo_multiplier(k)])
		_check(ticks == want_ticks, "%d-combo turn: the counter updated on EVERY tick: %s" % [want, ticks])
		# Damage numbers = ATK x (orbs/3) x combo x element x leader x passives, each with its multiplier.
		var expected := []
		var tm: Team = battle.team
		var dummy := Enemy.new(battle.test_fight_override.enemies[0])
		for m in tm.members:
			var orbs: int = last_cleared.get(m.element, 0)
			if orbs <= 0:
				continue
			var bonus := CombatRules.leader_multiplier(tm.leader(), m, last_groups, last_combos, dummy, tm) * CombatRules.passive_multiplier(m, last_groups, last_combos, dummy, false, tm)
			expected.append(str(DamageCalculator.attack_damage(m.atk, orbs, last_combos, m.element, T.NONE, bonus)))
		var shown := texts.filter(func(s: String) -> bool: return s.is_valid_int() and not s.begins_with("+") and not s.begins_with("-"))
		var mult_tag := "x%.2f" % DamageCalculator.combo_multiplier(want)
		var tags := texts.filter(func(s: String) -> bool: return s == mult_tag).size()
		expected.sort()
		shown.sort()
		_check(shown == expected and tags >= expected.size(), "  damage numbers %s match ATK x orbs/3 x combo x element x leader (want %s), each tagged %s" % [shown, expected, mult_tag])
		_check(not counter_at_enemy_hit.has(true) and not battle.combo_counter.visible, "  the counter is gone before the enemy hits (never carries over to the enemy turn)")
	# Reset on the next drag.
	battle.combo_counter.tick(4)
	_set_board(BASE)
	var p := _cell_pos(Vector2i(0, 0))
	_press(p)
	await _frames(2)
	var reset_ok: bool = not battle.combo_counter.visible and battle.combo_counter.count == 0
	_release(p)
	await _await_turn_end()
	_check(reset_ok, "picking up an orb resets the counter to 0 (hidden)")
	# Healing: Hearts x RCV x combo, with the multiplier shown.
	for attempt in 25:
		battle._start_battle(0, battle.StartMode.NEW_ACT)
		await _frames(3)
		battle.team.hp = 200
		_set_board(HEART_FIRE)
		texts.clear()
		seed(5000 + attempt)
		await _tap(Vector2i(5, 0))
		await _await_turn_end()
		if last_combos == 2:
			break
	var heal := roundi(battle.team.total_rcv * (last_cleared.get(T.HEART, 0) / 3.0) * DamageCalculator.combo_multiplier(last_combos))
	_check(last_combos == 2 and texts.has("+%d" % heal) and texts.has("x1.25"), "heal with 2 combos: +%d = RCV %d x hearts/3 x1.25 (shown with \"x1.25\")" % [heal, battle.team.total_rcv])


# ---------------------------------------------------------------- 4B

func _test_timing() -> void:
	_log("\n== 4B: FX + timing ==")
	var have := []
	for k in SkillFx.SHEET_FOR_ELEMENT.values() + [SkillFx.HEAL_SHEET]:
		if SkillFx.has_sheet(k):
			have.append(k)
	_log("INFO  FX sprite sheets found in assets/fx/: %s" % ("none yet: skills use the Godot code effects (beams, rings, slashes, domes, sparkles)" if have.is_empty() else ", ".join(have)))
	# Time per skill (tap USE -> skill finished).
	var worst := 0.0
	var parts := PackedStringArray()
	for id in ["spectre_01_rogue_dark", "enemy_shade", "berserker_04_void_dark", "biotech_01_medic_water", "titan_02_guardian_fire", "enemy_ember_drone"]:
		var h: FighterData = Catalog.template(id).duplicate()
		battle.set_team([h])
		battle.test_fight_override = _dummy(99999, 10, 2 if id == "berserker_04_void_dark" or id == "enemy_ember_drone" else 1)
		battle._start_battle(0, battle.StartMode.NEW_ACT)
		await _frames(3)
		battle.team.skill_turns[0] = 0
		var t0 := Time.get_ticks_msec()
		battle.use_skill(0)
		await _frames(1)
		while battle._busy:
			await get_tree().process_frame
		var dt := (Time.get_ticks_msec() - t0) / 1000.0
		worst = maxf(worst, dt)
		parts.append("%s %.2f s" % [Skills.display_name(h.active_skill), dt])
	_check(worst < 1.0, "every skill animation finishes in under 1.0 s: %s" % ", ".join(parts))
	# A normal 3-combo turn: attack + hit time per hunter, and the whole turn.
	battle.set_team([Catalog.template("berserker_01_angel_fire"), Catalog.template("biotech_01_medic_water"), Catalog.template("titan_01_shield_wood")])
	var turn_times := []
	for attempt in 6:
		battle.test_fight_override = _dummy(99999, 10)
		battle._start_battle(0, battle.StartMode.NEW_ACT)
		await _frames(3)
		_set_board(THREE_ELEMENTS)
		seed(7000 + attempt)
		var t0 := Time.get_ticks_msec()
		await _tap(Vector2i(5, 0))
		await _await_turn_end()
		turn_times.append((Time.get_ticks_msec() - t0) / 1000.0)
	var avg: float = turn_times.reduce(func(a, b): return a + b) / turn_times.size()
	_check(0.2 + 0.28 < 0.6, "attack + hit per hunter: lunge 0.20 s + hit 0.28 s = 0.48 s (limit 0.6 s)")
	_log("INFO  a normal 3-combo turn (orbs clearing + 3 hunters attack + 1 enemy hits back) takes %.1f s on average (%s)" % [avg, turn_times])
	_log("INFO  so a 16-turn Act 1 is about %.0f s of turns, plus your own drag time" % (avg * 16))


# ---------------------------------------------------------------- 4C

func _test_enemy_size() -> void:
	_log("\n== 4C: enemies x1.20 (x1.15 where they'd overlap) ==")
	var tight := PackedStringArray()
	var overlap_left := PackedStringArray()
	var fights := 0
	var top_min := 9999.0
	var top_name := ""
	for act in StarMap.ACTS:
		for i in act.fights.size():
			var f: FightData = act.fights[i]
			fights += 1
			var list := []
			for d in f.enemies:
				list.append(Enemy.new(d))
			var s: float = battle.fit_enemy_scale(list)
			if s < 1.2:
				tight.append("Act %d fight %d" % [act.act_number, i + 1])
			var xs: Array = battle.ENEMY_X[clampi(list.size(), 1, 3)]
			for k in list.size() - 1:
				if (battle.enemy_extent(f.enemies[k])[1] + battle.enemy_extent(f.enemies[k + 1])[0]) * s > xs[k + 1] - xs[k]:
					overlap_left.append("Act %d fight %d" % [act.act_number, i + 1])
			for d in f.enemies:
				if d.art:
					var r := ArtBounds.opaque_rect(d.art)
					var k := d.figure_height / float(d.art.get_height())
					var top: float = battle.ENEMY_FEET_Y - (d.figure_height - r.position.y * k) * s
					if top < top_min:
						top_min = top
						top_name = "%s (Act %d)" % [d.display_name, act.act_number]
	_check(overlap_left.is_empty(), "%d fights checked: no two enemies overlap (%s)" % [fights, "x1.20 everywhere" if tight.is_empty() else "x1.15 in: " + ", ".join(tight)])
	_log("INFO  fights drawn at x1.15 instead of x1.20 (would overlap at x1.20): %s" % (", ".join(tight) if not tight.is_empty() else "none"))
	var label_bottom: float = battle.enemy_attack_label.position.y + battle.enemy_attack_label.size.y * 0.8
	_check(top_min >= label_bottom - 4.0, "the tallest enemy's art starts at y %.0f (%s), under the fight title's last line (ends y %.0f); the board is far below" % [top_min, top_name, label_bottom])
	var bar_bottom: float = battle.ENEMY_FEET_Y + 26 + 30
	var plate_top: float = battle.TEAM_FEET_Y - FighterView.DEFAULT_CARD.y + 22 - 16
	_check(bar_bottom < plate_top, "enemy HP bars (end y %.0f) stay above the party plates (start y %.0f)" % [bar_bottom, plate_top])
	var act1: ActData = StarMap.ACTS[0]
	battle.set_team([Catalog.template("berserker_01_angel_fire"), Catalog.template("biotech_01_medic_water"), Catalog.template("titan_01_shield_wood")])
	battle.test_fight_override = null
	battle.act_fights = act1.fights
	for sc in [1.0, 0.0]:
		battle.enemy_scale_override = sc
		battle._start_battle(7, battle.StartMode.NEW_ACT)
		await _frames(3)
		if battle.story_beat.is_open():
			battle.story_beat.close()
		await get_tree().create_timer(0.5).timeout
		await _shot("s4_enemy_%s" % ("old_size" if sc == 1.0 else "new_size"))
	_check(is_equal_approx(battle.enemy_scale, 1.2) and is_equal_approx(battle.enemy_views[0].scale.x, 1.2), "Emberfang-9 is drawn at x1.20 (stats unchanged: %d HP / %d ATK)" % [battle.enemies[0].data.max_hp, battle.enemies[0].data.atk])
	battle.enemy_scale_override = 0.0
	battle._start_battle(5, battle.StartMode.NEW_ACT)
	await _frames(3)
	var v: FighterView = battle.enemy_views[1]
	var p: Vector2 = v.get_global_transform_with_canvas() * Vector2(0, -v.data.figure_height * 0.5)
	_press(p)
	await _frames(1)
	_release(p)
	await _frames(2)
	_check(battle.target_index == 1, "tapping a bigger enemy still targets it")
	await _shot("s4_two_enemies")


func _test_head_plates() -> void:
	_log("\n== 4C: head-only party plates ==")
	battle.test_fight_override = _dummy(99999, 10)
	battle.set_team([Catalog.template("berserker_01_angel_fire"), Catalog.template("spectre_01_rogue_dark"), Catalog.template("biotech_01_medic_water"), Catalog.template("titan_01_shield_wood")])
	battle._start_battle(0, battle.StartMode.NEW_ACT)
	await _frames(4)
	var heads := true
	for v in battle.team_views:
		var f = v.figure
		heads = heads and f is ArtFigure and f.head_size > 0.0 and f.sprite.texture is AtlasTexture
	_check(heads, "all 4 party members are HEAD-ONLY plates (face cropped from their own art)")
	battle.team.hp = int(battle.team.max_hp * 0.4)
	await _frames(3)
	var v0: FighterView = battle.team_views[0]
	_check(is_equal_approx(v0.hp_ratio, battle.team.hp_ratio()) and v0.skill_turns >= 0 and v0.is_leader and not battle.team_views[1].is_leader,
		"each plate shows the HP bar (the team's shared HP: %.0f%%), the skill charge, and LEADER on slot 1" % (v0.hp_ratio * 100))
	await _shot("s4_head_plates")
	var c := v0.get_global_transform_with_canvas() * v0.hit_rect().get_center()
	_press(c)
	await _frames(1)
	_release(c)
	await _frames(3)
	var pop: SkillPopup = battle.skill_popup
	var body := ""
	for ch in pop._body.get_children():
		body += (ch as Label).text + " | "
	_check(pop.visible and pop._title.text.contains("KAELA") and body.contains("HP") and body.contains("ATK") and body.contains("RCV") and body.contains("OVERRUN") and not body.contains("PASSIVE"),
		"tapping a plate: small tooltip with name, HP / ATK / RCV and the skill name (no Replace yet): \"%s\"" % body.strip_edges())
	await _shot("s4_tooltip")
	pop.visible = false
	await _frames(2)
	# Every character's head crop, for review.
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("0b0b14")
	bg.size = Vector2(1080, 1920)
	layer.add_child(bg)
	var ids := Catalog.IDS + Catalog.ENEMY_IDS + Catalog.RECOLOR_IDS
	for i in ids.size():
		var tex := Catalog.art(ids[i])
		var crop := AtlasTexture.new()
		crop.atlas = tex
		crop.region = ArtBounds.head_region(tex)
		var tr := TextureRect.new()
		tr.texture = crop
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.position = Vector2(20 + (i % 6) * 175, 30 + (i / 6) * 260)
		tr.size = Vector2(160, 160)
		layer.add_child(tr)
		var l := Label.new()
		l.text = Catalog.display_name(ids[i])
		l.add_theme_font_size_override("font_size", 18)
		l.position = tr.position + Vector2(0, 165)
		l.size = Vector2(160, 30)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layer.add_child(l)
	await _frames(4)
	await _shot("s4_head_crops_all")
	layer.queue_free()


# ---------------------------------------------------------------- helpers

func _dummy(hp: int, atk: int, count := 1) -> FightData:
	var f := FightData.new()
	f.display_name = "STAGE 4 TEST"
	for k in count:
		var d := FighterData.new()
		d.display_name = "TEST DUMMY"
		d.element = T.NONE
		d.role = FighterData.Role.ENEMY
		d.max_hp = hp
		d.atk = atk
		d.body_color = Color(0.4, 0.4, 0.45)
		d.figure_height = 280.0
		d.figure_width = 240.0
		f.enemies.append(d)
	return f


func _set_board(rows: Array) -> void:
	var map := {"F": T.FIRE, "W": T.WATER, "G": T.WOOD, "L": T.LIGHT, "D": T.DARK, "H": T.HEART}
	for y in Board.ROWS:
		for x in Board.COLS:
			(battle.board.grid[x][y] as Orb).setup(map[rows[y][x]])


func _cell_pos(c: Vector2i) -> Vector2:
	return battle.board.get_global_transform_with_canvas() * battle.board.cell_center(c)


func _tap(c: Vector2i) -> void:
	var p := _cell_pos(c)
	_press(p)
	await _frames(1)
	_release(p)
	await _frames(1)


func _await_turn_end() -> void:
	var t := 0.0
	await _frames(1)
	while t < 30.0:
		if battle.board.state == Board.State.READY or battle.result_panel.visible:
			return
		await get_tree().process_frame
		t += get_process_delta_time()
	_check(false, "turn did not finish within 30 s")


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


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	if not screenshots:
		return
	await _frames(1)
	if not DisplayServer.window_can_draw():
		# The window isn't drawing (screen off / locked / minimised): render a frame anyway.
		RenderingServer.force_draw(false)
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		return
	img.save_png(ProjectSettings.globalize_path("res://tests/screenshots/%s.png" % shot_name))
	_log("INFO  screenshot %s (window drawing: %s)" % [shot_name, DisplayServer.window_can_draw()])


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	_log(("PASS  " if ok else "FAIL  ") + what)


func _log(text: String) -> void:
	print(text)
	lines.append(text)


func _finish() -> void:
	_log("\n%s — %d failure(s)" % ["ALL PASSED" if fails == 0 else "SOME FAILED", fails])
	var f := FileAccess.open(ProjectSettings.globalize_path("res://tests/report_stage4.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	get_tree().quit(fails)
