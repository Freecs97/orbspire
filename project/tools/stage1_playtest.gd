extends SceneTree
## Stage 1 balance playtest (2026-11-18). Developer tool, runs headless:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --quit-after 30 -s res://tools/stage1_playtest.gd
## Writes tools/stage1_playtest_report.txt and prints PASS / FAIL lines.
##
## 1. XP table (new curve, level caps).
## 2. Recruit odds by Act band + 20,000 simulated pulls per band (rarity gates).
## 3. 2,000 full Act 1 campaigns through the REAL Profile code (rewards, XP,
##    Essence, Keys), spending every Credit on Basic Recruits and crafting
##    whatever Essence allows: what does a player own at the end of Act 1?
## 4. Farming: replay the Act 1 boss after clearing it - how long to the Lv15 cap?
## 5. Top end: can a max-level Singularity team one-shot Emberfang-9?

const RUNS := 2000

var out := PackedStringArray()
var fails := 0


func _init() -> void:
	var p: ProgressionTuning = load("res://data/progression.tres")
	var e: EconomyTuning = load("res://data/economy.tres")
	var act1: ActData = load("res://data/acts/act_01.tres")
	_xp_table(p)
	_odds(e)
	_campaigns(act1, e)
	_farming(act1, p)
	_top_end(act1, e)
	out.append("\n%s - %d failure(s)" % ["ALL PASSED" if fails == 0 else "FAILURES", fails])
	var f := FileAccess.open("res://tools/stage1_playtest_report.txt", FileAccess.WRITE)
	f.store_string("\n".join(out))
	f.close()
	print("\n".join(out))
	quit()


func _check(ok: bool, what: String) -> void:
	out.append(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


func _xp_table(p: ProgressionTuning) -> void:
	out.append("== 1. XP to next level (50 x level, steeper from Lv10) ==")
	var row := PackedStringArray()
	for l in range(1, 30):
		row.append("Lv%d->%d: %d" % [l, l + 1, p.xp_to_next(l)])
	out.append("  " + ", ".join(row))
	out.append("  Total XP to Lv10: %d   Lv10->Lv15: %d   Lv15->Lv30: %d" % [p.total_xp_for(10), p.total_xp_for(15) - p.total_xp_for(10), p.total_xp_for(30) - p.total_xp_for(15)])
	out.append("  Level caps: Stage 1 = Lv%d, Stage 2 = Lv%d, Stage 3 = Lv%d" % [p.level_cap(1), p.level_cap(2), p.level_cap(3)])
	out.append("  Stats: x1.0 at Lv1 -> x%.2f at Lv15 -> x%.1f at Lv30 (was x3.0 at Lv30)" % [p.stat_mult(15), p.stat_mult(30)])


func _odds(e: EconomyTuning) -> void:
	out.append("\n== 2. Recruit odds by Act (Scrap / Alloy / Forged / Prime / Ascendant / Singularity) ==")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var prof := Profile.new({})
	for act in [1, 2, 3, 5, 7]:
		out.append("  Act %d (band %d):" % [act, e.band_for_act(act) + 1])
		var best := -1
		for tier in 4:
			var odds := e.odds_for(tier, act)
			out.append("    %-9s %s" % ["Key" if tier == 3 else e.recruit_names[tier], odds])
			var seen := [0, 0, 0, 0, 0, 0]
			for k in 20000:
				seen[prof.roll_rarity(odds)] += 1
			for r in 6:
				if seen[r] > 0:
					best = maxi(best, r)
			if tier < 3 and act <= 2:
				_check(odds[0] + odds[1] >= 85 and odds[3] == 0 and odds[4] == 0 and odds[5] == 0,
					"Act %d %s: Scrap + Alloy = %d%%, no Prime or better" % [act, e.recruit_names[tier], odds[0] + odds[1]])
		var allowed := 2 if act < 3 else (3 if act < 5 else (4 if act < 7 else 5))
		_check(best <= allowed, "Act %d: 80,000 simulated pulls, best rarity seen = %s (allowed: up to %s)" % [act, e.rarity_names[best], e.rarity_names[allowed]])
	for act in range(1, 11):
		for tier in 3:
			if e.odds_for(tier, act)[5] > 0:
				_check(false, "Singularity from a Credit Recruit at Act %d" % act)
	_check(true, "Singularity is never in a Credit Recruit table (Key pulls only, from Act 7)")


func _campaigns(act1: ActData, e: EconomyTuning) -> void:
	out.append("\n== 3. %d full Act 1 campaigns (real Profile code; every Credit spent on Basic Recruits) ==" % RUNS)
	var by_rarity := [0, 0, 0, 0, 0, 0]
	var any_prime := 0
	var any_sing := 0
	var forged_counts := {}
	var credits_total := 0
	var pulls_total := 0
	var crafted := 0
	var keys_total := 0
	var lv_before_boss := []
	var lv_after := []
	for run in RUNS:
		var prof := Profile.new({})
		prof.ensure_start()
		var credits_earned := 0
		for i in 8:
			if i == 7:
				lv_before_boss.append(prof.unit(prof.data["team"][0])["level"])
			var r := prof.fight_rewards(act1.fights[i], 1, true, prof.team_uids(3), i == 7)
			credits_earned += r["credits"]
			while prof.can_recruit(0) == "":
				prof.recruit(0)
				pulls_total += 1
			for id in prof.data["essence"].keys():
				while prof.can_craft(id) == "":
					prof.craft(id)
					crafted += 1
		keys_total += prof.data["keys"]
		while prof.can_recruit(3) == "":   # spend the Act 1 clear Key too
			prof.recruit(3)
		lv_after.append(prof.unit(prof.data["team"][0])["level"])
		credits_total += credits_earned
		var forged := 0
		var prime := false
		var sing := false
		for u in prof.data["units"].slice(3):   # everything except the story trio
			by_rarity[u["rarity"]] += 1
			forged += 1 if u["rarity"] == 2 else 0
			prime = prime or u["rarity"] >= 3
			sing = sing or u["rarity"] == 5
		forged_counts[forged] = int(forged_counts.get(forged, 0)) + 1
		any_prime += 1 if prime else 0
		any_sing += 1 if sing else 0
	var total := 0
	for n in by_rarity:
		total += n
	var parts := PackedStringArray()
	for r in 6:
		parts.append("%s %.1f%%" % [e.rarity_names[r], 100.0 * by_rarity[r] / maxi(total, 1)])
	out.append("  Credits earned in Act 1: %d on average -> %.1f Basic Recruits, %.2f Essence crafts, %.1f Keys per run" % [
		credits_total / RUNS, float(pulls_total) / RUNS, float(crafted) / RUNS, float(keys_total) / RUNS])
	out.append("  Characters gained (Recruits + crafts + the Act 1 Key): %s" % ", ".join(parts))
	var fk := forged_counts.keys()
	fk.sort()
	var fparts := PackedStringArray()
	for k in fk:
		fparts.append("%d Forged: %.1f%%" % [k, 100.0 * forged_counts[k] / RUNS])
	out.append("  Forged characters gained per run: %s" % ", ".join(fparts))
	_check(any_sing == 0, "no run finishes Act 1 with a Singularity (%d of %d)" % [any_sing, RUNS])
	_check(any_prime == 0, "no run finishes Act 1 with a Prime or better (%d of %d)" % [any_prime, RUNS])
	_check(float(by_rarity[0] + by_rarity[1]) / maxi(total, 1) >= 0.6, "most new characters are Scrap / Alloy")
	lv_before_boss.sort()
	lv_after.sort()
	_check(lv_after[0] >= 9 and lv_after[-1] <= 11, "story team level: Lv%d before the boss, Lv%d after it (target about Lv10, cap Lv15)" % [lv_before_boss[0], lv_after[0]])
	_check(keys_total == RUNS, "exactly 1 Key per run (first Act 1 clear only, bosses drop none)")


func _farming(act1: ActData, p: ProgressionTuning) -> void:
	out.append("\n== 4. Farming after Act 1 (replay fights, full team XP) ==")
	var prof := Profile.new({})
	prof.ensure_start()
	for i in 8:
		prof.fight_rewards(act1.fights[i], 1, true, prof.team_uids(3), i == 7)
	var lead := prof.unit(prof.data["team"][0])
	var replays := 0
	while lead["level"] < p.level_cap(1) and replays < 500:
		prof.fight_rewards(act1.fights[7], 1, true, prof.team_uids(3), true)
		replays += 1
	out.append("  Replaying Emberfang-9 from Lv10: %s" % ("Lv15 cap after %d boss replays" % replays if lead["level"] >= 15 else "still Lv%d after 500 replays" % lead["level"]))
	_check(replays >= 15, "reaching the Lv15 cap in Act 1 takes %d+ boss replays (XP halves once you are 3+ levels above the fight)" % replays)
	var r := prof.fight_rewards(act1.fights[0], 1, true, prof.team_uids(3), false)
	out.append("  Fight 1 replay at Lv%d: %d XP of %d (fight is Lv%d)" % [lead["level"], r["xp"], act1.fights[0].xp, act1.fights[0].expected_level])
	_check(r["xp"] <= act1.fights[0].xp / 4, "low-level fights give 25% or less (10+ levels below), 0% at 15+")
	prof.data["cores"] = 5
	var before: int = lead["xp"]
	_check(not prof.use_core(lead["uid"]) and lead["xp"] == before, "Training Cores can't push past the Lv15 cap")


func _top_end(act1: ActData, e: EconomyTuning) -> void:
	out.append("\n== 5. Top end vs Emberfang-9 (%d HP, armoured) - one GREAT turn: 6 combos, 5 Fire + 3 of every colour ==" % act1.fights[7].enemies[0].max_hp)
	var boss: Array = act1.fights[7].enemies
	# A copy with huge HP measures the TRUE damage of the turn (the real boss stops counting at 0 HP).
	var dummy: FighterData = boss[0].duplicate()
	dummy.max_hp = 999999
	var cases := [["3 Singularity, Lv15 (Stage 1 cap = max level today)", 15, 1.0], ["3 Singularity, Lv30, both evolutions (+21%)", 30, 1.21]]
	for c in cases:
		var best_raw := 0
		var best_left := 99999
		var best_id := ""
		for id in Catalog.IDS:
			var team: Array[FighterData] = []
			for k in 3:
				var f: FighterData = CombatRules.at_level(Catalog.template(id), c[1]).duplicate()
				var m: float = e.rarity_stat_mult[5] * c[2]
				f.max_hp = roundi(f.max_hp * m)
				f.atk = roundi(f.atk * m)
				f.passives_unlocked = 1
				team.append(f)
			var raw := BalanceSim.great_turn([dummy], team, false)
			var held := BalanceSim.great_turn(boss, team, true)
			if raw["dealt"] > best_raw:
				best_raw = raw["dealt"]
				best_id = id
			best_left = mini(best_left, held["left"])
		out.append("  %s: strongest team (%s x3) deals %d raw -> %s; with Resolve the boss keeps at least %d HP" % [c[0], Catalog.display_name(best_id),
			best_raw, "ONE-SHOT without Resolve" if best_raw >= boss[0].max_hp else "not a one-shot even without Resolve", best_left])
		_check(best_left > 0, "%s can't one-shot Emberfang-9" % c[0])
	# One max Singularity in a normal end-of-Act-1 team.
	var mixed: Array[FighterData] = []
	var lead: FighterData = CombatRules.at_level(Catalog.template("berserker_01_angel_fire"), 30).duplicate()
	lead.atk = roundi(lead.atk * e.rarity_stat_mult[5] * 1.21)
	mixed.append(lead)
	for id in ["biotech_01_medic_water", "titan_01_shield_wood"]:
		mixed.append(CombatRules.at_level(Catalog.template(id), 8))
	var one := BalanceSim.great_turn([dummy], mixed, false)
	var one_held := BalanceSim.great_turn(boss, mixed, true)
	out.append("  ONE Lv30 evolved Singularity (Kaela Rynn, leading) + Lv8 Forged Biotech / Titan: %d true damage vs %d HP (%s without Resolve)" % [
		one["dealt"], boss[0].max_hp, "one-shot" if one["dealt"] >= boss[0].max_hp else "no one-shot"])
	_check(one_held["left"] > 0, "a single max Singularity can't one-shot Emberfang-9 (boss keeps %d HP thanks to Resolve)" % one_held["left"])
	# Same turn with Lv15 Singularity (the most anyone can have until evolution is built).
	var now: Array[FighterData] = [CombatRules.at_level(Catalog.template("berserker_01_angel_fire"), 15).duplicate()]
	now[0].atk = roundi(now[0].atk * e.rarity_stat_mult[5])
	now.append(mixed[1])
	now.append(mixed[2])
	var one_now := BalanceSim.great_turn([dummy], now, false)
	out.append("  ONE Lv15 Singularity Kaela Rynn (max today) + the same team: %d true damage vs %d HP" % [one_now["dealt"], boss[0].max_hp])
	_check(one_now["dealt"] < boss[0].max_hp, "today's best single Singularity (Lv15) can't one-shot Emberfang-9 even without Resolve")
