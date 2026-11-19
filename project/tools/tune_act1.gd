extends SceneTree
## Stage 1 balance: writes Act 1's enemy counts, HP / ATK and XP, then prints the
## balance simulator's numbers for a Forged story team and a Scrap / Alloy team.
## Developer tool. Run from the project folder:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/tune_act1.gd

## enemy file -> [HP, ATK]   (old numbers in the comment)
const STATS := {
	# Stage 2: Helios (Light, neutral to all 3 starters) is now the fight 1 tutorial
	# and the Ember Drone moved to fight 5, so they swapped numbers.
	"solar_drone": [330, 58],       # fight 1 (tutorial)
	"coolant_slime": [300, 52],     # 230 / 40
	"furnace_worker": [1950, 192],  # 1500 / 160  (mini-boss)
	"spore_sprout": [460, 64],      # 360 / 50
	"ember_drone": [600, 96],       # fight 5
	"shadow_thief": [620, 109],     # 480 / 85   (Shade)
	"forge_brute": [2600, 210],     # 2000 / 175 (mini-boss)
	"emberfang_9": [2900, 216],     # 1200 / 180 (boss)
}
## Enemies per fight: first 3 fights = 1 enemy, fights 4-6 = 1-2.
const COUNTS := [1, 1, 1, 2, 1, 2, 1, 1]
## XP per fight (total 2,250 = Lv1 -> Lv10 on the new curve).
const XP := [100, 135, 300, 185, 215, 250, 430, 635]
const TEAM := ["res://data/team/fire_berserker.tres", "res://data/team/water_biotech.tres", "res://data/team/wood_titan.tres"]

var out := PackedStringArray()


func _init() -> void:
	var p: ProgressionTuning = load("res://data/progression.tres")
	var e: EconomyTuning = load("res://data/economy.tres")
	var write := not "--dry" in OS.get_cmdline_user_args()
	var xp_so_far := 0
	var fights: Array[FightData] = []
	for i in 8:
		var path := "res://data/fights/act1/fight_%d.tres" % (i + 1)
		var f: FightData = load(path)
		var d: FighterData = f.enemies[0]
		var key := d.resource_path.get_file().get_basename()
		d.max_hp = STATS[key][0]
		d.atk = STATS[key][1]
		if write:
			ResourceSaver.save(d, d.resource_path)
		var list: Array[FighterData] = []
		for k in COUNTS[i]:
			list.append(d)
		f.enemies = list
		f.xp = XP[i]
		f.expected_level = p.level_for_xp(xp_so_far)
		xp_so_far += XP[i]
		fights.append(f)
		if write:
			ResourceSaver.save(f, path)
	out.append("Act 1 total XP %d -> story team Lv%d after the boss" % [xp_so_far, p.level_for_xp(xp_so_far)])
	for rar in [[2, 2, 2], [1, 0, 1], [0, 0, 0]]:
		out.append("\nTEAM: Fire Berserker / Water Biotech / Wood Titan at %s" % " / ".join(PackedStringArray(rar.map(func(r: int) -> String: return e.rarity_names[r]))))
		for i in 8:
			var f: FightData = fights[i]
			var team := _team(f.expected_level, rar, e)
			var g := BalanceSim.great_turn(f.enemies, team)
			var graw := BalanceSim.great_turn(f.enemies, team, false)
			out.append("  %-34s Lv%d  %d x %4d HP ATK %3d | good %2d  avg %2d  idle %2d  survives: good %-3s avg %-3s | great turn %s (raw %d dmg)" % [
				f.display_name, f.expected_level, f.enemies.size(), f.enemies[0].max_hp, f.enemies[0].atk,
				BalanceSim.turns_to_win(f.enemies, team, "GOOD"), BalanceSim.turns_to_win(f.enemies, team, "AVERAGE"),
				BalanceSim.idle_turns(f.enemies, team), "yes" if BalanceSim.avg_survives(f.enemies, team, "GOOD") else "NO",
				"yes" if BalanceSim.avg_survives(f.enemies, team) else "NO",
				"KILLS" if g["left"] == 0 else "leaves %d" % g["left"], graw["dealt"]])
	print("\n".join(out))
	quit()


## The story trio at a level, with these rarities.
func _team(level: int, rar: Array, e: EconomyTuning) -> Array[FighterData]:
	var t: Array[FighterData] = []
	for k in TEAM.size():
		var c: FighterData = CombatRules.at_level(load(TEAM[k]), level).duplicate()
		var m: float = e.rarity_stat_mult[rar[k]]
		c.max_hp = roundi(c.max_hp * m)
		c.atk = roundi(c.atk * m)
		c.rcv = roundi(c.rcv * m)
		t.append(c)
	return t
