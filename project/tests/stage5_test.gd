extends Node
## Stage 5 test: Replace + the full character detail screen (real main scene, own save).
##   5A-T  Team screen: tap a party member -> REPLACE / DETAILS / CLOSE; Replace = pick
##         from the Roster (sorts, IN SLOT tags), the old one goes back to the Roster
##   5B    Kaela Rynn's detail screen: full art, stats, XP, rarity stars, evolution
##         1/3-3/3, next evolution, every skill in full words, Essence, Lock / Retire
##   5A-B  In battle: tap a plate -> USE / DETAILS / CLOSE (Replace is Team-screen only
##         since the Universe update); DETAILS is read-only
## Run:  Godot_v4.7.2-stable_win64_console.exe --path . res://tests/stage5_test.tscn
## Results: tests/report_stage5.txt, screenshots tests/screenshots/s6_*.png

const MainScene := preload("res://scenes/main.tscn")
const BattleScene := preload("res://scenes/battle.tscn")
const SAVE := "user://stage5_test_save.json"
const T := Element.Type
const FIRE3 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "FFFLDH"]

var main: Node
var p: Profile
var lines := PackedStringArray()
var fails := 0
var kaela := -1
var mira := -1
var bram := -1
var drek := -1
var iris := -1
var kaela2 := -1


func _ready() -> void:
	GameSettings.path = "user://test_settings.json"
	GameSettings.skill_cut_ins = false
	Profile.friend_drops = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/screenshots"))
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	main = MainScene.instantiate()
	main.save_path = SAVE
	add_child(main)
	await _frames(3)
	if not "profile" in main or main.profile == null:
		_check(false, "main scene failed to load")
		_finish()
		return
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	p = main.profile
	main.save["intro_seen"] = true
	_log("Godot %s · Stage 5: Replace + character detail" % Engine.get_version_info().string)
	_make_roster()
	await _test_team_menu_and_replace()
	await _test_kaela_detail()
	await _test_retire_and_stage3()
	await _test_battle()
	await _test_battle_without_save()
	_finish()


func _make_roster() -> void:
	kaela = p.choose_starter("berserker_01_angel_fire")
	p.add_xp(p.unit(kaela), Profile.PROGRESSION.total_xp_for(12) + 120)
	p.unit(kaela)["cores"] = 2
	mira = p.add_unit("biotech_01_medic_water", 2, 10)
	bram = p.add_unit("titan_01_shield_wood", 1, 9)
	drek = p.add_unit("berserker_02_hulk_wood", 0, 11)
	iris = p.add_unit("berserker_03_thin_water", 3, 8)
	kaela2 = p.add_unit("berserker_01_angel_fire", 0, 3)
	p.add_unit("friend_jake", 3, 5)
	p.data["team"] = [kaela, mira, bram]
	p.data["credits"] = 640
	p.data["cores"] = 3
	p.data["essence"]["berserker_01_angel_fire"] = 3
	main._write()
	_log("INFO  roster: Kaela Lv%d (team slot 1), Mira, Bram in the team; Drek, Iris, a 2nd Kaela, Jake in the Roster" % p.unit(kaela)["level"])


# ================================================================ 5A: Team screen

func _test_team_menu_and_replace() -> void:
	_log("\n== 5A: Team screen: tap a party member ==")
	main.show_page("TEAM")
	await _frames(3)
	var ts: TeamScreen = main.team_screen
	await _click(ts.slot_cards[0])
	_check(ts.menu.visible and ts.menu.title.text == "KAELA RYNN" and ts.menu.replace_button.text == "REPLACE" and ts.menu.details_button.text == "DETAILS" and ts.menu.close_button.text == "CLOSE",
		"tapping Kaela (slot 1) opens a menu: REPLACE / DETAILS / CLOSE")
	await _shot("s6_team_menu")
	await _click(ts.menu.replace_button)
	var pk: RosterPicker = ts.picker
	var ids := pk.cards().map(func(c: UnitCard) -> int: return c.uid)
	var mira_card: UnitCard = _card(pk, mira)
	_check(pk.visible and pk.title_label.text == "REPLACE KAELA RYNN" and not kaela in ids and ids.size() == p.data["units"].size() - 1
		and mira_card != null and mira_card._tag.visible and mira_card._tag.text.contains("IN SLOT 2"),
		"REPLACE opens the Roster: everyone you own except Kaela (%d), team members tagged \"IN SLOT n\"" % ids.size())
	await _shot("s6_replace_picker")
	var by_level := _card_levels(pk)
	await _click(pk.sort_buttons["RARITY"])
	var rar := pk.cards().map(func(c: UnitCard) -> int: return int(p.unit(c.uid)["rarity"]))
	await _click(pk.sort_buttons["ELEMENT"])
	var els := pk.cards().map(func(c: UnitCard) -> int: return RosterPicker.ELEMENT_ORDER.find(Catalog.template(p.unit(c.uid)["id"]).element))
	_check(_sorted_desc(by_level) and _sorted_desc(rar) and _sorted_asc(els), "sort by LEVEL %s, RARITY %s, ELEMENT %s" % [by_level, rar, els])
	await _click(pk.sort_buttons["LEVEL"])
	await _click(_card(pk, drek))
	_check(p.data["team"][0] == drek and not p.unit(kaela).is_empty() and not kaela in p.data["team"] and not pk.visible and ts.toast.text.contains("went back to your Roster"),
		"picked Drek Vane: he leads slot 1; Kaela is NOT deleted, she's back in the Roster (\"%s\")" % ts.toast.text)
	await _frames(2)
	await _shot("s6_team_after_replace")
	# Swap: put Kaela back in slot 1, then a team member into another slot swaps them.
	await _click(ts.slot_cards[0])
	await _click(ts.menu.replace_button)
	await _click(_card(pk, kaela))
	_check(p.data["team"][0] == kaela and not drek in p.data["team"], "Replace again: Kaela back in slot 1, Drek back in the Roster")
	await _click(ts.slot_cards[2])
	await _click(ts.menu.replace_button)
	await _click(_card(pk, mira))
	_check(p.data["team"][2] == mira and p.data["team"][1] == bram and ts.toast.text.contains("moved to slot 2"), "picking someone already in the team swaps the two slots (\"%s\")" % ts.toast.text)
	await _click(ts.slot_cards[1])
	await _click(ts.menu.replace_button)
	await _click(_card(pk, mira))
	_check(p.data["team"] == [kaela, mira, bram], "swapped back: Kaela, Mira, Bram")
	await _click(ts.slot_cards[3])
	_check(pk.visible and not ts.menu.visible and pk.title_label.text == "CHOOSE A HUNTER", "an EMPTY slot (4) goes straight to the Roster picker")
	await _click(pk.close_button)
	_check(not pk.visible and p.data["team"].size() == 3, "CLOSE picks nobody")
	await _click(ts.slot_cards[0])
	await _click(ts.menu.details_button)
	_check(ts.detail.visible and ts.detail.name_label.text == "KAELA RYNN", "DETAILS opens Kaela's full detail screen")


# ================================================================ 5B: Kaela Rynn's detail screen

func _test_kaela_detail() -> void:
	_log("\n== 5B: Kaela Rynn's detail screen ==")
	var ts: TeamScreen = main.team_screen
	var d: UnitDetail = ts.detail
	var u := p.unit(kaela)
	var f := p.fighter(kaela)
	_check(d.art_rect.texture == Catalog.art("berserker_01_angel_fire", 1) and not d.art_rect.texture is AtlasTexture and d.art_rect.size.x >= 600,
		"the FULL art, large and centred (%d px, not the head crop)" % d.art_rect.size.x)
	_check(d.stars.filled == 3 and d.rarity_label.text.contains("3 / 6") and d.rarity_label.text.contains("FORGED"), "rarity: 3 of 6 stars, \"%s\"" % d.rarity_label.text)
	_check(d.stats_label.text == "HP %d     ATK %d     RCV %d" % [f.max_hp, f.atk, f.rcv] and d.level_label.text.contains("LEVEL 12") and d.level_label.text.contains("AFFINITY  Fire")
		and d.level_label.text.contains("ARCHETYPE  Berserker") and d.level_label.text.contains("RARITY  Forged"),
		"stats: %s, %s" % [d.stats_label.text, d.level_label.text.replace("\n", " / ")])
	var need := Profile.PROGRESSION.xp_to_next(12)
	_check(d.xp_label.text == "XP %d / %d  ·  %d to Lv13" % [u["xp"], need, need - int(u["xp"])] and d.xp_fill.size.x > 0.0, "XP to the next level: \"%s\" (bar filled)" % d.xp_label.text)
	var now_ok: bool = (d.evo_boxes[0].get_node("Text") as Label).text.contains("NOW") and not (d.evo_boxes[1].get_node("Text") as Label).text.contains("NOW")
	_check(d.evo_label.text == "EVOLUTION: Stage 1/3" and now_ok and (d.evo_boxes[1].get_node("Pic") as TextureRect).texture == Catalog.art("berserker_01_angel_fire", 2),
		"evolution 1/3 - 2/3 - 3/3 with her Stage 2 / 3 art; Stage 1 highlighted (NOW)")
	var p2 := Skills.display_name(f.passives[1])
	_check(d.evo_next_label.text.contains("needs Lv15 (now Lv12)") and d.evo_next_label.text.contains("1000 Credits (you have 640)") and d.evo_next_label.text.contains("5 Training Cores (you have 3)")
		and d.evo_next_label.text.contains("+10% HP / ATK / RCV") and d.evo_next_label.text.contains("(7 -> 6 turns)") and d.evo_next_label.text.contains("Passive 2: " + p2),
		"next evolution, what it needs and gives: \"%s\"" % d.evo_next_label.text.replace("\n", " / "))
	_check(d.active_label.text.begins_with("OVERRUN  ·  cooldown 7 turns") and d.active_label.text.contains(Skills.describe(&"overrun", T.FIRE)),
		"active skill in full words: \"%s\"" % d.active_label.text.replace("\n", " / "))
	_check(d.leader_label.text.contains(Skills.display_name(f.leader_skill).to_upper()) and d.leader_label.text.contains(Skills.describe(f.leader_skill, T.FIRE))
		and d.leader_label.text.contains("Only the hunter in team slot 1 is the leader, and leader skills never stack") and d.leader_label.text.contains("leads your team right now"),
		"leader skill + the slot-1 / never-stack note: \"%s\"" % d.leader_label.text.replace("\n", " / "))
	var pl := d.passive_labels
	_check(pl[0].text.contains("unlocks at Lv10  ·  UNLOCKED") and pl[1].text.contains("unlocks at Evolution 1  ·  LOCKED") and pl[2].text.contains("unlocks at Evolution 2  ·  LOCKED")
		and pl[0].text.contains(Skills.describe(f.passives[0], T.FIRE)),
		"passives: name, when they unlock (Lv10 / Evolution 1 / Evolution 2), locked or not, full text")
	_check(d.essence_label.text.contains("Essence: 3 / 10") and d.essence_label.text.contains("Training Cores used on it: 2"), "Essence progress 3 / 10, and Training Cores used")
	_check(d.use_core_button.visible and not d.use_core_button.disabled and d.evolve_button.disabled and d.evolve_button.text.contains("Needs Lv15")
		and d.retire_button.disabled and d.retire_button.text.contains("In your team"),
		"buttons: USE CORE, EVOLVE (\"%s\"), RETIRE blocked for a party member (\"%s\")" % [d.evolve_button.text.replace("\n", " "), d.retire_button.text.replace("\n", " ")])
	await _frames(2)
	await _shot("s6_detail_kaela_1_top")
	for k in [1, 2, 3]:
		d.scroll.scroll_vertical = k * 760
		await _frames(3)
		await _shot("s6_detail_kaela_%d" % (k + 1))
	d.scroll.scroll_vertical = 0
	await _click(d.lock_button)
	var locked: bool = p.unit(kaela)["locked"]
	var lock_text := d.lock_button.text
	await _click(d.lock_button)
	_check(locked and lock_text == "UNLOCK" and not p.unit(kaela)["locked"] and d.lock_button.text == "LOCK", "LOCK / UNLOCK toggles and saves")
	var lv := int(p.unit(kaela)["level"])
	await _click(d.use_core_button)
	_check(p.data["cores"] == 2 and int(p.unit(kaela)["cores"]) == 3 and d.essence_label.text.contains("used on it: 3"), "USE CORE works from the detail screen (Lv%d, %d Cores left)" % [p.unit(kaela)["level"], p.data["cores"]])
	await _click(d.close_button)
	_check(not d.visible, "CLOSE")
	_log("INFO  Kaela was Lv%d before the Core" % lv)


func _test_retire_and_stage3() -> void:
	_log("\n== 5B: Retire (twice) and a Stage 3 character ==")
	main.show_page("ROSTER")
	await _frames(3)
	var rs: RosterScreen = main.roster_screen
	rs.open_detail(kaela2)
	await _frames(2)
	var d: UnitDetail = rs.detail
	_check(d.visible and not d.retire_button.disabled and d.retire_button.text.begins_with("RETIRE"), "the Roster opens the same detail screen; a spare Kaela can be retired")
	await _click(d.retire_button)
	var first := d.retire_button.text
	var still := not p.unit(kaela2).is_empty()
	await _click(d.retire_button)
	_check(still and first.begins_with("SURE") and p.unit(kaela2).is_empty() and not d.visible and rs.toast.text.begins_with("Retired"), "RETIRE asks twice (\"%s\"), then retires and closes" % first)
	var s3 := p.add_unit("berserker_01_angel_fire", 5, 30)
	p.unit(s3)["stage"] = 3
	rs.open_detail(s3)
	await _frames(2)
	var now3: bool = (d.evo_boxes[2].get_node("Text") as Label).text.contains("NOW")
	_check(d.evo_label.text == "EVOLUTION: Stage 3/3" and now3 and d.evo_next_label.text.begins_with("Fully evolved") and d.stars.filled == 6
		and d.art_rect.texture == Catalog.art("berserker_01_angel_fire", 3) and d.passive_labels[2].text.contains("UNLOCKED"),
		"a Stage 3 Singularity Kaela: 3/3 highlighted, her Stage 3 art, 6 stars, every passive unlocked")
	await _shot("s6_detail_kaela_stage3_singularity")
	await _click(d.close_button)
	p.data["units"] = p.data["units"].filter(func(v: Dictionary) -> bool: return v["uid"] != s3)


# ================================================================ 5A: in battle

func _test_battle() -> void:
	_log("\n== 5A: in battle ==")
	main.start_act(1, 0, false)
	await _frames(6)
	var b = main.battle
	await _until(func() -> bool: return b.board.state == Board.State.READY, 5.0)
	await _tap_plate(b, 0)
	var pop: SkillPopup = b.skill_popup
	_check(pop.visible and pop.use_button.visible and not "replace_button" in pop and pop.details_button.text == "DETAILS" and pop.close_button.text == "CLOSE",
		"tapping Kaela's plate: USE / DETAILS / CLOSE (Universe update: no REPLACE in combat)")
	await _shot("s6_battle_popup")
	await get_tree().create_timer(SkillPopup.LOCKOUT + 0.05).timeout
	await _click(pop.details_button)
	var d: UnitDetail = b.unit_detail
	_check(d.visible and d.name_label.text == "KAELA RYNN" and not d.use_core_button.visible and not d.evolve_button.visible and not d.lock_button.visible
		and not d.retire_button.visible and d.note_label.text.contains("Read-only") and b.board.state == Board.State.LOCKED,
		"DETAILS in battle: the full detail screen, READ-ONLY (no train / evolve / lock / retire), board locked under it")
	await _shot("s6_battle_detail")
	await _click(d.close_button)
	_check(not d.visible and b.board.state == Board.State.READY, "closing it gives the turn back")
	# The team is changed on the TEAM screen (Replace there); the battle picks it up next fight.
	var mira_name: String = b.team.members[1].display_name
	p.set_team_slot(1, iris)
	main._write()
	for e in b.enemies:
		e.hp = 1
	await _turn(b, FIRE3)
	await _until(func() -> bool: return b.result_panel.visible, 6.0)
	await _click(b.result_panel._next_button)
	await _frames(4)
	_check(b.fight_index == 1 and b.team.members[1].display_name == "IRIS VALE" and mira_name != "IRIS VALE",
		"a team change made on the TEAM screen shows up from the next fight (%s -> IRIS VALE)" % mira_name)
	main.show_map()
	await _frames(3)


func _test_battle_without_save() -> void:
	_log("\n== 5A: a test fight with no save ==")
	var tb := BattleScene.instantiate()
	add_child(tb)
	await _frames(4)
	await _until(func() -> bool: return tb.board.state == Board.State.READY, 5.0)
	tb.open_skill_popup(0)
	await _frames(2)
	var no_replace: bool = not "replace_button" in tb.skill_popup
	tb.skill_popup.details_pressed.emit(0)
	tb.skill_popup.visible = false
	await _frames(2)
	var d: UnitDetail = tb.unit_detail
	_check(no_replace and d.visible and not d.lock_button.visible and not d.retire_button.visible and d.close_button.visible,
		"no save behind the fight: no REPLACE, DETAILS still shows the card (only CLOSE)")
	tb.queue_free()
	await _frames(2)


# ================================================================ helpers

func _card(pk: RosterPicker, uid: int) -> UnitCard:
	for c in pk.cards():
		if c.uid == uid:
			return c
	return null


func _card_levels(pk: RosterPicker) -> Array:
	return pk.cards().map(func(c: UnitCard) -> int: return int(p.unit(c.uid)["level"]))


func _sorted_desc(a: Array) -> bool:
	for i in a.size() - 1:
		if a[i] < a[i + 1]:
			return false
	return true


func _sorted_asc(a: Array) -> bool:
	for i in a.size() - 1:
		if a[i] > a[i + 1]:
			return false
	return true


func _tap_plate(b, i: int) -> void:
	var v: FighterView = b.team_views[i]
	var pos := v.get_global_transform_with_canvas() * v.hit_rect().get_center()
	_press(pos)
	await _frames(1)
	_release(pos)
	await _frames(3)


func _turn(b, rows: Array) -> void:
	var map := {"F": T.FIRE, "W": T.WATER, "G": T.WOOD, "L": T.LIGHT, "D": T.DARK, "H": T.HEART}
	for y in Board.ROWS:
		for x in Board.COLS:
			(b.board.grid[x][y] as Orb).setup(map[rows[y][x]])
	var pos: Vector2 = b.board.get_global_transform_with_canvas() * b.board.cell_center(Vector2i(5, 0))
	_press(pos)
	await _frames(1)
	_release(pos)
	await _frames(2)
	await _until(func() -> bool: return (b.board.state == Board.State.READY and b._player_turn) or b.result_panel.visible, 30.0)


func _click(c: Control) -> void:
	var pos := c.get_global_rect().get_center()
	_press(pos)
	await _frames(1)
	_release(pos)
	await _frames(3)


func _press(pos: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	ev.position = pos
	ev.global_position = pos
	get_viewport().push_input(ev, true)


func _release(pos: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = false
	ev.position = pos
	ev.global_position = pos
	get_viewport().push_input(ev, true)


func _until(cond: Callable, limit: float) -> void:
	var t := 0.0
	while not cond.call() and t < limit:
		await get_tree().process_frame
		t += get_process_delta_time()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(n: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await _frames(1)
	if not DisplayServer.window_can_draw():
		RenderingServer.force_draw(false)
	var img := get_viewport().get_texture().get_image()
	if img and not img.is_empty():
		img.save_png(ProjectSettings.globalize_path("res://tests/screenshots/%s.png" % n))


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	_log(("PASS  " if ok else "FAIL  ") + what)


func _log(text: String) -> void:
	print(text)
	lines.append(text)


func _finish() -> void:
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	_log("\n%s — %d failure(s)" % ["ALL PASSED" if fails == 0 else "SOME FAILED", fails])
	var f := FileAccess.open(ProjectSettings.globalize_path("res://tests/report_stage5.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	get_tree().quit(fails)
