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
		var act: ActData = StarMap.ACTS[n - 1]
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
	_log("\n== S6-S: story beats + codex (universe only) ==")
	var ok := true
	var banned := ["The Ban", "the Ban", "Mara", "June"]
	var clean := true
	for n in range(1, 11):
		var act: ActData = StarMap.ACTS[n - 1]
		var all := " ".join(PackedStringArray(act.intel_lines)) + " " + " ".join(PackedStringArray(act.intro_lines)) + " " + act.boss_taunt + " " + act.outro_line \
			+ " " + act.codex_spliced_from + " " + act.codex_wanted + " " + act.codex_cost
		var has := act.intro_lines.size() == 2 and act.boss_taunt != "" and act.outro_line != "" and act.codex_spliced_from != "" and act.codex_wanted != "" and act.codex_cost != "" and act.intel_lines.size() == 3
		ok = ok and has
		for w in banned:
			clean = clean and not all.contains(w)
		clean = clean and (n == 1 or all.contains("Progenitors"))
		if n >= 2:
			_log("INFO  Act %2d intro: %s" % [n, " / ".join(PackedStringArray(act.intro_lines))])
			_log("INFO         taunt: %s" % act.boss_taunt)
			_log("INFO         outro: %s" % act.outro_line)
	_check(ok, "every Act has 3 intel lines, a 2-line intro, a boss taunt, an outro and a codex entry (spliced from / wanted / cost)")
	_check(clean, "THE PROGENITORS everywhere; never \"The Ban\"; no Mara, no June")


func _test_unlock_and_intro() -> void:
	_log("\n== S6-U / S6-I: unlocking and intros ==")
	var m := StarMap.new()
	m.cleared = []
	var s0 := [m.state(1), m.state(2)]
	m.cleared = [1, 2, 3]
	var s1 := [m.state(4), m.state(5), m.state(3)]
	m.free()
	_check(s0 == ["current", "locked"] and s1 == ["current", "locked", "completed"], "the star map unlocks an Act only after the Act before it is cleared (%s, %s)" % [s0, s1])
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
	main.star_map.play_pressed.emit(3)
	await _frames(4)
	var b = main.battle
	var first: bool = b != null and b.act.act_number == 3 and b.story_beat.is_open() and b.story_beat._speaker.text.begins_with("GREENHOUSE RUINS")
	b.story_beat.close()
	await _frames(2)
	main.show_star_map()
	await _frames(2)
	main.star_map.play_pressed.emit(3)
	await _frames(4)
	var again: bool = main.battle.story_beat.is_open()
	_check(first and not again and 3 in main.save["act_intros"], "Act 3's intro plays the first time you start it, not the second time")
	main.show_star_map()
	main.queue_free()
	await _frames(2)
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _test_balance() -> void:
	_log("\n== S6-B: harder every Act, Resolve holds ==")
	var hp := []
	var atk := []
	var mini := []
	for act in StarMap.ACTS:
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
	for act in StarMap.ACTS:
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
