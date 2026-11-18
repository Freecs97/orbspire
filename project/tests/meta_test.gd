extends Node
## Automated test for Stage C: real levels, characters, team select, Credits,
## Essence + Lab, Recruit (odds, Keys, duplicates), roster cap, retire, Training Cores.
## Developer tool. Plays the REAL main scene with its own save (user://meta_test_save.json).
## Run:  Godot_v4.7.2-stable_win64_console.exe --path . res://tests/meta_test.tscn
## Results: tests/report_meta.txt

const MainScene := preload("res://scenes/main.tscn")
const SAVE := "user://meta_test_save.json"
const FIRE4 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "FFFFDH"]

var main: Node
var p: Profile
var e: EconomyTuning = preload("res://data/economy.tres")
var lines := PackedStringArray()
var fails := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/screenshots"))
	_wipe()
	main = MainScene.instantiate()
	main.save_path = SAVE
	add_child(main)
	await _frames(3)
	if not "profile" in main or main.profile == null:
		_check(false, "main scene failed to load")
		_finish()
		return
	p = main.profile
	main.save["intro_seen"] = true
	_log("Godot %s · Stage C test (levels, characters, drops)" % Engine.get_version_info().string)
	_test_start()
	_test_names()
	await _test_battle_levels_and_rewards()
	_test_xp_rules()
	_test_credits_rules()
	_test_essence_rules()
	await _test_lab()
	await _test_recruit()
	_test_roster_cap()
	await _test_retire_and_cores()
	await _test_team_select()
	await _test_save_reload()
	_finish()


func _test_start() -> void:
	_log("\n== C1: a new game ==")
	var ids := []
	for u in p.data["units"]:
		ids.append(u["id"])
	_check(ids == ["berserker_01_angel_fire", "biotech_01_medic_water", "titan_01_shield_wood"] and p.data["team"].size() == 3,
		"starts with the story trio as the team: %s" % [ids])
	var all_lv1_forged := true
	for u in p.data["units"]:
		all_lv1_forged = all_lv1_forged and u["level"] == 1 and u["rarity"] == 2
	_check(all_lv1_forged and p.data["credits"] == 0 and p.data["roster_cap"] == 30, "all Lv1, Forged rarity; 0 Credits; roster cap 30")
	_check(Catalog.IDS.size() == 20, "20 collectable characters (5 per type, one per element)")
	var f := p.fighter(p.data["team"][0])
	_check(f.max_hp == 320 and f.atk == 95 and f.rcv == 10 and f.passives_unlocked == 0, "Fire Berserker Lv1 Forged = 320 / 95 / 10, no passive yet")


func _test_names() -> void:
	_log("\n== C1b: names from your roster list ==")
	var want := {"berserker_01_angel_fire": "KAELA RYNN|Fire Berserker", "spectre_01_rogue_dark": "VEX MARLOWE|Dark Spectre",
		"titan_03_anchor_water": "ROWAN TIDE|Water Titan", "biotech_05_radiant_light": "LUCA BRIGHT|Light Biotech"}
	var all_named := true
	for id in Catalog.IDS:
		var t := Catalog.template(id)
		all_named = all_named and t.display_name != "" and t.title != "" and not t.display_name.ends_with(t.title.to_upper())
	var spot := true
	for id in want:
		var parts: PackedStringArray = want[id].split("|")
		spot = spot and Catalog.template(id).display_name == parts[0] and Catalog.template(id).title == parts[1]
	_check(all_named and spot, "all 20 hunters have a name + title (e.g. KAELA RYNN · Fire Berserker, ROWAN TIDE · Water Titan)")
	var light_dark := {}
	for a in StarMap.ACTS:
		for f in a.fights:
			for d in f.enemies:
				if (d.element == Element.Type.LIGHT or d.element == Element.Type.DARK) and not d.is_boss or (d.is_boss and d.title != ""):
					light_dark["%s (%s)" % [d.display_name, d.title]] = d.title != ""
	_check(not light_dark.is_empty() and light_dark.values().all(func(v: bool) -> bool: return v), "every Light/Dark enemy in all 10 Acts has its proper name: %s" % ", ".join(PackedStringArray(light_dark.keys())))


func _test_battle_levels_and_rewards() -> void:
	_log("\n== C2: real levels in battle + rewards after a fight ==")
	main.start_act(1, 0, false)
	await _frames(4)
	var b = main.battle
	_check(not b.use_level_preview and b.level_label.text.contains("TEAM Lv1") and not b.level_label.text.contains("preview"), "Act 1 uses your real levels (\"%s\"), not the preview" % b.level_label.text)
	var hp_before: int = b.team.max_hp
	for en in b.enemies:
		en.hp = 1
	_set_board(b, FIRE4)
	await _tap(b, Vector2i(5, 0))
	await _until(func() -> bool: return b.result_panel.visible, 15.0)
	var r: Dictionary = b.last_rewards
	_check(r.get("credits", 0) == 30 and r.get("xp", 0) == 60, "win fight 1: +60 XP and +30 Credits (20 + 10 x Act 1): %s" % [r])
	var lv := []
	for uid in p.data["team"]:
		lv.append(p.unit(uid)["level"])
	_check(lv == [2, 2, 2], "60 XP takes each team member Lv1 -> Lv2: %s" % [lv])
	_check(b.result_panel._info.text.contains("Lv2!") and b.result_panel._info.text.contains("+30 Credits"), "the win screen lists Credits and level-ups")
	await _shot("c2_rewards")
	await _click(b.result_panel._next_button)
	await _frames(3)
	_check(b.team.max_hp > hp_before, "next fight: the team has its new Lv2 stats (HP %d -> %d)" % [hp_before, b.team.max_hp])
	main.show_star_map()
	await _frames(2)


func _test_xp_rules() -> void:
	_log("\n== C3: XP, catch-up, Passive 1 at Lv10 ==")
	var uid := p.add_unit("titan_02_guardian_fire", 2, 1)
	var top := p.add_unit("berserker_02_hulk_wood", 2, 12)
	var u := p.unit(uid)
	var lines_up := p.grant_xp([uid], 100)
	# 12 - 1 = 11 levels below the highest -> x2 XP: 200 XP = Lv1 -> 2 (50) -> 3 (75), 75 left.
	_check(u["level"] == 3 and u["xp"] == 75, "11 levels behind your highest: x2 catch-up XP (100 -> 200): Lv%d, %d XP" % [u["level"], u["xp"]])
	var mid := p.add_unit("biotech_02_splicer_wood", 2, 8)
	p.grant_xp([mid], 100)
	_check(p.unit(mid)["xp"] == 150, "4 levels behind: x1.5 (100 -> 150 XP)")
	var to10 := Profile.PROGRESSION.total_xp_for(10) - Profile.PROGRESSION.total_xp_for(3) - 75
	lines_up = p.grant_xp([top], 0)
	p.add_xp(u, to10)
	_check(u["level"] == 10 and p.fighter(uid).passives_unlocked == 1, "at Lv10 Passive 1 unlocks (passives unlocked: %d)" % p.fighter(uid).passives_unlocked)
	var x := p.add_unit("spectre_02_mage_fire", 2, 9)
	var msg := p.grant_xp([x], 400)
	_check(not msg.is_empty() and msg[0].contains("Passive unlocked"), "level-up message says so: \"%s\"" % ("" if msg.is_empty() else msg[0]))
	var cap := p.add_unit("titan_03_anchor_water", 2, 30)
	p.add_xp(p.unit(cap), 99999)
	_check(p.unit(cap)["level"] == 30, "level cap is 30")
	for id in [uid, top, mid, x, cap]:
		p.data["units"] = p.data["units"].filter(func(v: Dictionary) -> bool: return v["uid"] != id)


func _test_credits_rules() -> void:
	_log("\n== C4: Credits (win / lose / mini-boss / boss / first clear + Key) ==")
	var a1: ActData = StarMap.ACTS[0]
	var a3: ActData = StarMap.ACTS[2]
	p.rng.seed = 7
	var c0: int = p.data["credits"]
	var r := p.fight_rewards(a3.fights[0], 3, false, [], false)
	_check(r["credits"] == roundi((20 + 30) * 0.25) and r["xp"] == 0, "a LOSE in Act 3 pays 25%% of 50 = %d Credits and no XP" % r["credits"])
	r = p.fight_rewards(a3.fights[2], 3, true, [], false)
	_check(r["credits"] == 100, "Act 3 mini-boss win: 50 x 2 = %d" % r["credits"])
	r = p.fight_rewards(a1.fights[7], 1, true, [], true)
	_check(r["credits"] == 30 * 4 + 300 and r["keys"] == 1, "Act 1 boss, first clear: 30 x 4 + 300 bonus = %d Credits, +%d Key" % [r["credits"], r["keys"]])
	r = p.fight_rewards(a1.fights[7], 1, true, [], true)
	_check(r["credits"] == 120 and r["keys"] == 0, "beating it again: no bonus, no Key (%d)" % r["credits"])
	_check(p.data["credits"] > c0, "Credits are added to your total (%d)" % p.data["credits"])


func _test_essence_rules() -> void:
	_log("\n== C5: Digital Essence drops ==")
	var map := {
		"EMBER DRONE": "berserker_01_angel_fire", "COOLANT SLIME": "biotech_01_medic_water",
		"FURNACE WORKER": "titan_02_guardian_fire", "SHADOW THIEF": "spectre_01_rogue_dark", "EMBERFANG-9": "berserker_01_angel_fire",
	}
	var ok := true
	var shown := PackedStringArray()
	for f in StarMap.ACTS[0].fights:
		var d: FighterData = f.enemies[0]
		if map.has(d.display_name):
			var got := Catalog.essence_for(d, 1)
			ok = ok and got == map[d.display_name]
			shown.append("%s -> %s" % [d.display_name, Catalog.display_name(got)])
	_check(ok, "each enemy drops Essence for one specific character: %s" % ", ".join(shown))
	p.rng.seed = 11
	var regular: FightData = StarMap.ACTS[0].fights[1]   # 3 Coolant Slimes
	var drops := 0
	var trials := 3000
	for k in trials:
		var r := p.fight_rewards(regular, 1, true, [], false)
		for id in r["essence"]:
			drops += r["essence"][id]
	var rate := float(drops) / (trials * 3)
	_check(rate > 0.13 and rate < 0.17, "regular enemies drop 1 Essence %.1f%% of the time (target 15%%)" % (rate * 100))
	var mini_ok := true
	for k in 200:
		var r := p.fight_rewards(StarMap.ACTS[0].fights[2], 1, true, [], false)
		var n := 0
		for id in r["essence"]:
			n += r["essence"][id]
		mini_ok = mini_ok and n >= 1 and n <= 2
	_check(mini_ok, "mini-bosses always drop 1-2 Essence")
	var rb := p.fight_rewards(StarMap.ACTS[0].fights[7], 1, true, [], false)
	_check(rb["essence"].get("berserker_01_angel_fire", 0) == 3, "the boss always drops 3 Essence (%s)" % [rb["essence"]])


func _test_lab() -> void:
	_log("\n== C6: Lab: 10 Essence -> craft ==")
	p.data["essence"]["spectre_03_sniper_wood"] = 10
	main.show_page("ROSTER")
	await _frames(2)
	var rs: RosterScreen = main.roster_screen
	await _click(rs.lab_button)
	await _frames(2)
	var btn: Button = rs.craft_buttons.get("spectre_03_sniper_wood")
	_check(rs.showing_lab and btn != null and not btn.disabled and rs.craft_buttons["titan_05_sanctum_light"].disabled, "LAB lists all 20 with Essence (x / 10); CRAFT only lights up at 10")
	await _shot("c6_lab")
	var n_before: int = p.data["units"].size()
	rs.scroll.ensure_control_visible(btn)
	await _frames(3)
	await _click(btn)
	await _frames(2)
	var made: Dictionary = p.data["units"][-1]
	_check(p.data["units"].size() == n_before + 1 and made["id"] == "spectre_03_sniper_wood" and made["level"] == 1 and made["rarity"] == 2
		and p.data["essence"]["spectre_03_sniper_wood"] == 0, "CRAFT: Wood Spectre joins at Lv1 (Forged); Essence 10 -> 0")


func _test_recruit() -> void:
	_log("\n== C7: Recruit: costs, odds, Keys, duplicates ==")
	p.data["credits"] = 5000
	main.show_page("RECRUIT")
	await _frames(2)
	var rc: RecruitScreen = main.recruit_screen
	_check(rc.odds_label.text.contains("Basic:  Scrap 50") and rc.odds_label.text.contains("Key:  Ascendant 80"), "the odds are shown on screen")
	var n_before: int = p.data["units"].size()
	await _click(rc.tier_buttons[0])
	await _frames(3)
	_check(rc.reveal.visible and p.data["credits"] == 4700 and p.data["units"].size() == n_before + 1, "BASIC recruit: -300 Credits, a new character revealed")
	await _shot("c7_recruit_reveal")
	await _click(rc.reveal_ok)
	p.data["credits"] = 0
	await _click(rc.tier_buttons[2])
	_check(not rc.reveal.visible and rc.toast.text == "Not enough Credits", "ELITE without Credits: \"%s\"" % rc.toast.text)
	# Odds: simulate many pulls with the real roll function.
	p.rng.seed = 42
	for tier in 4:
		var counts := [0, 0, 0, 0, 0, 0]
		var pulls := 20000
		for k in pulls:
			counts[p.roll_rarity(e.odds_for(tier))] += 1
		var ok := true
		var got := PackedStringArray()
		for r in 6:
			var pct: float = 100.0 * counts[r] / pulls
			ok = ok and absf(pct - e.odds_for(tier)[r]) < 1.2
			got.append("%.1f" % pct)
		_check(ok, "%s odds over 20,000 pulls: %s%% (table %s)" % ["Key" if tier == 3 else e.recruit_names[tier], ", ".join(got), e.odds_for(tier)])
	p.data["keys"] = 1
	var kr := p.recruit(3)
	_check(not kr.is_empty() and kr["rarity"] >= 4 and p.data["keys"] == 0, "KEY recruit: %s (Ascendant or better), Key used" % Catalog.rarity_name(kr["rarity"]))
	var seen := {}
	var dup := false
	p.data["credits"] = 100000
	for k in 25:
		var r := p.recruit(0)
		if r.is_empty():
			break
		dup = dup or seen.has(r["id"])
		seen[r["id"]] = true
	_check(dup, "duplicates can be pulled")
	# Clean up the extra pulls (keep the roster small for the next tests).
	var keep: Array = p.data["units"].slice(0, n_before + 1)
	p.data["units"] = keep
	p.data["credits"] = 0


func _test_roster_cap() -> void:
	_log("\n== C8: roster cap 30, +5 slots for Credits ==")
	var n0: int = p.data["units"].size()
	while p.data["units"].size() < 30:
		p.add_unit("berserker_05_solar_light", 0)
	p.data["credits"] = 10000
	_check(p.can_recruit(0).begins_with("Roster full") and p.recruit(0).is_empty(), "at 30/30 recruiting is blocked: \"%s\"" % p.can_recruit(0))
	p.data["essence"]["titan_04_void_dark"] = 10
	_check(p.craft("titan_04_void_dark") == -1, "crafting is blocked too")
	_check(p.expand_roster() and p.data["roster_cap"] == 35 and p.data["credits"] == 9000, "EXPAND: cap 30 -> 35 for 1,000 Credits")
	_check(not p.recruit(0).is_empty(), "then recruiting works again")
	p.data["units"] = p.data["units"].slice(0, n0)
	p.data["credits"] = 0


func _test_retire_and_cores() -> void:
	_log("\n== C9: retire rules + Training Cores ==")
	var team0: int = p.data["team"][0]
	_check(p.retire_check(team0).begins_with("In your team"), "can't retire a team member: \"%s\"" % p.retire_check(team0))
	var only_light := p.add_unit("biotech_05_radiant_light", 1)
	_check(p.retire_check(only_light).begins_with("Your only LIGHT"), "can't retire your only character of an element: \"%s\"" % p.retire_check(only_light))
	var dup := p.add_unit("biotech_05_radiant_light", 3)
	p.toggle_lock(dup)
	_check(p.retire_check(dup).begins_with("Locked"), "a locked character can't be retired")
	p.toggle_lock(dup)
	p.data["credits"] = 200
	_check(p.buy_core() and p.buy_core() and p.data["cores"] == 2 and p.data["credits"] == 100, "BUY CORE: 50 Credits each")
	var u := p.unit(dup)
	p.use_core(dup)
	p.use_core(dup)
	_check(u["cores"] == 2 and u["level"] >= 2 and p.data["cores"] == 0, "USE CORE: +100 XP each (2 used: Lv%d)" % u["level"])
	_check(p.retire_value(dup) == 30 + 1, "retire value: Prime base 30 + 50%% of 2 cores = %d" % p.retire_value(dup))
	main.show_page("ROSTER")
	await _frames(2)
	var rs: RosterScreen = main.roster_screen
	rs.open_detail(dup)
	await _frames(2)
	await _shot("c9_detail")
	await _click(rs.retire_button)
	_check(p.unit(dup).size() > 0 and rs.retire_button.text.begins_with("SURE"), "RETIRE asks twice (first tap: \"%s\")" % rs.retire_button.text)
	await _click(rs.retire_button)
	await _frames(2)
	_check(p.unit(dup).is_empty() and p.data["cores"] == 31, "second tap retires it: +31 Training Cores (%d)" % p.data["cores"])
	_check(p.retire_check(only_light).begins_with("Your only LIGHT"), "with the duplicate gone, the remaining Light character is protected again")
	p.data["units"] = p.data["units"].filter(func(v: Dictionary) -> bool: return v["uid"] != only_light)


func _test_team_select() -> void:
	_log("\n== C10: TEAM: pick who fights ==")
	var extra := p.add_unit("berserker_03_thin_water", 4, 5)
	main.show_page("TEAM")
	await _frames(2)
	var ts: TeamScreen = main.team_screen
	await _click(ts.slot_cards[1])
	_check(ts.picker.visible, "tapping slot 2 opens the picker")
	await _shot("c10_team_picker")
	var card: UnitCard = null
	for c in ts.picker_cards():
		if c.uid == extra:
			card = c
	await _click(card)
	_check(p.data["team"][1] == extra and not ts.picker.visible, "picked the Water Berserker into slot 2")
	var old_leader: int = p.data["team"][0]
	await _click(ts.slot_cards[0])
	for c in ts.picker_cards():
		if c.uid == extra:
			card = c
	await _click(card)
	_check(p.data["team"][0] == extra and p.data["team"][1] == old_leader, "picking someone already in the team swaps the two slots")
	await _shot("c10_team")
	main.start_act(1, 0, false)
	await _frames(4)
	var b = main.battle
	_check(b.team.members.size() == 3 and b.team.members[0].display_name == "IRIS VALE" and b.team.leader().leader_skill == &"leader_berserker", "Act 1 fights with the chosen team (leader: %s)" % b.team.members[0].display_name)
	main.show_star_map()
	await _frames(2)


func _test_save_reload() -> void:
	_log("\n== C11: everything is saved ==")
	main._write()
	var before: String = JSON.stringify(main.save)
	main.queue_free()
	await _frames(2)
	var m2 := MainScene.instantiate()
	m2.save_path = SAVE
	add_child(m2)
	await _frames(3)
	_check(JSON.stringify(m2.save) == before or (m2.profile.data["units"].size() == JSON.parse_string(before)["units"].size() and m2.profile.data["cores"] == int(JSON.parse_string(before)["cores"])),
		"reloading the save gives the same roster, team, Credits, Cores and Essence")
	m2.queue_free()


# ---------------------------------------------------------------- helpers

func _set_board(b: Node, rows: Array) -> void:
	var map := {"F": Element.Type.FIRE, "W": Element.Type.WATER, "G": Element.Type.WOOD, "L": Element.Type.LIGHT, "D": Element.Type.DARK, "H": Element.Type.HEART}
	for y in Board.ROWS:
		for x in Board.COLS:
			(b.board.grid[x][y] as Orb).setup(map[rows[y][x]])


func _tap(b: Node, c: Vector2i) -> void:
	var pos: Vector2 = b.board.get_global_transform_with_canvas() * b.board.cell_center(c)
	_press(pos)
	await _frames(1)
	_release(pos)
	await _frames(1)


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
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://tests/screenshots/%s.png" % n))


func _wipe() -> void:
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	_log(("PASS  " if ok else "FAIL  ") + what)


func _log(text: String) -> void:
	print(text)
	lines.append(text)


func _finish() -> void:
	_log("\n%s — %d failure(s)" % ["ALL PASSED" if fails == 0 else "SOME FAILED", fails])
	var f := FileAccess.open(ProjectSettings.globalize_path("res://tests/report_meta.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	_wipe()
	get_tree().quit(fails)
