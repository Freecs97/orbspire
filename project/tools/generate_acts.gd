extends SceneTree
## Builds Acts 2-10 (8 fights each) from your art, and tunes every enemy's HP / ATK
## with the balance simulator so each Act follows the same curve as Act 1.
## Developer tool. Act 1 is never touched.
##
## Run from the project folder (rerun any time to rebalance):
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/generate_acts.gd
##
## Each Act uses the same shape as Act 1:
##   1: 2 small enemies of the Act's element      5: 2 Light (or Dark) enemies
##   2: 3 enemies of the Act's element             6: 2 Dark (or Light) enemies
##   3: MINI-BOSS (armoured)                       7: MINI-BOSS 2 (armoured)
##   4: 3 enemies of another element               8: BOSS (armoured, your boss art)

const TEAM_ACT1 := ["res://data/team/fire_berserker.tres", "res://data/team/water_biotech.tres", "res://data/team/wood_titan.tres"]
const SPECTRE := "res://data/team/dark_spectre.tres"
## Story team level when each Act ends (Act 1 already ends at Lv10).
const END_LEVEL := [10, 12, 14, 16, 18, 20, 22, 24, 27, 30]
## How an Act's XP is shared over its 8 fights (same as Act 1: 60/80/180/110/130/150/260/380).
const XP_SHARE := [60, 80, 180, 110, 130, 150, 260, 380]
## Balance targets per fight slot (same as Act 1's): turns to win with good play,
## turns until a team that does nothing falls.
const GOOD_TURNS := [2, 3, 5, 3, 3, 3, 5, 6]
const IDLE_TURNS := [12, 10, 8, 9, 9, 9, 8, 8]
const COUNTS := [2, 3, 1, 3, 2, 2, 1, 1]

## Enemy line-up per Act: [fight1, fight2, mini1, fight4, fight5, fight6, mini2], art names.
const PLAN := {
	2: ["water_drowned_drifter", "water_pipe_crawler", "water_tide_guard", "fire_ash_imp", "light_holo_decoy", "dark_glitch_ghost", "water_deep_diver_mutant"],
	3: ["wood_pollen_wisp", "wood_overgrowth_sproutling", "wood_vine_strangler", "water_bubble_bomber", "light_prism_wisp", "dark_void_imp", "wood_thorn_brute"],
	4: ["light_radiant_sprite", "light_sun_squire", "light_halo_guard", "wood_moss_zombie", "light_beacon_sniper", "dark_night_stalker", "light_mirror_mimic"],
	5: ["dark_nightmare_drone", "dark_void_cultist", "dark_eclipse_assassin", "fire_flame_turret", "light_dawn_acolyte", "dark_dark_hacker", "dark_umbra_hound"],
	6: ["fire_solar_flare_sprite", "fire_pyro_cultist", "fire_inferno_biker", "wood_root_crawler", "light_light_cultist", "dark_reaper_acolyte", "fire_molten_scrapbot"],
	7: ["water_kraken_spawnling", "water_hydro_hacker", "water_rain_assassin", "fire_plasma_hound", "light_prism_wisp", "dark_nightmare_drone", "water_flood_medic"],
	8: ["wood_bio_hound", "wood_moss_zombie", "wood_chloro_cultist", "water_coolant_slime", "light_mirror_mimic", "dark_umbra_hound", "wood_greenhouse_mutant"],
	9: ["light_prism_wisp", "light_light_cultist", "light_halo_guard", "water_tide_guard", "light_sun_squire", "dark_eclipse_assassin", "light_beacon_sniper"],
	10: ["dark_void_imp", "dark_glitch_ghost", "dark_night_stalker", "fire_forge_brute", "light_radiant_sprite", "dark_reaper_acolyte", "dark_void_cultist"],
}
const ARENA := {
	2: "bg_act02_drowned_arena", 3: "bg_act03_greenhouse_arena", 4: "bg_act04_spires_arena", 5: "bg_act05_void_arena",
	6: "bg_act06_solar_arena", 7: "bg_act07_data_arena", 8: "bg_act08_gene_arena", 9: "bg_act09_sanctum_arena", 10: "bg_act10_core_arena",
}
const BOSS_ART := {
	2: "boss_02_tidecoil7_flood_serpent", 3: "boss_03_thornwood_unit", 4: "boss_04_dawnwing_solar_griffin",
	5: "boss_05_voidscale_stealth_dragon", 6: "boss_06_ashen01_solar_phoenix", 7: "boss_07_kraken_mainframe",
	8: "boss_08_mossback_chimera", 9: "boss_09_seraph_enforcer", 10: "boss_10_reaper0_shadow_reaper",
}
## Proper names for the Light / Dark enemies (from your roster list). The PNG name
## becomes their title, e.g. "HELIOS" the Solar Drone.
const NAMES := {
	"solar_drone": "Helios", "halo_guard": "Aurelius", "prism_wisp": "Prisma", "dawn_acolyte": "Aurora",
	"holo_decoy": "Mirage", "beacon_sniper": "Lux", "radiant_sprite": "Lumen", "mirror_mimic": "Echo",
	"sun_squire": "Sol", "light_cultist": "Cassian",
	"shadow_thief": "Shade", "void_imp": "Nix", "night_stalker": "Nocturne", "glitch_ghost": "Spectra",
	"dark_hacker": "Cipher", "reaper_acolyte": "Mortis", "umbra_hound": "Umbra", "void_cultist": "Obsidian",
	"nightmare_drone": "Morpheus", "eclipse_assassin": "Erebus",
}
const ELEMENTS := {"fire": Element.Type.FIRE, "water": Element.Type.WATER, "wood": Element.Type.WOOD, "light": Element.Type.LIGHT, "dark": Element.Type.DARK}

var report := PackedStringArray()


func _init() -> void:
	var p: ProgressionTuning = load("res://data/progression.tres")
	for n in range(2, 11):
		_build_act(n, p)
	var f := FileAccess.open("res://tools/act_generation_report.txt", FileAccess.WRITE)
	f.store_string("\n".join(report))
	f.close()
	print("\n".join(report))
	quit()


func _build_act(n: int, p: ProgressionTuning) -> void:
	var act: ActData = load("res://data/acts/act_%02d.tres" % n)
	var dir_e := "res://data/enemies/act%02d" % n
	var dir_f := "res://data/fights/act%02d" % n
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_e))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_f))
	var team_base := []
	for path in TEAM_ACT1:
		team_base.append(load(path))
	team_base.append(load(SPECTRE))   # the Dark Spectre joins from Act 2
	var start_xp := p.total_xp_for(END_LEVEL[n - 2])
	var act_xp := p.total_xp_for(END_LEVEL[n - 1]) - start_xp
	var xps := _split_xp(act_xp)
	report.append("\nACT %d · %s · %s · %d XP (Lv%d -> Lv%d)" % [n, act.colony_name.to_upper(), Element.display_name(act.element), act_xp, END_LEVEL[n - 2], END_LEVEL[n - 1]])
	var fights: Array[FightData] = []
	var xp_so_far := start_xp
	for slot in 8:
		var level := p.level_for_xp(xp_so_far)
		var team := BalanceSim.leveled_team(team_base, level)
		var d := _enemy_for(n, act, slot)
		_tune(d, slot, team)
		var fname := _file_name(d.title if d.title != "" else d.display_name, slot)
		ResourceSaver.save(d, "%s/%s.tres" % [dir_e, fname])
		var saved: FighterData = load("%s/%s.tres" % [dir_e, fname])
		var f := FightData.new()
		var list: Array[FighterData] = []
		for k in COUNTS[slot]:
			list.append(saved)
		f.enemies = list
		f.xp = xps[slot]
		f.expected_level = level
		f.display_name = "%d/8 · %s" % [slot + 1, _title(d, slot)]
		ResourceSaver.save(f, "%s/fight_%d.tres" % [dir_f, slot + 1])
		fights.append(load("%s/fight_%d.tres" % [dir_f, slot + 1]))
		var good := BalanceSim.turns_to_win(list, team, "GOOD")
		var avg := BalanceSim.turns_to_win(list, team, "AVERAGE")
		var great := BalanceSim.great_turn(list, team)
		report.append("  %-38s Lv%2d  %d x %5d HP  ATK %4d%s  | good %d, avg %2d, idle %2d, avg survives %s, great turn %s | %d XP" % [
			f.display_name, level, list.size(), d.max_hp, d.atk, " ARMOUR" if d.armored else "", good, avg,
			BalanceSim.idle_turns(list, team), "yes" if BalanceSim.avg_survives(list, team) else "NO",
			"KILLS" if great["left"] == 0 else "leaves %d" % great["left"], f.xp])
		xp_so_far += xps[slot]
	act.fights = fights
	act.arena = load("res://assets/backgrounds/%s.png" % ARENA[n])
	act.boss_art = load("res://assets/bosses/%s.png" % BOSS_ART[n])
	ResourceSaver.save(act, "res://data/acts/act_%02d.tres" % n)


## A new enemy data card for this Act's fight slot (stats are tuned after).
func _enemy_for(n: int, act: ActData, slot: int) -> FighterData:
	var d := FighterData.new()
	d.role = FighterData.Role.ENEMY
	d.rcv = 0
	if slot == 7:
		d.display_name = act.singularity_name.to_upper()
		d.element = act.element
		d.art = load("res://assets/bosses/%s.png" % BOSS_ART[n])
		d.figure_height = 400.0
		d.figure_width = 380.0
		d.armored = true
		d.is_boss = true
		d.kind = &"boss"
		return d
	var key: String = PLAN[n][slot]
	var elem_name := key.get_slice("_", 0)
	var name := key.substr(elem_name.length() + 1)
	d.display_name = name.replace("_", " ").to_upper()
	if NAMES.has(name):
		d.title = name.replace("_", " ").capitalize()
		d.display_name = String(NAMES[name]).to_upper()
	d.element = ELEMENTS[elem_name]
	d.art = load("res://assets/enemies/enemy_%s.png" % key)
	var size := _size_for(name)
	var mini := slot == 2 or slot == 6
	d.figure_height = size.x * (1.18 if mini else 1.0)
	d.figure_width = size.y * (1.18 if mini else 1.0)
	d.armored = mini
	d.is_boss = mini
	d.kind = &"art"
	return d


## Rough on-screen size (height, width) from what the enemy is.
func _size_for(name: String) -> Vector2:
	for small in ["drone", "sprite", "wisp", "imp", "spawnling", "sproutling", "bomber", "ghost"]:
		if name.contains(small):
			return Vector2(240, 210)
	for wide in ["hound", "crawler", "turret"]:
		if name.contains(wide):
			return Vector2(260, 260)
	for big in ["brute", "guard", "biker", "scrapbot", "mutant"]:
		if name.contains(big):
			return Vector2(330, 230)
	if name.contains("slime"):
		return Vector2(280, 190)
	return Vector2(310, 160)


## HP so that GOOD play wins in the target number of turns (middle of that range),
## ATK so that doing nothing loses in the target number of turns. Then:
## average play must survive, and mini-bosses / bosses must survive one GREAT turn.
func _tune(d: FighterData, slot: int, team: Array[FighterData]) -> void:
	var n: int = COUNTS[slot]
	var lo := _min_hp_for_turns(d, n, team, GOOD_TURNS[slot])
	var hi := _min_hp_for_turns(d, n, team, GOOD_TURNS[slot] + 1)
	d.max_hp = snappedi((lo + hi) / 2, 10)
	var hp := BalanceSim.team_hp(team)
	d.atk = ceili(float(hp) / (n * IDLE_TURNS[slot]))
	while ceili(float(hp) / (n * d.atk)) > IDLE_TURNS[slot]:
		d.atk += 1
	while not BalanceSim.avg_survives(_list(d, n), team) and d.atk > 10:
		d.atk = int(d.atk * 0.95)
	if d.armored:
		var great := BalanceSim.great_turn(_list(d, n), team)
		if great["left"] == 0:
			d.max_hp = snappedi(ceili(great["dealt"] * 1.15), 10)


func _min_hp_for_turns(d: FighterData, n: int, team: Array[FighterData], turns: int) -> int:
	var a := 10
	var b := 40000
	while a < b:
		var mid := (a + b) / 2
		d.max_hp = mid
		if BalanceSim.turns_to_win(_list(d, n), team, "GOOD") >= turns:
			b = mid
		else:
			a = mid + 1
	return a


func _list(d: FighterData, n: int) -> Array:
	var out := []
	for k in n:
		out.append(d)
	return out


func _split_xp(total: int) -> Array:
	var out := []
	var given := 0
	for k in XP_SHARE.size():
		var x := snappedi(total * XP_SHARE[k] / 1350.0, 5) if k < XP_SHARE.size() - 1 else total - given
		out.append(x)
		given += x
	return out


func _file_name(display_name: String, slot: int) -> String:
	if slot == 7:
		return "boss_" + display_name.to_lower().replace(" ", "_").replace("-", "")
	return display_name.to_lower().replace(" ", "_") + ("_mini" if slot == 2 or slot == 6 else "")


func _title(d: FighterData, slot: int) -> String:
	var name := d.display_name
	if slot == 7:
		return "BOSS: " + name
	if slot == 2 or slot == 6:
		return "MINI-BOSS: " + name + (" (%s)" % d.title.to_upper() if d.title != "" else "")
	if d.title != "":
		return "%s · %s" % [name, _plural(d.title.to_upper())]
	return _plural(name)


func _plural(name: String) -> String:
	if name.ends_with("THIEF"):
		return name.trim_suffix("F") + "VES"
	if name.ends_with("Y") and not "AEIOU".contains(name[name.length() - 2]):
		return name.trim_suffix("Y") + "IES"
	if name.ends_with("S") or name.ends_with("SH"):
		return name + "ES"
	return name + "S"
