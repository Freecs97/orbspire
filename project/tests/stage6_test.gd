extends Node
## Stage 6 test: Acts 2-10 rebuilt on the new balance (tools/generate_acts.gd).
##   S6-A  each Act: 8 fights, its own arena + boss art, enemy counts, XP curve
##   S6-S  story: 2-line intro, boss taunt, outro, codex entry; THE PROGENITORS,
##         never "The Ban", no Mara / June
##   S6-U  an Act unlocks only when the Act before it is cleared (the star map)
##   S6-B  harder every Act; Resolve: a max team can't one-shot any boss
##   S6-I  an Act's intro plays once, the first time you start it
## The full campaign playtest (240 simulated players) is tools/act_generation_report.txt.
## Run:  Godot_v4.7.2-stable_win64_console.exe --path . res://tests/stage6_test.tscn
## Results: tests/report_stage6.txt

const MainScene := preload("res://scenes/main.tscn")
const SAVE := "user://stage6_test_save.json"
const ARENA := ["", "bg_act01_furnace_arena", "bg_act02_drowned_arena", "bg_act03_greenhouse_arena", "bg_act04_spires_arena", "bg_act05_void_arena",
	"bg_act06_solar_arena", "bg_act07_data_arena", "bg_act08_gene_arena", "bg_act09_sanctum_arena", "bg_act10_core_arena"]
const BOSSES := ["", "EMBERFANG-9", "TIDECOIL-7", "THORNWOOD UNIT", "DAWNWING", "VOIDSCALE", "ASHEN-01", "KRAKEN MAINFRAME", "MOSSBACK CHIMERA", "SERAPH ENFORCER", "REAPER-0"]

var lines := PackedStringArray()
var fails := 0


func _ready() -> void:
	GameSettings.path = "user://test_settings.json"
	GameSettings.skill_cut_ins = false
	Profile.friend_drops = false
	_log("Godot %s · Stage 6: Acts 2-10" % Engine.get_version_info().string)
	_test_acts()
	_test_story()
	await _test_unlock_and_intro()
	_test_balance()
	_finish()


func _test_acts() -> void:
	_log("\n== S6-A: the Acts ==")
	var ok := true
	var xp_total := 0
	var levels := []
	var p: ProgressionTuning = load("res://data/progression.tres")
	for n in range(1, 11):
		var act: ActData = Cosmos.ACTS[n - 1]
		var f8: FightData = act.fights[7] if act.fights.size() == 8 else null
		var counts := act.fights.map(func(f: FightData) -> int: return f.enemies.size())
		var good: bool = act.act_number == n and act.fights.size() == 8 and act.arena.resource_path.ends_with(ARENA[n] + ".png") \
			and f8 != null and f8.enemies[0].display_name == BOSSES[n] and f8.enemies[0].is_boss and f8.enemies[0].armored \
			and act.boss_art != null and f8.enemies[0].art == act.boss_art and counts.max() <= 3
		ok = ok and good
		for f in act.fights:
			xp_total += f.xp
		levels.append(p.level_for_xp(xp_total))
		_log("INFO  Act %2d  %-17s %-16s boss %5d HP / %3d ATK · enemies per fight %s%s" % [n, act.colony_name, act.singularity_name, f8.enemies[0].max_hp, f8.enemies[0].atk, counts, "" if good else "  <- PROBLEM"])
	_check(ok, "Acts 1-10: 8 fights each, each Act's own arena and boss art, boss armoured, never more than 3 enemies")
	_check(levels == [10, 12, 14, 16, 18, 20, 22, 24, 27, 30], "XP: the team reaches %s after each boss (Lv30 = max only in Act 10, after evolving at Lv15)" % [levels])


func _test_story() -> void:
	_log("\n== S6-S: the approved story (2026-11-19), Part A ==")
	var ok := true
	var same := true
	var banned := ["The Ban", "the Ban", "the ban", "Mara", "June"]
	var clean := true
	for n in range(1, 11):
		var act: ActData = Cosmos.ACTS[n - 1]
		var s: Dictionary = StoryText.ACTS[n]
		var all := " ".join(PackedStringArray(act.intel_lines)) + " " + " ".join(PackedStringArray(act.intro_lines)) + " " + act.boss_taunt + " " + act.outro_line \
			+ " " + act.codex_colony + " " + act.codex_rationed + " " + act.codex_spliced_from + " " + act.codex_abandoned
		var has := act.intro_lines.size() == 2 and act.boss_taunt != "" and act.outro_line != "" and act.codex_colony != "" and act.codex_rationed != "" \
			and act.codex_spliced_from != "" and act.codex_abandoned != "" and act.intel_lines.size() == 3
		ok = ok and has
		same = same and Array(act.intro_lines) == s["intro"] and act.boss_taunt == s["taunt"] and act.outro_line == s["outro"] \
			and act.codex_colony == s["colony"] and act.codex_rationed == s["rationed"] and act.codex_spliced_from == s["spliced"] and act.codex_abandoned == s["abandoned"]
		var outro_lines := act.outro_line.split("\n").size()
		ok = ok and (n == 1 or (outro_lines >= 2 and outro_lines <= 3))
		for w in banned:
			clean = clean and not all.contains(w)
		clean = clean and (n == 1 or all.contains("Progenitors") or all.contains("Year 121") or all.contains("outlaw"))
		_log("INFO  Act %2d taunt (%.0f s): %s" % [n, act.taunt_seconds, act.boss_taunt])
	_check(ok, "every Act: 2-line intro, boss taunt, 2-3 line outro, 4-line codex (colony / rationed / spliced / abandoned), 3 intel lines")
	_check(same, "the Act files hold exactly the approved text (scripts/data/story_text.gd)")
	_check(clean, "THE PROGENITORS, never \"The Ban\" (the Act 9 preview now says \"enforce their law\"); no Mara, no June")
	var a1: ActData = Cosmos.ACTS[0]
	_check(a1.boss_taunt == "You did not make me. But you made what made me." and Cosmos.ACTS[9].boss_taunt == "I was the first splice. I remember being made. I remember who made me.",
		"the two locked lines: Emberfang-9 and Reaper-0")
	var early := ""
	for n in range(1, 10):
		early += Cosmos.ACTS[n - 1].outro_line + " " + Cosmos.ACTS[n - 1].boss_taunt + " " + " ".join(PackedStringArray(Cosmos.ACTS[n - 1].intro_lines))
	_check(not early.contains("first splice") and not early.contains("Year 61") and Cosmos.ACTS[9].outro_line.contains("Year 61"),
		"the Act 10 twist (the Progenitors were the first splices, Year 61) is only in Act 10")
	_check(a1.outro_seconds == 10.0 and a1.taunt_seconds == 5.0 and Cosmos.ACTS[5].outro_seconds > 10.0,
		"Act 1's beats keep their timing; longer outros stay on screen longer (Act 6: %.0f s)" % Cosmos.ACTS[5].outro_seconds)

func _test_unlock_and_intro() -> void:
	_log("\n== S6-U / S6-I: unlocking and intros ==")
	var save0 := {"cleared_acts": []}
	var j0 := Journey.new(save0)
	var s0 := [j0.world_state(Cosmos.act_world_key(1)), j0.world_state(Cosmos.act_world_key(2))]
	var save1 := {"cleared_acts": [1, 2, 3]}
	var j1 := Journey.new(save1)
	var s1 := [j1.world_state(Cosmos.act_world_key(4)), j1.world_state(Cosmos.act_world_key(5)), j1.world_state(Cosmos.act_world_key(3))]
	_check(s0 == ["current", "locked"] and s1 == ["current", "locked", "completed"], "the map unlocks an Act only after the Act before it is cleared (%s, %s)" % [s0, s1])
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var main := MainScene.instantiate()
	main.save_path = SAVE
	add_child(main)
	await _frames(3)
	main.save["intro_seen"] = true
	main.save["act_intros"] = [1]
	main.save["slot4_notice"] = true
	main.save["cleared_acts"] = [1, 2]
	main.profile.choose_starter(Profile.STARTERS[0])
	main.play_world(Cosmos.act_world_key(3), 0)
	await _frames(4)
	var b = main.battle
	var first: bool = b != null and b.act.act_number == 3 and b.story_beat.is_open() and b.story_beat._speaker.text.begins_with("GREENHOUSE RUINS")
	b.story_beat.close()
	await _frames(2)
	main.show_map()
	await _frames(2)
	main.play_world(Cosmos.act_world_key(3), 0)
	await _frames(4)
	var again: bool = main.battle.story_beat.is_open()
	_check(first and not again and 3 in main.save["act_intros"], "Act 3's intro plays the first time you start it, not the second time")
	main.show_map()
	main.queue_free()
	await _frames(2)
	# An OLD save (before intros were tracked): Acts it already started or cleared
	# never replay their intro, even with the new story text.
	var old := {"intro_seen": true, "cleared_acts": [1, 2, 3, 4], "act_fight": {"5": 3}, "codex": [], "slot4_notice": true,
		"units": [], "team": []}
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify(old))
	f.close()
	var main2 := MainScene.instantiate()
	main2.save_path = SAVE
	add_child(main2)
	await _frames(3)
	main2.profile.choose_starter(Profile.STARTERS[0])
	var seen: Array = main2.save["act_intros"]
	main2.play_world(Cosmos.act_world_key(4), 0)
	await _frames(4)
	var replay4: bool = main2.battle.story_beat.is_open()
	main2.show_map()
	await _frames(2)
	main2.play_world(Cosmos.act_world_key(5), 0)
	await _frames(4)
	var replay5: bool = main2.battle.story_beat.is_open()
	main2.show_map()
	await _frames(2)
	main2.play_world(Cosmos.act_world_key(6), 0)
	await _frames(4)
	var new6: bool = main2.battle.story_beat.is_open() and main2.battle.story_beat.shown_text() == "\n".join(PackedStringArray(StoryText.ACTS[6]["intro"]))
	main2.battle.story_beat.close()
	_check(seen.has(4) and seen.has(5) and not replay4 and not replay5 and new6,
		"an old save: Acts 4 and 5 (already played) don't replay their intro; Act 6 (never started) shows its new intro once")
	main2.show_map()
	main2.queue_free()
	await _frames(2)
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _test_balance() -> void:
	_log("\n== S6-B: harder every Act, Resolve holds ==")
	var hp := []
	var atk := []
	var mini := []
	for act in Cosmos.ACTS:
		hp.append(act.fights[7].enemies[0].max_hp)
		atk.append(act.fights[7].enemies[0].atk)
		mini.append(act.fights[2].enemies[0].atk)
	_check(_rising(hp) and _rising(atk) and _rising(mini), "boss HP %s and ATK %s, and mini-boss ATK, rise every Act" % [hp, atk])
	# A max team: 4 x Lv30, Singularity, both evolutions, every passive.
	var held := true
	var e := Profile.ECONOMY
	var team: Array[FighterData] = []
	for id in ["berserker_04_void_dark", "spectre_02_mage_fire", "berserker_01_angel_fire", "spectre_04_assassin_water"]:
		var f: FighterData = CombatRules.at_level(Catalog.template(id), 30).duplicate()
		var mult: float = e.rarity_stat_mult[5] * (1.0 + e.evo_stat_bonus * 2)
		f.atk = roundi(f.atk * mult)
		f.max_hp = roundi(f.max_hp * mult)
		f.passives_unlocked = 3
		team.append(f)
	var left := []
	for act in Cosmos.ACTS:
		var g := BalanceSim.great_turn(act.fights[7].enemies, team)
		left.append(g["left"])
		held = held and g["left"] > 0
	_check(held, "a max team (4 x Lv30 evolved Singularity) can't one-shot any boss: HP left after one perfect turn %s" % [left])


func _rising(a: Array) -> bool:
	for i in a.size() - 1:
		if a[i + 1] <= a[i]:
			return false
	return true


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	_log(("PASS  " if ok else "FAIL  ") + what)


func _log(text: String) -> void:
	print(text)
	lines.append(text)


func _finish() -> void:
	_log("\n%s — %d failure(s)" % ["ALL PASSED" if fails == 0 else "SOME FAILED", fails])
	var f := FileAccess.open(ProjectSettings.globalize_path("res://tests/report_stage6.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	get_tree().quit(fails)
