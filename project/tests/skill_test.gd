extends Node
## Stage 3 Part A test: every character's OWN skills (docs/stage3_skill_table.md).
##   A - each of the 18 active skills fires in a real battle and does what the table says
##       (screenshot of each skill's animation: tests/screenshots/sk_<skill>.png)
##   K - each of the 20 leader skills: triggers when it should, not when it shouldn't
##   P - each passive (Last Stand = survive a fatal hit once per fight)
##   B - balance: 3-of-a-type teams through Act 1, starters equal, Resolve vs skills
## Run:  Godot_v4.7.2-stable_win64_console.exe --path . res://tests/skill_test.tscn
## Results: tests/report_skills.txt

const BattleScene := preload("res://scenes/battle.tscn")
const BASE := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "FWGLDH"]
const HEART5 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "HHHHHW"]
const T := Element.Type
const ROWS_OF := {
	Element.Type.FIRE: ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "FFFLDH"],
	Element.Type.WATER: ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "WWWLDH"],
	Element.Type.WOOD: ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "GGGLDH"],
	Element.Type.LIGHT: ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "LLLFWH"],
	Element.Type.DARK: ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "DDDLWH"],
}
const WATER4 := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "WWWWDH"]

var battle: Node2D
var lines := PackedStringArray()
var fails := 0
var last_combos := 0
var last_cleared := {}
var screenshots := true
var tu: SkillTuning = Skills.TUNING


func _ready() -> void:
	screenshots = DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/screenshots"))
	battle = BattleScene.instantiate()
	add_child(battle)
	await _frames(3)
	if not "team" in battle:
		_check(false, "battle script failed to load (see the Godot log)")
		_finish()
		return
	battle.board.turn_finished.connect(func(c: int, cl: Dictionary, _g: Array) -> void:
		last_combos = c
		last_cleared = cl)
	_log("Godot %s · Stage 3 Part A: per-character skills" % Engine.get_version_info().string)
	_test_table()
	await _test_actives()
	_test_leaders()
	await _test_passives()
	_test_balance()
	_finish()


# ---------------------------------------------------------------- the table itself

func _test_table() -> void:
	_log("\n== T: the 20 skill sets ==")
	var actives := {}
	var leaders := {}
	var sets := {}
	var cd_ok := true
	for id in Catalog.IDS:
		var c := Catalog.template(id)
		var cd := Skills.cooldown(c.active_skill)
		cd_ok = cd_ok and cd >= 5 and cd <= 9 and Skills.describe(c.active_skill) != "" and Skills.describe(c.leader_skill) != ""
		if c.active_skill != &"overrun":
			actives[c.active_skill] = int(actives.get(c.active_skill, 0)) + 1
		leaders[c.leader_skill] = true
		var key := ",".join(PackedStringArray(c.passives))
		sets[key] = true
		_log("INFO  %-13s %-15s | %-16s CD%d | %-14s | %s / %s / %s" % [c.display_name, c.title, Skills.display_name(c.active_skill), cd,
			Skills.display_name(c.leader_skill), Skills.display_name(c.passives[0]), Skills.display_name(c.passives[1]), Skills.display_name(c.passives[2])])
	_check(cd_ok, "every active skill has a cooldown of 5-9 and every skill has a description")
	_check(actives.size() == 17 and actives.values().all(func(n: int) -> bool: return n == 1), "17 different active skills (+ Overrun for the 3 starters)")
	_check(leaders.size() == 20, "20 different leader skills (%d)" % leaders.size())
	_check(sets.size() == 20, "no two characters share the same 3 passives (%d different sets)" % sets.size())
	var spectre_atk := true
	for id in Catalog.IDS:
		var c := Catalog.template(id)
		if c.role == FighterData.Role.SPECTRE:
			spectre_atk = spectre_atk and c.atk == 110 and c.max_hp == 230
	_check(spectre_atk, "Spectres toned down: 230 HP / 110 ATK (was 130)")
	_check(not "bind_resist" in str(Catalog.template("titan_01_shield_wood").passives) and Catalog.template("titan_01_shield_wood").passives[2] == &"damage_resist",
		"Bram Stone: Passive 3 is Damage Resist now (Bind Resist removed until binds exist)")
	_check(Skills.cooldown(&"mend") == 5, "Mend is CD 5")


# ---------------------------------------------------------------- A: actives

func _test_actives() -> void:
	_log("\n== A: every active skill fires (real battle, dummy enemy with no element = 1x) ==")
	# Berserkers
	for id in ["berserker_01_angel_fire", "berserker_03_thin_water", "berserker_02_hulk_wood"]:
		var h := _hero(id)
		await _setup([h], _dummy(4000))
		_set_board(BASE)
		var from: int = Element.BEATS[h.element]
		var before_from: int = battle.board.count_type(from)
		var before_own: int = battle.board.count_type(h.element)
		await _use(0, "overrun_" + Element.display_name(h.element).to_lower())
		_check(battle.board.count_type(from) == 0 and battle.board.count_type(h.element) == before_own + before_from,
			"%s Overrun: all %d %s orbs -> %s" % [h.display_name, before_from, Element.display_name(from), Element.display_name(h.element)])

	var corvin := _hero("berserker_04_void_dark")
	await _setup([corvin], _dummy(4000, 2, true))
	await _use(0, "night_rend")
	var hp := _hps()
	_check(hp == [3810, 3810] and not battle.enemies[0].armor_up and not battle.enemies[1].armor_up, "Corvin Night Rend: hits EVERY enemy for 95 x 2 = 190, breaks armour -> %s" % [hp])

	var sol := _hero("berserker_05_solar_light")
	await _setup([sol], _dummy(4000))
	_set_board(BASE)
	await _use(0, "solar_flare")
	var row_light := true
	for x in Board.COLS:
		row_light = row_light and (battle.board.grid[x][Board.ROWS - 1] as Orb).orb_type == T.LIGHT
	_check(row_light and battle.team.boost_element == T.LIGHT and is_equal_approx(battle.team.boost_mult, 1.5), "Sol Solar Flare: bottom row -> Light, Light hunters x1.5 this turn")
	_set_board(ROWS_OF[T.LIGHT])
	await _turn()
	var want := roundi(95 * (last_cleared.get(T.LIGHT, 0) / 3.0) * DamageCalculator.combo_multiplier(last_combos) * 1.5)
	_check(battle.enemies[0].hp == 4000 - want and battle.team.boost_element == -1, "  ...the next turn hits x1.5 (%d), then the boost ends" % want)

	var vex := _hero("spectre_01_rogue_dark")
	await _setup([vex], _dummy(4000))
	await _use(0, "shadow_verdict")
	_check(battle.enemies[0].hp == 4000 - 440, "Vex Shadow Verdict: ATK 110 x 4 = 440 -> HP %d" % battle.enemies[0].hp)

	var joren := _hero("spectre_02_mage_fire")
	await _setup([joren], _dummy(4000, 1, true))
	await _use(0, "ember_lance")
	_check(battle.enemies[0].hp == 4000 - 550 and not battle.enemies[0].armor_up, "Joren Ember Lance: 110 x 5 = 550 straight through armour -> HP %d" % battle.enemies[0].hp)

	var wren := _hero("spectre_03_sniper_wood")
	await _setup([wren], _dummy(4000))
	await _use(0, "thorn_snipe")
	var e0: Enemy = battle.enemies[0]
	_check(e0.hp == 4000 - 330 and e0.vulnerable_turns == 2 and is_equal_approx(e0.vulnerable_mult, 1.25), "Wren Thorn Snipe: 110 x 3 = 330, target takes +25%% for 2 turns -> HP %d" % e0.hp)
	_set_board(ROWS_OF[T.WOOD])
	var hp0 := e0.hp
	await _turn()
	var base := DamageCalculator.attack_damage(110, last_cleared.get(T.WOOD, 0), last_combos, T.WOOD, T.NONE)
	_check(hp0 - e0.hp == roundi(base * 1.25), "  ...her next orb attack does %d x 1.25 = %d" % [base, hp0 - e0.hp])

	var kai := _hero("spectre_04_assassin_water")
	await _setup([kai], _dummy(4000))
	await _use(0, "undertow_strike")
	var a1: int = 4000 - battle.enemies[0].hp
	battle.enemies[0].hp = 1500
	_ready_skill(0)
	await _use(0, "")
	_check(a1 == 330 and battle.enemies[0].hp == 1500 - 550, "Kai Undertow Strike: 330 (x3), and 550 (x5) on a target below 50% HP")

	var lyra := _hero("spectre_05_infiltrator_light")
	await _setup([lyra], _dummy(4000, 1, true))
	_set_board(BASE)
	var light0: int = battle.board.count_type(T.LIGHT)
	await _use(0, "radiant_pierce")
	_check(battle.enemies[0].hp == 4000 - 330 and not battle.enemies[0].armor_up and battle.board.count_type(T.LIGHT) == light0 + 3,
		"Lyra Radiant Pierce: 330, breaks armour, +3 Light orbs (%d -> %d)" % [light0, battle.board.count_type(T.LIGHT)])

	# Titans (dummy ATK 100 so the cuts are easy to read)
	var bram := _hero("titan_01_shield_wood")
	await _setup([bram], _dummy(99999, 1, false, 100))
	await _use(0, "bulwark")
	var max_b: int = battle.team.max_hp
	await _no_match_turn()
	_check(battle.team.hp == max_b - 50, "Bram Bulwark: the enemy's 100 hits for 50 (team %d / %d)" % [battle.team.hp, max_b])

	var freya := _hero("titan_02_guardian_fire")
	await _setup([freya], _dummy(99999, 1, false, 100))
	await _use(0, "forge_guard")
	var max_f: int = battle.team.max_hp
	var s_ok: bool = battle.team.shields.size() == 1 and battle.team.shields[0]["attacks"] == 3
	await _no_match_turn()
	_check(s_ok and battle.team.hp == max_f - 65 and battle.enemies[0].hp == 99999 - 78, "Freya Forge Guard: 100 -> 65 taken, and she strikes back for 78 (3 attacks)")

	var rowan := _hero("titan_03_anchor_water")
	await _setup([rowan], _dummy(99999, 1, false, 100))
	battle.team.take_damage(300)
	var max_r: int = battle.team.max_hp
	await _use(0, "tidewall")
	var healed: int = battle.team.hp - (max_r - 300)
	var hp_r: int = battle.team.hp
	await _no_match_turn()
	_check(healed == roundi(max_r * 0.15) and battle.team.hp == hp_r - 60, "Rowan Tidewall: heals 15%% (%d), then the hit is 40%% less (100 -> 60)" % healed)

	var dmitri := _hero("titan_04_void_dark")
	# (Bram + Mira along so team HP stays above 50%: Iron Pact must not kick in here.)
	await _setup([dmitri, _hero("titan_01_shield_wood"), _hero("biotech_01_medic_water")], _dummy(99999, 2, false, 100))
	await _use(0, "gravity_well")
	var max_d: int = battle.team.max_hp
	await _no_match_turn()
	var first: int = max_d - battle.team.hp
	await _no_match_turn()
	var second: int = max_d - first - battle.team.hp
	await _no_match_turn()
	var third: int = max_d - first - second - battle.team.hp
	_check(first == 140 and second == 140 and third == 200, "Dmitri Gravity Well: 2 enemies x 100 hit for 70 each for 2 turns (%d, %d), then full again (%d)" % [first, second, third])

	var aurelia := _hero("titan_05_sanctum_light")
	await _setup([aurelia], _dummy(99999, 1, false, 100))
	battle.team.take_damage(100)
	var max_a: int = battle.team.max_hp
	await _use(0, "sanctuary")
	var hp_a: int = battle.team.hp
	await _no_match_turn()
	_check(hp_a == max_a - 100 + roundi(max_a * 0.1) and battle.team.hp == hp_a, "Aurelia Sanctuary: heals 10%%, and the next attack is blocked completely (team %d -> %d)" % [hp_a, battle.team.hp])

	# Biotechs
	var mira := _hero("biotech_01_medic_water")
	await _setup([mira], _dummy(99999))
	battle.team.take_damage(200)
	_set_board(BASE)
	var h0: int = battle.board.count_type(T.HEART)
	var max_m: int = battle.team.max_hp
	await _use(0, "mend")
	_check(battle.team.hp == mini(max_m - 200 + roundi(max_m * 0.3), max_m) and battle.board.count_type(T.HEART) == h0 + 3, "Mira Mend (CD5): heals 30%, +3 Hearts")

	var silas := _hero("biotech_02_splicer_wood")
	await _setup([silas], _dummy(99999))
	_set_board(BASE)
	var dark0: int = battle.board.count_type(T.DARK)
	var hearts0: int = battle.board.count_type(T.HEART)
	await _use(0, "spore_bloom")
	_check(battle.board.count_type(T.DARK) == 0 and battle.board.count_type(T.HEART) == hearts0 + dark0, "Silas Spore Bloom: all %d Dark orbs -> Hearts" % dark0)

	var ash := _hero("biotech_03_healer_fire")
	await _setup([ash], _dummy(99999))
	battle.team.take_damage(300)
	var max_s: int = battle.team.max_hp
	await _use(0, "cauterize")
	_check(battle.team.hp == max_s - 300 + roundi(max_s * 0.2) and battle.team.boost_element == T.FIRE and is_equal_approx(battle.team.boost_mult, 1.5),
		"Ash Cauterize: heals 20%, Fire hunters x1.5 this turn")

	var selene := _hero("biotech_04_shadow_dark")
	await _setup([selene], _dummy(99999, 1, false, 10))
	battle.team.take_damage(250)
	var max_n: int = battle.team.max_hp
	await _use(0, "night_bloom")
	var hp_n: int = battle.team.hp
	await _no_match_turn()
	_check(battle.team.regen_turns == 2 and battle.team.hp == hp_n - 10 + roundi(max_n * 0.12), "Selene Night Bloom: next turn starts with +12%% (%d), 2 heals left" % roundi(max_n * 0.12))

	var luca := _hero("biotech_05_radiant_light")
	await _setup([luca], _dummy(99999))
	_set_board(BASE)
	var hl0: int = battle.board.count_type(T.HEART)
	var mt0: float = battle.board.move_time
	await _use(0, "dawn_chorus")
	_check(battle.board.count_type(T.HEART) == hl0 + 4 and is_equal_approx(battle.board.move_time, mt0 + 2.0), "Luca Dawn Chorus: +4 Hearts, move time %.0f -> %.0f s this turn" % [mt0, battle.board.move_time])
	await _no_match_turn()
	_check(is_equal_approx(battle.board.move_time, mt0), "  ...back to %.0f s next turn" % mt0)
	await _shot_popup()


# ---------------------------------------------------------------- K: leaders

func _test_leaders() -> void:
	_log("\n== K: every leader skill (slot 1 only, never stacks) ==")
	var CR := CombatRules
	var fire := _hero("biotech_03_healer_fire")
	var water := _hero("spectre_04_assassin_water")
	var wood := _hero("spectre_03_sniper_wood")
	var light := _hero("titan_05_sanctum_light")
	var dark := _hero("titan_04_void_dark")
	var by_el := {T.FIRE: fire, T.WATER: water, T.WOOD: wood, T.LIGHT: light, T.DARK: dark}
	var foe := Enemy.new(_dummy(1000).enemies[0])

	for id in ["berserker_01_angel_fire", "berserker_03_thin_water", "berserker_02_hulk_wood"]:
		var L := _hero(id)
		var m: FighterData = by_el[L.element]
		var on := CR.leader_multiplier(L, m, [_g(L.element, 4)], 1)
		var off := CR.leader_multiplier(L, m, [_g(L.element, 3)], 1)
		var want: float = {&"leader_berserker": 2.0, &"leader_riptide": 1.75, &"leader_overgrowth": 1.75}[L.leader_skill]
		_check(is_equal_approx(on, want) and off == 1.0, "%s %s: 4+ %s in one group -> x%s (3 in a group: x%s)" % [L.display_name, Skills.display_name(L.leader_skill), Element.display_name(L.element), on, off])
	var drek_team := Team.new(_typed([_hero("berserker_02_hulk_wood")]))
	drek_team.hp = 100
	_check(CR.turn_heal(drek_team, 0, [_g(T.WOOD, 4)]) == roundi(drek_team.max_hp * 0.05), "  Overgrowth also heals 5% on that turn")

	var corvin := _hero("berserker_04_void_dark")
	var ct := Team.new(_typed([corvin]))
	var full := CR.leader_multiplier(corvin, dark, [], 1, null, ct)
	ct.hp = int(ct.max_hp * 0.4)
	var low := CR.leader_multiplier(corvin, dark, [], 1, null, ct)
	_check(is_equal_approx(full, 1.15) and is_equal_approx(low, 2.0) and CR.leader_multiplier(corvin, fire, [], 1, null, ct) == 1.0, "Corvin Bloodmoon: Dark x1.15, x2 below 50% team HP, others x1 (toned down from x1.5 / x2.25)")
	var sol := _hero("berserker_05_solar_light")
	_check(is_equal_approx(CR.leader_multiplier(sol, fire, [_g(T.LIGHT, 4), _g(T.LIGHT, 3)], 2), 1.75) and CR.leader_multiplier(sol, fire, [_g(T.LIGHT, 3), _g(T.LIGHT, 3)], 2) == 1.0,
		"Sol Zenith: 7 Light orbs in one turn (4 + 3) -> everyone x1.75; 6 -> x1 (needs 7 now, was 6)")
	var vex := _hero("spectre_01_rogue_dark")
	_check(CR.leader_multiplier(vex, fire, [], 4) == 1.0 and is_equal_approx(CR.leader_multiplier(vex, fire, [], 5), 1.5) and is_equal_approx(CR.leader_multiplier(vex, fire, [], 7), 2.5), "Vex Nightfall: x1.5 at 5 combos, x2.5 at 7")
	var joren := _hero("spectre_02_mage_fire")
	_check(is_equal_approx(CR.leader_multiplier(joren, fire, [], 5), 2.25) and CR.leader_multiplier(joren, fire, [], 4) == 1.0 and CR.leader_multiplier(joren, water, [], 5) == 1.0, "Joren Kindled Focus: 5+ combos -> Fire x2.25")
	var wren := _hero("spectre_03_sniper_wood")
	_check(is_equal_approx(CR.leader_multiplier(wren, fire, [], 1, foe, null, true), 1.75) and CR.leader_multiplier(wren, fire, [], 1, foe, null, false) == 1.0, "Wren Hunter's Mark: hits on the TAPPED enemy x1.75, untapped x1")
	var kai := _hero("spectre_04_assassin_water")
	foe.hp = 400
	var low_hit := CR.leader_multiplier(kai, fire, [], 1, foe)
	foe.hp = 600
	_check(is_equal_approx(low_hit, 2.0) and CR.leader_multiplier(kai, fire, [], 1, foe) == 1.0, "Kai Cold Precision: enemy below 50% HP -> x2")
	var lyra := _hero("spectre_05_infiltrator_light")
	_check(is_equal_approx(CR.leader_multiplier(lyra, light, [], 4), 1.75) and is_equal_approx(CR.leader_multiplier(lyra, fire, [], 4), 1.25) and CR.leader_multiplier(lyra, light, [], 3) == 1.0, "Lyra Halo Sight: 4+ combos -> Light x1.75, others x1.25")

	var base_hp := 470 + 350
	var pair := [_hero("titan_02_guardian_fire"), _hero("biotech_01_medic_water")]
	for L_id in ["titan_01_shield_wood", "titan_02_guardian_fire", "titan_03_anchor_water", "titan_04_void_dark", "titan_05_sanctum_light"]:
		var L := _hero(L_id)
		var team := Team.new(_typed([L, _hero("biotech_01_medic_water")]))
		var want_hp: float = {&"leader_titan": 1.3, &"leader_molten_ward": 1.2, &"leader_deep_current": 1.2, &"leader_iron_pact": 1.25, &"leader_dawn_aegis": 1.15}[L.leader_skill]
		_check(team.max_hp == roundi(base_hp * want_hp), "%s %s: team HP x%s (%d -> %d)" % [L.display_name, Skills.display_name(L.leader_skill), want_hp, base_hp, team.max_hp])
	_check(is_equal_approx(CR.leader_multiplier(_hero("titan_02_guardian_fire"), fire, [], 1), 1.3) and CR.leader_multiplier(_hero("titan_02_guardian_fire"), water, [], 1) == 1.0, "  Molten Ward: Fire hunters x1.3")
	var deep := Team.new(_typed([_hero("titan_03_anchor_water"), _hero("biotech_01_medic_water")]))
	_check(deep.total_rcv == roundi((26 + 46) * 1.5), "  Deep Current: team RCV x1.5 (%d)" % deep.total_rcv)
	var iron := Team.new(_typed([_hero("titan_04_void_dark")]))
	var iron_full := CR.leader_damage_taken(iron)
	iron.hp = int(iron.max_hp * 0.4)
	_check(iron_full == 1.0 and is_equal_approx(CR.leader_damage_taken(iron), 0.7), "  Iron Pact: below 50% team HP the team takes 30% less")
	_check(is_equal_approx(CR.leader_damage_taken(Team.new(_typed([_hero("titan_05_sanctum_light")]))), 0.85), "  Dawn Aegis: the team takes 15% less from every hit")

	var mira := _hero("biotech_01_medic_water")
	_check(is_equal_approx(CR.leader_multiplier(mira, fire, [_g(T.FIRE, 3), _g(T.WATER, 3)], 2), 1.5) and CR.leader_multiplier(mira, fire, [_g(T.FIRE, 3)], 1) == 1.0, "Mira Lifeline: 2+ elements -> x1.5 (1 element: x1)")
	var silas := _hero("biotech_02_splicer_wood")
	var st := Team.new(_typed([silas]))
	st.hp = 1
	_check(is_equal_approx(CR.leader_multiplier(silas, wood, [_g(T.HEART, 3)], 1), 1.5) and CR.leader_multiplier(silas, wood, [], 1) == 1.0 and CR.turn_heal(st, 3, [_g(T.HEART, 3)]) == roundi(st.total_rcv * 1.5),
		"Silas Rootwork: Hearts matched -> Wood x1.5 (was x1.75) and Hearts heal x1.5")
	var ash := _hero("biotech_03_healer_fire")
	_check(Team.new(_typed([ash])).total_rcv == roundi(46 * 1.3) and is_equal_approx(CR.leader_multiplier(ash, fire, [_g(T.HEART, 3)], 1), 1.5), "Ash Second Wind: team RCV x1.3; Hearts matched -> Fire x1.5 (was x1.75)")
	var selene := _hero("biotech_04_shadow_dark")
	_check(is_equal_approx(CR.leader_multiplier(selene, dark, [_g(T.FIRE, 3), _g(T.WATER, 3), _g(T.DARK, 3)], 3), 2.0) and CR.leader_multiplier(selene, dark, [_g(T.FIRE, 3), _g(T.DARK, 3)], 2) == 1.0,
		"Selene Umbral Pact: 3+ elements -> Dark x2 (2 elements: x1); team RCV x1.3")
	var luca := _hero("biotech_05_radiant_light")
	_check(is_equal_approx(CR.move_time(Team.new(_typed([luca]))), 6.0) and is_equal_approx(CR.leader_multiplier(luca, fire, [_g(T.HEART, 3)], 1), 1.3), "Luca Radiance: +1 s to move; Hearts matched -> everyone x1.3")
	var not_leader := CR.leader_multiplier(_hero("biotech_01_medic_water"), fire, [_g(T.FIRE, 4)], 1)
	_check(not_leader == 1.0, "only slot 1 counts: Kaela in slot 2 behind Mira gives no Furnace Heart bonus on 4 Fire (x%s)" % not_leader)
	pair.clear()


# ---------------------------------------------------------------- P: passives

func _test_passives() -> void:
	_log("\n== P: every passive ==")
	var CR := CombatRules
	var g4 := [_g(T.FIRE, 4)]
	_check(is_equal_approx(CR.passive_multiplier(_hero("berserker_01_angel_fire", 1), g4, 1, null, false), 1.5), "Cleave: 4+ group x1.5")
	_check(CR.act_start_turns(_hero("berserker_01_angel_fire", 2)) == 3, "Skill Boost: Overrun starts an Act at 3 turns instead of 4")
	var joren3 := _hero("spectre_02_mage_fire", 3)
	var sq := [_square(T.FIRE)]
	_check(is_equal_approx(CR.passive_multiplier(joren3, sq, 1, null, false), 2.5) and CR.ignores_armor(joren3, sq), "Breaker: 3x3 square x2.5, through armour")
	var te := Team.new(_typed([_hero("berserker_03_thin_water", 2), _hero("biotech_01_medic_water", 1)]))
	_check(is_equal_approx(CR.move_time(te), 6.0), "Time Extend (TEAM): 6 s, and two hunters with it still give 6 s (doesn't stack)")
	var rg := Team.new(_typed([_hero("biotech_01_medic_water"), _hero("berserker_02_hulk_wood", 2)]))
	rg.hp = 1
	_check(CR.turn_heal(rg, 0, [_g(T.WOOD, 3)]) == roundi(rg.max_hp * 0.04) and CR.turn_heal(rg, 0, [_g(T.FIRE, 3)]) == 0, "Regrowth: Drek attacks -> heal 4%% (%d)" % roundi(rg.max_hp * 0.04))
	var ct := Team.new(_typed([_hero("biotech_01_medic_water"), _hero("berserker_04_void_dark", 1)]))
	ct.hp = int(ct.max_hp * 0.4)
	_check(is_equal_approx(CR.passive_multiplier(_hero("berserker_04_void_dark", 1), [], 1, null, false, ct), 1.3), "Bloodlust: below 50% team HP x1.3")
	var lyra3 := _hero("spectre_05_infiltrator_light", 3)
	_check(is_equal_approx(CR.passive_multiplier(lyra3, [_g(T.LIGHT, 5)], 1, null, false), 1.3) and CR.passive_multiplier(lyra3, [_g(T.LIGHT, 4)], 1, null, false) == 1.0, "Orb Enhance: 5+ group x1.3 (4: x1)")
	var vex3 := _hero("spectre_01_rogue_dark", 3)
	var foe := Enemy.new(_dummy(1000).enemies[0])
	foe.hp = 400
	_check(is_equal_approx(CR.passive_multiplier(vex3, [], 1, null, true), 2.0) and is_equal_approx(CR.passive_multiplier(vex3, [], 7, null, false), 2.0) and is_equal_approx(CR.passive_multiplier(vex3, [], 1, foe, false), 1.5),
		"Ambush x2 (first attack), Combo Boost x2 (7+ combos), Finisher x1.5 (enemy below 50%)")
	var fr := Team.new(_typed([_hero("titan_02_guardian_fire", 2)]))
	_check(fr.max_hp == roundi(470 * 1.15 * 1.2), "HP Up: Freya's HP +15%% in battle (%d with Molten Ward)" % fr.max_hp)
	var rw := Team.new(_typed([_hero("titan_03_anchor_water", 2)]))
	_check(rw.total_rcv == roundi(26 * 1.25 * 1.5), "RCV Up: Rowan's RCV +25%% in battle (%d with Deep Current)" % rw.total_rcv)
	var oh := Team.new(_typed([_hero("biotech_01_medic_water", 2)]))
	oh.hp = 1
	_check(CR.turn_heal(oh, 5, [_g(T.HEART, 5)]) == roundi(oh.total_rcv * 5 / 3.0 * 1.5), "Overflow Heal (TEAM): 5 Hearts in one group heal x1.5")
	var fa := Team.new(_typed([_hero("biotech_03_healer_fire", 3), _hero("biotech_03_healer_fire", 3)]))
	_check(is_equal_approx(CR.passive_multiplier(_hero("berserker_01_angel_fire"), [], 1, null, false, fa), 1.1), "Fire ATK Up (TEAM): Fire hunters x1.1, and two Ash Morenos still give x1.1 (doesn't stack)")

	# Real battle passives
	await _setup([_hero("berserker_04_void_dark", 3)], _dummy(99999, 1, false, 99999))
	await _no_match_turn()
	var survived: bool = battle.team.hp == 1 and battle.team.last_stand_used and not battle.result_panel.visible
	await _shot("sk_last_stand")
	await _no_match_turn()
	_check(survived and battle.result_panel.visible and battle.team.is_defeated(), "Last Stand (TEAM): a fatal hit leaves the team at 1 HP once per fight; the next one defeats it")

	await _setup([_hero("titan_01_shield_wood", 3), _hero("titan_03_anchor_water", 1)], _dummy(99999, 1, false, 100))
	var m0: int = battle.team.max_hp
	await _no_match_turn()
	_check(m0 - battle.team.hp == 90, "Damage Resist (TEAM): 100 -> 90; Bram and Rowan both have it, still only 10%% (took %d)" % (m0 - battle.team.hp))

	await _setup([_hero("titan_02_guardian_fire", 3)], _dummy(99999, 1, false, 10))
	await _no_match_turn()
	var high: int = 99999 - battle.enemies[0].hp
	battle.team.hp = int(battle.team.max_hp * 0.4)
	var e_hp: int = battle.enemies[0].hp
	await _no_match_turn()
	_check(high == 78 and e_hp - battle.enemies[0].hp == 156, "Counter 78, and Retaliation doubles it (156) below 50% team HP")

	await _setup([_hero("biotech_02_splicer_wood", 2)], _dummy(99999))
	battle.team.skill_turns[0] = 4
	_set_board(HEART5)
	await _turn()
	_check(battle.team.skill_turns[0] == 2, "Heart Charge: 5+ Hearts -> skill charges 1 extra turn (4 -> %d)" % battle.team.skill_turns[0])

	await _setup([_hero("biotech_01_medic_water", 3), _hero("berserker_01_angel_fire")], _dummy(99999))
	battle.team.skill_turns[1] = 4
	_ready_skill(0)
	await _use(0, "")
	_check(battle.team.skill_turns[1] == 3, "Field Medic: Mend charges every ally by 1 (4 -> %d)" % battle.team.skill_turns[1])


# ---------------------------------------------------------------- B: balance

func _test_balance() -> void:
	_log("\n== B: balance with the new skills ==")
	var act: ActData = StarMap.ACTS[0]
	var roles := ["BERSERKER", "TITAN", "SPECTRE", "BIOTECH"]
	var by_role := {}
	for id in Catalog.IDS:
		var c := Catalog.template(id)
		var total := 0
		var all_ok := true
		for f in act.fights:
			var team := BalanceSim.leveled_team([c, c, c], f.expected_level)
			var foes := _neutral(f.enemies)
			total += BalanceSim.turns_to_win(foes, team, "GOOD")
			all_ok = all_ok and BalanceSim.avg_survives(foes, team, "GOOD" if f.enemies[0].armored else "AVERAGE")
		var key: String = roles[c.role]
		if not by_role.has(key):
			by_role[key] = []
		by_role[key].append(total)
		_log("INFO  3x %-13s (%s leads): Act 1 in %d turns (good play)%s" % [c.display_name, Skills.display_name(c.leader_skill), total, "" if all_ok else "  LOSES A FIGHT"])
	for r in roles:
		var arr: Array = by_role[r]
		var avg := float(arr.reduce(func(a, b): return a + b)) / arr.size()
		_check(avg >= 15.0 and avg <= 17.5, "%s teams of 3: Act 1 in %d-%d turns, average %.1f (target 15-17)" % [r, arr.min(), arr.max(), avg])
	# Starters: the tutorial is still the same fight for all three.
	var f1: FightData = act.fights[0]
	var res := []
	for id in Profile.STARTERS:
		var team := BalanceSim.leveled_team([Catalog.template(id)], 1)
		res.append([BalanceSim.turns_to_win(f1.enemies, team, "GOOD"), BalanceSim.turns_to_win(f1.enemies, team, "AVERAGE")])
	_check(res[0] == res[1] and res[1] == res[2], "the 3 starters still win the tutorial in the same turns: %s" % [res])
	# Resolve: the biggest skill hits can't take a boss below 50% in one turn.
	var boss_d: FighterData = act.fights[7].enemies[0]
	var e := Profile.ECONOMY
	for id in ["spectre_02_mage_fire", "spectre_04_assassin_water", "berserker_04_void_dark"]:
		var c: FighterData = CombatRules.at_level(Catalog.template(id), 30).duplicate()
		var m: float = e.rarity_stat_mult[5] * (1.0 + e.evo_stat_bonus * 2)
		c.atk = roundi(c.atk * m)
		var boss := Enemy.new(boss_d)
		var mult: float = {"spectre_02_mage_fire": tu.ember_lance_atk_mult, "spectre_04_assassin_water": tu.undertow_low_atk_mult, "berserker_04_void_dark": tu.night_rend_atk_mult}[id]
		var raw := CombatRules.skill_hit(c, boss, mult)
		var g := BalanceSim.great_turn([boss_d], _typed([c, c, c]))
		var dealt := boss.take_hit(raw, true) + boss.take_hit(raw, true)
		_check(dealt <= ceili(boss_d.max_hp * 0.5), "Resolve vs %s Lv30 Singularity, both evolutions: skill hit %d raw (x2 tried) -> Emberfang-9 loses only %d of %d this turn" % [c.display_name, raw, dealt, boss_d.max_hp])
		if g["left"] == 0:
			_check(false, "a great turn killed the boss")
	var lv1: FighterData = Catalog.template("spectre_02_mage_fire")
	var mb: FighterData = act.fights[2].enemies[0]
	var lance := CombatRules.skill_hit(lv1, Enemy.new(mb), tu.ember_lance_atk_mult)
	_check(lance * 2 < mb.max_hp, "the biggest Lv1 skill (Ember Lance %d, even x2 element = %d) is far from one-shotting the smallest mini-boss (%d HP)" % [lance, lance * 2, mb.max_hp])


# ---------------------------------------------------------------- helpers

func _hero(id: String, unlocked := 0) -> FighterData:
	var c: FighterData = Catalog.template(id).duplicate()
	c.passives_unlocked = unlocked
	return c


func _g(type: int, n: int) -> Dictionary:
	return BalanceSim.group(type, n)


func _square(type: int) -> Dictionary:
	var cells := []
	for y in 3:
		for x in 3:
			cells.append(Vector2i(x, y))
	return {"type": type, "cells": cells}


func _typed(list: Array) -> Array[FighterData]:
	var out: Array[FighterData] = []
	for d in list:
		out.append(d)
	return out


func _neutral(enemies: Array) -> Array:
	var o := []
	for d in enemies:
		var c: FighterData = d.duplicate()
		c.element = Element.Type.NONE
		o.append(c)
	return o


## A test fight: `count` dummies with no element (every hit is 1x).
func _dummy(hp: int, count := 1, armored := false, atk := 10) -> FightData:
	var f := FightData.new()
	f.display_name = "SKILL TEST"
	for k in count:
		var d := FighterData.new()
		d.display_name = "TEST DUMMY"
		d.element = Element.Type.NONE
		d.role = FighterData.Role.ENEMY
		d.max_hp = hp
		d.atk = atk
		d.armored = armored
		d.body_color = Color(0.4, 0.4, 0.45)
		d.figure_height = 280.0
		d.figure_width = 240.0
		f.enemies.append(d)
	return f


func _setup(members: Array, fight: FightData) -> void:
	battle.set_team(members)
	battle.test_fight_override = fight
	battle._start_battle(0, battle.StartMode.NEW_ACT)
	await _frames(3)
	_ready_skill(0)


func _ready_skill(i: int) -> void:
	battle.team.skill_turns[i] = 0
	battle._refresh_team_ui()


## Tap card i, press USE, screenshot the animation, wait until the skill is done.
func _use(i: int, shot_name: String) -> void:
	var view: FighterView = battle.team_views[i]
	var p := view.get_global_transform_with_canvas() * view.hit_rect().get_center()
	_press(p)
	await _frames(1)
	_release(p)
	await _frames(2)
	if not battle.skill_popup.visible:
		_check(false, "skill pop-up did not open")
		return
	var b: Button = battle.skill_popup.use_button
	var bp := b.get_global_rect().get_center()
	_press(bp)
	await _frames(1)
	_release(bp)
	if shot_name != "":
		await get_tree().create_timer(0.42).timeout
		await _shot("sk_" + shot_name)
	var t := 0.0
	while battle._busy and t < 6.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	await _frames(2)


func _turn() -> void:
	var p: Vector2 = battle.board.get_global_transform_with_canvas() * battle.board.cell_center(Vector2i(5, 0))
	_press(p)
	await _frames(1)
	_release(p)
	await _frames(1)
	var t := 0.0
	await _frames(1)
	while t < 30.0:
		if battle.board.state == Board.State.READY or battle.result_panel.visible:
			return
		await get_tree().process_frame
		t += get_process_delta_time()
	_check(false, "turn did not finish")


func _no_match_turn() -> void:
	_set_board(BASE)
	await _turn()


func _hps() -> Array:
	var out := []
	for e in battle.enemies:
		out.append(e.hp)
	return out


func _shot_popup() -> void:
	await _setup([_hero("spectre_03_sniper_wood", 1)], _dummy(4000))
	var view: FighterView = battle.team_views[0]
	var p := view.get_global_transform_with_canvas() * view.hit_rect().get_center()
	_press(p)
	await _frames(1)
	_release(p)
	await _frames(3)
	_check(battle.skill_popup.visible and battle.skill_popup._title.text.contains("WREN"), "tapping a card shows the character's OWN active, leader (with name) and passives")
	await _shot("sk_popup_wren")
	battle.skill_popup.visible = false
	await _frames(2)


func _set_board(rows: Array) -> void:
	var map := {"F": T.FIRE, "W": T.WATER, "G": T.WOOD, "L": T.LIGHT, "D": T.DARK, "H": T.HEART}
	for y in Board.ROWS:
		for x in Board.COLS:
			(battle.board.grid[x][y] as Orb).setup(map[rows[y][x]])


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
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
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
	var f := FileAccess.open(ProjectSettings.globalize_path("res://tests/report_skills.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	get_tree().quit(fails)
