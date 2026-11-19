extends SceneTree
## Stage 2 balance check (run: --headless --path . --quit-after 60 -s res://tools/stage2_sim.gd)
##
## 1. ARCHETYPES: each of the 4 types (Fire, Forged) SOLO against Act 1 fights 1-3
##    with the enemy made element-neutral, at the fight's expected level.
##    Shows Lv1 stats, turns to win (good / average) and whether average play survives.
## 2. STARTERS: Kaela / Iris / Drek solo in the real tutorial fight (fight 1).
##    All three must give the SAME result.
## 3. RAMP: the real Act 1 with a Forged starter, + 1 Scrap after fight 1,
##    + 2 Scrap after fight 2 (every possible Scrap pick), at expected levels.
## Writes tools/stage2_sim_report.txt.

const ACT1 := "res://data/acts/act_01.tres"
const STARTERS := ["berserker_01_angel_fire", "berserker_03_thin_water", "berserker_02_hulk_wood"]
const FIRE_OF_TYPE := ["berserker_01_angel_fire", "titan_02_guardian_fire", "spectre_02_mage_fire", "biotech_03_healer_fire"]
const ROLES := ["BERSERKER", "TITAN", "SPECTRE", "BIOTECH"]

var out := PackedStringArray()


func _init() -> void:
	var act: ActData = load(ACT1)
	var econ: EconomyTuning = load("res://data/economy.tres")
	_log("== 1. ARCHETYPES: Lv1 Forged stats, then SOLO vs Act 1 fights 1-3 (enemy made element-neutral)")
	for id in FIRE_OF_TYPE:
		var t := Catalog.template(id)
		_log("%-10s Lv1  HP %d  ATK %d  RCV %d" % [ROLES[t.role], t.max_hp, t.atk, t.rcv])
	for id in FIRE_OF_TYPE:
		var t := Catalog.template(id)
		var line := "%-10s" % ROLES[t.role]
		for i in 3:
			var f: FightData = act.fights[i]
			var team := _team([t], [2], f.expected_level, econ)
			var foes := _neutral(f.enemies)
			line += " | F%d good %2d avg %2d %s" % [i + 1, BalanceSim.turns_to_win(foes, team, "GOOD"), BalanceSim.turns_to_win(foes, team, "AVERAGE"),
				"survives" if BalanceSim.avg_survives(foes, team) else "DIES   "]
		_log(line)
	_log("")
	_log("== 1b. ARCHETYPES in a team: 3 of the same type (Fire, Forged) vs the whole of Act 1 (neutral enemies), good-play turns")
	for id in FIRE_OF_TYPE:
		var t := Catalog.template(id)
		var turns := []
		var all_ok := true
		for f in act.fights:
			var team := _team([t, t, t], [2, 2, 2], f.expected_level, econ)
			var foes := _neutral(f.enemies)
			turns.append(BalanceSim.turns_to_win(foes, team, "GOOD"))
			all_ok = all_ok and BalanceSim.avg_survives(foes, team, "GOOD" if f.enemies[0].armored else "AVERAGE")
		_log("%-10s x3  turns %s  total %d  %s" % [ROLES[t.role], turns, turns.reduce(func(a, b): return a + b), "survives all" if all_ok else "LOSES SOME"])
	_log("")
	_log("== 2. STARTERS solo in the tutorial (Act 1 fight 1, real enemy), Forged Lv1")
	var f1: FightData = act.fights[0]
	for id in STARTERS:
		var t := Catalog.template(id)
		var team := _team([t], [2], f1.expected_level, econ)
		_log("%-12s %-16s HP %d ATK %d RCV %d | vs %s: good %d, avg %d, %s" % [t.display_name, t.title, t.max_hp, t.atk, t.rcv, f1.display_name,
			BalanceSim.turns_to_win(f1.enemies, team, "GOOD"), BalanceSim.turns_to_win(f1.enemies, team, "AVERAGE"),
			"survives" if BalanceSim.avg_survives(f1.enemies, team) else "DIES"])
	_log("")
	_log("== 3. RAMP: Forged starter, + Scrap drop 1 after fight 1 (a character of the element that covers the")
	_log("   starter's weakness), + Scrap drop 2 after fight 2 (any of the 20). Every possible pair is played.")
	for sid in STARTERS:
		var s := Catalog.template(sid)
		var worst := []
		var fails := 0
		var runs := 0
		var cover := Element.beaten_by(act.fights[-1].enemies[0].element)   # strong vs the Act boss (Water in Act 1)
		for a in Catalog.IDS.filter(func(x: String) -> bool: return Catalog.template(x).element == cover):
			for b in Catalog.IDS:
				runs += 1
				var ok := true
				for i in act.fights.size():
					var f: FightData = act.fights[i]
					var members := [s]
					var rar := [2]
					if i >= 1:
						members.append(Catalog.template(a))
						rar.append(0)
					if i >= 2:
						members.append(Catalog.template(b))
						rar.append(0)
					var team := _team(members, rar, f.expected_level, econ)
					var mode := "GOOD" if f.enemies[0].armored or i == 0 else "AVERAGE"
					if not BalanceSim.avg_survives(f.enemies, team, mode):
						ok = false
						if worst.size() < 6:
							worst.append("F%d with %s + %s" % [i + 1, Catalog.display_name(a), Catalog.display_name(b)])
				if not ok:
					fails += 1
		_log("%-12s %d / %d team draws clear all of Act 1 (good play on fight 1 + mini-bosses + boss, average elsewhere). Fails e.g.: %s" % [s.display_name, runs - fails, runs, worst])
	var f := FileAccess.open("res://tools/stage2_sim_report.txt", FileAccess.WRITE)
	f.store_string("\n".join(out))
	f.close()
	quit()


func _team(members: Array, rarities: Array, level: int, econ: EconomyTuning) -> Array[FighterData]:
	var t: Array[FighterData] = []
	for k in members.size():
		var d: FighterData = CombatRules.at_level(members[k], level).duplicate()
		var m: float = econ.rarity_stat_mult[rarities[k]]
		d.max_hp = roundi(d.max_hp * m)
		d.atk = roundi(d.atk * m)
		d.rcv = roundi(d.rcv * m)
		t.append(d)
	return t


func _neutral(enemies: Array) -> Array:
	var o := []
	for e in enemies:
		var c: FighterData = e.duplicate()
		c.element = Element.Type.NONE
		o.append(c)
	return o


func _log(s: String) -> void:
	out.append(s)
	print(s)
