extends Node
## Universe update test (master prompt "Universe Map Final" + "Art Location + Random
## Colouring", 2026-11-19).
##   U-MAP     10 galaxies scattered round Galaxy 1 (no line), rings by distance
##   U-SYS     systems / worlds scattered radially, levels rise outward
##   U-STORY   Galaxy 1 Systems 1-3 = Acts 1-10 unchanged (+ side worlds)
##   U-TRAVEL  outward ring by ring, any direction; Reaper-0 gates free exploration
##   U-AFF     affinities mixed everywhere; mono teams can't clear a galaxy
##   U-WORLD   5 stages, Stage 5 boss; cleansed only by Stage 5
##   U-COUNT   Worlds Cleansed / Singularities / Wardens, saved across a restart
##   U-DANGER  Green / Yellow / Red / Skull; Skull warns but never blocks
##   U-LEVEL   galaxy caps, XP Lv31-120, +2% per level, Lv1-30 unchanged
##   U-COLOUR  random hue shifts: neighbours differ, all hues used, same every load
##   U-ART     World_Building inventory: every file mapped, missing ones reported
##   U-POPUP   combat pop-up: 20 taps = 20 opens that stay open; no REPLACE
## Run:  Godot_v4.7.2-stable_win64_console.exe --path . res://tests/universe_test.tscn
## Results: tests/report_universe.txt

const MainScene := preload("res://scenes/main.tscn")
const SAVE := "user://universe_test_save.json"
const WB := "C:/Users/User/Documents/General_Agent/Orbspire/orbspire-art-organized/World_Building"
const MONO_FIRE := ["berserker_01_angel_fire", "biotech_03_healer_fire", "spectre_02_mage_fire", "titan_02_guardian_fire"]
const MONO_WATER := ["berserker_03_thin_water", "biotech_01_medic_water", "spectre_04_assassin_water", "titan_03_anchor_water"]

var lines := PackedStringArray()
var fails := 0


func _ready() -> void:
	GameSettings.path = "user://test_settings.json"
	GameSettings.skill_cut_ins = false
	Profile.friend_drops = false
	_log("Godot %s · Universe update" % Engine.get_version_info().string)
	_test_map()
	_test_systems_and_worlds()
	_test_story()
	_test_travel()
	_test_affinities()
	_test_levels()
	_test_colours()
	_test_art()
	_test_balance()
	_test_recolours()
	_test_dual()
	await _test_flow()
	await _test_popup()
	await _test_story_b()
	_finish()


# ---------------------------------------------------------------- U-MAP

func _test_map() -> void:
	_log("\n== U-MAP: the universe ==")
	var gals := Cosmos.galaxies()
	var centre := Vector2(0.5, 0.5)
	_check(gals.size() == 10 and gals[0]["name"] == "Orbspire Galaxy" and (gals[0]["pos"] as Vector2).distance_to(centre) < 0.03, "10 galaxies; Galaxy 1 (Orbspire) is the centre")
	var ring_d := {1: [], 2: [], 3: []}
	for g in gals.slice(1):
		ring_d[int(g["ring"])].append((g["pos"] as Vector2).distance_to(centre))
	var order_ok: bool = ring_d[1].max() < ring_d[2].min() and ring_d[2].max() < ring_d[3].min()
	_check(order_ok and ring_d[1].size() == 3 and ring_d[2].size() == 3 and ring_d[3].size() == 3,
		"3 + 3 + 3 galaxies; farther from the centre = higher ring (Ring 1 %.3f-%.3f < Ring 2 %.3f-%.3f < Ring 3 %.3f-%.3f)" % [
		ring_d[1].min(), ring_d[1].max(), ring_d[2].min(), ring_d[2].max(), ring_d[3].min(), ring_d[3].max()])
	var bands_ok := true
	for g in gals:
		bands_ok = bands_ok and g["band"] == Cosmos.BANDS[int(g["g"]) - 1]
	_check(bands_ok and Cosmos.galaxy(4)["band"] == [51, 70] and Cosmos.galaxy(10)["band"] == [111, 120], "level bands: Galaxy 1 Lv1-30, Tide 31-50 ... Core 111-120")
	var pts: Array = gals.map(func(x: Dictionary) -> Vector2: return x["pos"])
	_check(not _in_a_line(pts), "not in a line, not on a grid: spread round the centre in every direction (%s)" % _angles_text(pts))
	var angles := []
	for g in gals.slice(1):
		angles.append(snappedf(rad_to_deg(((g["pos"] as Vector2) - centre).angle()), 1.0))
	_log("INFO  galaxy angles round the centre: %s" % [angles])


func _in_a_line(pts: Array) -> bool:
	# Points in a line: all close to the line through the two farthest points.
	var a: Vector2 = pts[0]
	var b: Vector2 = pts[0]
	var best := 0.0
	for p in pts:
		for q in pts:
			if (p as Vector2).distance_to(q) > best:
				best = (p as Vector2).distance_to(q)
				a = p
				b = q
	var far := 0.0
	var dir := (b - a).normalized()
	for p in pts:
		var v: Vector2 = p - a
		far = maxf(far, absf(v.cross(dir)))
	return far < 0.12


func _angles_text(pts: Array) -> String:
	var quadrants := {}
	for p in pts.slice(1):
		var v: Vector2 = (p as Vector2) - Vector2(0.5, 0.5)
		quadrants["%s%s" % ["E" if v.x > 0 else "W", "S" if v.y > 0 else "N"]] = true
	return "quadrants used: %s" % ", ".join(PackedStringArray(quadrants.keys()))


# ---------------------------------------------------------------- U-SYS

func _test_systems_and_worlds() -> void:
	_log("\n== U-SYS: solar systems and worlds ==")
	var sys_ok := true
	var rings_ok := true
	var worlds_ok := true
	var lv_ok := true
	var total := 0
	for g in range(1, 11):
		var systems := Cosmos.systems(g)
		sys_ok = sys_ok and systems.size() == 10 and (systems[0]["pos"] as Vector2).distance_to(Vector2(0.5, 0.5)) < 0.01
		var mean := {}
		for s in systems:
			var r: int = s["ring"]
			if not mean.has(r):
				mean[r] = []
			mean[r].append((s["pos"] as Vector2).distance_to(Vector2(0.5, 0.5)))
			var ws := Cosmos.worlds(g, int(s["s"]))
			total += ws.size()
			worlds_ok = worlds_ok and ws.size() >= 5 and ws.size() <= 10 and ws.size() == int(s["n_worlds"])
			var sun: Vector2 = MapArt.SYSTEM_SUN[s["art"]]
			for i in range(1, ws.size()):
				# Worlds farther from the star have a higher (or equal) Recommended Level.
				lv_ok = lv_ok and (ws[i]["pos"] as Vector2).distance_to(sun) > (ws[i - 1]["pos"] as Vector2).distance_to(sun) - 0.06
				if not s["story"]:
					lv_ok = lv_ok and int(ws[i]["rec"]) >= int(ws[i - 1]["rec"])
		for r in range(1, 4):
			rings_ok = rings_ok and _avg(mean[r]) > _avg(mean[r - 1])
	_check(sys_ok, "every galaxy: 10 solar systems, its main system in the centre")
	_check(rings_ok, "systems scattered in rings round the centre (farther ring = farther out), no line")
	_check(worlds_ok, "every system: 5-10 worlds")
	_check(lv_ok, "worlds scattered round the star: farther from the star = higher Recommended Level")
	_check(total == Cosmos.total_worlds() and Cosmos.total_singularities() == 107, "totals: %d worlds, %d singularities (10 Acts + 97 systems), %d wardens" % [total, Cosmos.total_singularities(), Cosmos.total_wardens()])


func _avg(a: Array) -> float:
	var s := 0.0
	for v in a:
		s += float(v)
	return s / maxf(a.size(), 1)


# ---------------------------------------------------------------- U-STORY

func _test_story() -> void:
	_log("\n== U-STORY: main story = Galaxy 1, Systems 1-3 ==")
	var acts := {1: [], 2: [], 3: []}
	var aff_ok := true
	for s in range(1, 4):
		var els := {}
		for w in Cosmos.worlds(1, s):
			els[int(w["element"])] = true
			if int(w["act"]) > 0:
				acts[s].append(int(w["act"]))
		aff_ok = aff_ok and els.size() == 5 and Cosmos.worlds(1, s).size() == 5
	_check(acts[1] == [1, 2, 3] and acts[2] == [4, 5, 6, 7] and acts[3] == [8, 9, 10], "System 1 = Acts 1-3, System 2 = Acts 4-7, System 3 = Acts 8-10 (%s)" % [acts])
	_check(aff_ok, "each story system: 5 worlds with all 5 affinities (Acts + optional side worlds)")
	var same := true
	for n in range(1, 11):
		var w := Cosmos.world_by_key(Cosmos.act_world_key(n))
		var a := Cosmos.build_world(int(w["g"]), int(w["s"]), int(w["w"]))
		same = same and a == Cosmos.ACTS[n - 1] and a.fights.size() == 8
	_check(same, "the 10 Act worlds ARE the Stage 6 Acts (8 fights each, numbers unchanged)")
	var story_text := ""
	for a in Cosmos.ACTS:
		story_text += " ".join(PackedStringArray(a.intro_lines)) + a.boss_taunt + a.outro_line
	_check(story_text.contains("Progenitors") or story_text.contains("PROGENITORS"), "THE PROGENITORS in the story; no \"The Ban\"" if not story_text.contains("The Ban") else "FOUND \"The Ban\"")


# ---------------------------------------------------------------- U-TRAVEL

func _test_travel() -> void:
	_log("\n== U-TRAVEL: outward, ring by ring ==")
	var save := {"cleared_acts": [1, 2, 3, 4, 5, 6]}
	var j := Journey.new(save)
	var before := []
	for g in range(1, 11):
		before.append(j.galaxy_unlocked(g))
	_check(before == [true, false, false, false, false, false, false, false, false, false], "before Reaper-0: only Galaxy 1")
	_check(j.system_unlocked(1, 1) and j.system_unlocked(1, 2) and not j.system_unlocked(1, 3) and not j.system_unlocked(1, 4),
		"story systems in order (System 3 waits for Act 7); exploration systems wait for Reaper-0")
	_check(j.system_lock_reason(1, 3).contains("Act 7") and j.system_lock_reason(1, 5).contains("Reaper-0"), "lock reasons: \"%s\" / \"%s\"" % [j.system_lock_reason(1, 3), j.system_lock_reason(1, 5)])
	save["cleared_acts"] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	var ring1 := []
	for g in range(2, 5):
		ring1.append(j.galaxy_unlocked(g))
	_check(ring1 == [true, true, true] and not j.galaxy_unlocked(5) and not j.galaxy_unlocked(8),
		"after Reaper-0: all 3 Ring 1 galaxies open (any order); Ring 2 and 3 stay locked (no jumping to the edge)")
	var any_g1 := true
	for s in range(4, 11):
		any_g1 = any_g1 and j.system_unlocked(1, s)
	_check(any_g1, "Galaxy 1 exploration opens after Reaper-0 (the story already cleared a system in Rings 0, 1 and 2)")
	var probe := {"cleared_acts": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], "cosmos": {}}
	var jp := Journey.new(probe)
	var ring1_g2 := -1
	var ring2_g2 := -1
	for sys in Cosmos.systems(2):
		if int(sys["ring"]) == 1 and ring1_g2 < 0:
			ring1_g2 = int(sys["s"])
		if int(sys["ring"]) == 2 and ring2_g2 < 0:
			ring2_g2 = int(sys["s"])
	var r1_before := jp.system_unlocked(2, ring1_g2)
	var r2_before := jp.system_unlocked(2, ring2_g2)
	var c1 := Cosmos.worlds(2, 1)
	jp.c["cleansed"].append(c1[c1.size() - 1]["key"])
	_check(jp.system_unlocked(2, 1) and not r1_before and not r2_before and jp.system_unlocked(2, ring1_g2) and not jp.system_unlocked(2, ring2_g2),
		"inside Tide Galaxy: the centre system first; clearing it opens Ring 1 only")
	# Clear one Ring 3 system of Galaxy 3 (Thorn): Ring 2 opens, Ring 3 still locked.
	var outer := -1
	for sys in Cosmos.systems(3):
		if int(sys["ring"]) == 3:
			outer = int(sys["s"])
			break
	var ws := Cosmos.worlds(3, outer)
	j.c["cleansed"].append(ws[ws.size() - 1]["key"])
	_check(j.galaxy_completed(3) and j.galaxy_unlocked(5) and j.galaxy_unlocked(6) and j.galaxy_unlocked(7) and not j.galaxy_unlocked(8),
		"complete ONE Ring 1 galaxy (Thorn) -> every Ring 2 galaxy opens; Ring 3 still needs a Ring 2 galaxy")
	# Inside a world: cleanse a nearer world to open the next ring of worlds.
	var key1: String = Cosmos.worlds(2, 1)[0]["key"]
	var key2: String = Cosmos.worlds(2, 1)[1]["key"]
	var locked_before := not j.world_unlocked(key2)
	j.c["cleansed"].append(key1)
	_check(j.world_unlocked(key1) and locked_before and j.world_unlocked(key2), "worlds: cleanse a world nearer the star to open the next ones")
	_check(not j.stage_playable(key2, 1) and j.stage_playable(key2, 0), "stages go in order (Stage 2 waits for Stage 1)")
	_check(j.galaxy_lock_reason(8) != "" and j.world_lock_reason(Cosmos.worlds(8, 1)[0]["key"]) != "", "locked places can still be previewed (they say what opens them)")


# ---------------------------------------------------------------- U-AFF

func _test_affinities() -> void:
	_log("\n== U-AFF: affinities mixed everywhere ==")
	var gal_ok := true
	var sys_ok := true
	var stage_ok := true
	var pure := 0
	var worlds := 0
	for g in range(1, 11):
		var split := {}
		for sys in Cosmos.systems(g):
			split[int(sys["element"])] = int(split.get(int(sys["element"]), 0)) + 1
			var els := {}
			for w in Cosmos.worlds(g, int(sys["s"])):
				els[int(w["element"])] = true
				if int(w["act"]) > 0:
					continue
				worlds += 1
				if w["pure"]:
					pure += 1
					continue
				var mix := {}
				for row in (w["stage_elements"] as Array).slice(0, 4):
					for e in row:
						mix[int(e)] = true
				var rel := Cosmos.related_elements(int(w["element"]))
				stage_ok = stage_ok and mix.size() >= 3 and mix.has(int(w["element"])) and rel.any(func(e: int) -> bool: return mix.has(e))
				stage_ok = stage_ok and int(w["stage_elements"][4][0]) == int(w["element"])
			sys_ok = sys_ok and els.size() == 5
		gal_ok = gal_ok and split.size() == 5 and split.values().all(func(n: int) -> bool: return n == 2)
	_check(gal_ok, "every galaxy: 2 Fire, 2 Water, 2 Wood, 2 Light, 2 Dark systems")
	_check(sys_ok, "every solar system: worlds of all 5 affinities (none single-affinity)")
	_check(stage_ok, "mixed worlds: Stages 1-4 use 3+ affinities incl. the main one and one it is strong / weak against; Stage 5 boss = the main one")
	_check(pure > 0 and float(pure) / worlds < 0.2, "PURE worlds (Bailey's choice): %d of %d generated worlds (%.0f%%)" % [pure, worlds, 100.0 * pure / worlds])
	# Mono teams vs a balanced team, every world of a galaxy, good play.
	for g in [2, 6]:
		var fire := _clears_galaxy(g, MONO_FIRE)
		var water := _clears_galaxy(g, MONO_WATER)
		var mixed := _clears_galaxy(g, Cosmos.REF_IDS)
		_check(fire.x > 0 and water.x > 0 and mixed.x == 0,
			"Galaxy %d with good play: mono-Fire loses %d of %d worlds, mono-Water %d, a balanced team %d (it can clear the galaxy)" % [g, fire.x, fire.y, water.x, mixed.x])


## (worlds lost, worlds played) for a team at each world's Recommended Level.
func _clears_galaxy(g: int, ids: Array) -> Vector2i:
	var lost := 0
	var n := 0
	for sys in Cosmos.systems(g):
		for w in Cosmos.worlds(g, int(sys["s"])):
			if int(w["act"]) > 0:
				continue
			n += 1
			var a := Cosmos.build_world(g, int(sys["s"]), int(w["w"]))
			var team := Cosmos.ref_team(a.rec_level, ids)
			for f in a.fights:
				if not BalanceSim.avg_survives(f.enemies, team, "GOOD"):
					lost += 1
					break
	return Vector2i(lost, n)


# ---------------------------------------------------------------- U-LEVEL

func _test_levels() -> void:
	_log("\n== U-LEVEL: slow, meaningful levelling ==")
	var p: ProgressionTuning = load("res://data/progression.tres")
	_check(p.xp_to_next(1) == 50 and p.xp_to_next(9) == 450 and p.xp_to_next(10) == 625 and p.xp_to_next(14) == 1575 and is_equal_approx(p.stat_mult(30), 2.5),
		"Lv1-30 unchanged (XP 50, 450, 625, 1575; stats x2.5 at Lv30)")
	_check(p.xp_to_next(31) == 15345 and p.xp_to_next(60) == 75375 and p.xp_to_next(119) == 333795,
		"XP Lv31+: 75 x level, +35%% steps carrying on from Lv30 (Lv31 %d, Lv60 %d, Lv119 %d)" % [p.xp_to_next(31), p.xp_to_next(60), p.xp_to_next(119)])
	_check(is_equal_approx(p.stat_mult(31) / p.stat_mult(30), 1.02) and is_equal_approx(p.stat_mult(60), 4.0) and is_equal_approx(p.stat_mult(120), 7.0),
		"one level above 30 = +2%% of the Lv30 stats, not +10%% (Lv31 x%.3f, Lv60 x%.2f, Lv120 x%.2f)" % [p.stat_mult(31), p.stat_mult(60), p.stat_mult(120)])
	_check(p.level_cap(1) == 15 and p.level_cap(2) == 30 and p.level_cap(3) == 60 and p.level_cap(4) == 90 and p.built_stages == 3,
		"evolution gates: Stage 2 at Lv15, Stage 3 at Lv30; Stage 4 (Lv60) and Stage 5 (Lv90) RESERVED, not built")
	var caps := []
	for g in range(1, 11):
		caps.append(Cosmos.galaxy_cap(g))
	var ring1 := maxi(maxi(caps[1], caps[2]), caps[3])
	_check(caps[0] == 30 and ring1 == 70 and caps[9] == 120, "galaxy caps: Galaxy 1 Lv30, Ring 1 up to Lv70, Core Lv120 (%s)" % [caps])
	var prof := Profile.new({})
	var uid := prof.add_unit("berserker_01_angel_fire", 2)
	var u := prof.unit(uid)
	u["stage"] = 3
	u["level"] = 29
	prof.grant_xp([uid], 10000000, 0, Cosmos.galaxy_cap(1))
	var in_g1: int = u["level"]
	prof.data["level_ceiling"] = 70
	prof.grant_xp([uid], 100000000, 0, Cosmos.galaxy_cap(4))
	var in_g4: int = u["level"]
	u["level"] = 45
	prof.grant_xp([uid], 1000000, 0, Cosmos.galaxy_cap(1))
	_check(in_g1 == 30 and in_g4 == 60 and u["level"] == 45,
		"Galaxy 1 stops at Lv30 even fully evolved; in Galaxy 4 (cap 70) Stage 3 stops at Lv60 until Stage 4 exists; a Lv45 replaying Galaxy 1 keeps Lv45")
	var team35: Array[FighterData] = Cosmos.ref_team(35, Cosmos.REF_IDS, 1.2)
	var boss10: Array = Cosmos.ACTS[9].fights[7].enemies
	var g35 := BalanceSim.great_turn(boss10, team35)
	_check(g35["left"] > 0, "a Lv35 Singularity team does NOT one-shot the Lv30 boss Reaper-0 (%d HP left after a perfect turn)" % g35["left"])


# ---------------------------------------------------------------- U-COLOUR

func _test_colours() -> void:
	_log("\n== U-COLOUR: random colours, the same every time ==")
	var gal_ok := true
	for r in range(1, 4):
		var ring := Cosmos.galaxies_in_ring(r)
		for a in ring:
			for b in ring:
				if a != b:
					gal_ok = gal_ok and MapArt.hue_gap(a["seen_hue"], b["seen_hue"]) >= 0.15
	_check(gal_ok, "no two galaxies in the same ring within 0.15 of each other")
	var sys_ok := true
	var all_hues := true
	var world_ok := true
	var three := true
	for g in range(1, 11):
		var systems := Cosmos.systems(g)
		var pos: Array = systems.map(func(x: Dictionary) -> Vector2: return x["pos"])
		var adj := Cosmos.neighbours(pos)
		var bins := {}
		for i in systems.size():
			bins[int(float(systems[i]["seen_hue"]) * 5.0) % 5] = true
			for j in adj[i]:
				sys_ok = sys_ok and MapArt.hue_gap(systems[i]["hue"], systems[j]["hue"]) >= 0.15
		all_hues = all_hues and bins.size() == 5
		for sys in systems:
			var ws := Cosmos.worlds(g, int(sys["s"]))
			var wpos: Array = ws.map(func(x: Dictionary) -> Vector2: return x["pos"])
			var wadj := Cosmos.neighbours(wpos)
			var wbins := {}
			for i in ws.size():
				wbins[int(float(ws[i]["seen_hue"]) * 5.0) % 5] = true
				for j in wadj[i]:
					world_ok = world_ok and MapArt.hue_gap(ws[i]["hue"], ws[j]["hue"]) >= 0.15
				for j in ws.size():
					if j != i and int(ws[i]["template"]) == int(ws[j]["template"]):
						world_ok = world_ok and MapArt.hue_gap(ws[i]["hue"], ws[j]["hue"]) >= 0.15
			three = three and wbins.size() >= 3
	_check(sys_ok, "no two neighbouring solar systems within 0.15 hue shift")
	_check(all_hues, "every galaxy uses ALL hues (reds, golds, greens, blues, purples) across its systems")
	_check(world_ok, "no two neighbouring worlds within 0.15, and never the same planet picture with (almost) the same colour twice in a system")
	_check(three, "every solar system shows 3+ different hues across its worlds")
	# Same after a restart: wipe the caches and make everything again.
	var before := _colour_fingerprint()
	Cosmos._galaxies = []
	Cosmos._systems = {}
	Cosmos._worlds = {}
	Cosmos._built = {}
	_check(_colour_fingerprint() == before, "fixed seed %d: every position and colour is the SAME after a restart" % Cosmos.SEED)
	var fp := Cosmos.layout_fingerprint()
	_check(fp == Cosmos.APPROVED_LAYOUT, "LOCKED: positions and colours match the layout Bailey approved on 2026-11-19 (%s)" % fp)
	# A blue planet can be a Fire world: colour never decides affinity.
	var found := ""
	for sys in Cosmos.systems(2):
		for w in Cosmos.worlds(2, int(sys["s"])):
			if found == "" and int(w["element"]) == Element.Type.FIRE and float(w["seen_hue"]) > 0.55 and float(w["seen_hue"]) < 0.7:
				found = w["key"]
	var fw := Cosmos.world_by_key(found) if found != "" else {}
	var built := Cosmos.build_world(int(fw["g"]), int(fw["s"]), int(fw["w"])) if found != "" else null
	_check(found != "" and built.element == Element.Type.FIRE and built.fights[4].enemies[0].element == Element.Type.FIRE,
		"a blue planet can be a Fire world (%s, colour %.2f): its label, orb icon and boss are Fire; colour never changes affinity" % [found, float(fw.get("seen_hue", 0.0))])


func _colour_fingerprint() -> String:
	var parts := PackedStringArray()
	for g in range(1, 11):
		parts.append("%.4f" % float(Cosmos.galaxy(g)["hue"]))
		for sys in Cosmos.systems(g):
			parts.append("%.4f/%s" % [float(sys["hue"]), str(sys["pos"])])
			for w in Cosmos.worlds(g, int(sys["s"])):
				parts.append("%.4f/%d/%s/%d" % [float(w["hue"]), int(w["template"]), str(w["pos"]), int(w["element"])])
	return "|".join(parts)


# ---------------------------------------------------------------- U-ART

func _test_art() -> void:
	_log("\n== U-ART: World_Building art ==")
	var mapped := {}
	var exists := true
	for row in MapArt.SOURCES:
		mapped["%s/%s" % [row[0], row[1]]] = row[2]
		exists = exists and ResourceLoader.exists("res://assets/maps/" + String(row[2]))
	_check(exists and MapArt.SOURCES.size() == 11, "11 pictures copied into assets/maps (renamed, mapping listed in MapArt.SOURCES)")
	if DirAccess.dir_exists_absolute(WB):
		var unmapped := PackedStringArray()
		var counts := {}
		for folder in ["Universe", "Galaxies", "Solar_System", "Worlds"]:
			var files := DirAccess.get_files_at(WB + "/" + folder)
			counts[folder] = files.size()
			for f in files:
				if not mapped.has("%s/%s" % [folder, f]):
					unmapped.append(folder + "/" + f)
		_check(unmapped.is_empty(), "every file in the 4 World_Building folders is mapped (%s)" % [counts])
	else:
		_log("INFO  World_Building folder not on this machine; skipped the folder listing")
	_check(MapArt.MISSING.size() == 3 and " ".join(PackedStringArray(MapArt.MISSING)).contains("City"), "missing art is reported, not skipped: %s" % " / ".join(PackedStringArray(MapArt.MISSING)))


# ---------------------------------------------------------------- balance of generated worlds

func _test_balance() -> void:
	_log("\n== U-BAL: generated worlds ==")
	var turns_ok := true
	var boss_ok := true
	var shot := true
	var stronger := true
	var n := 0
	for g in [1, 2, 5, 10]:
		var prev_ring := {}
		for sys in Cosmos.systems(g):
			if sys["story"]:
				continue
			var w0: Dictionary = Cosmos.worlds(g, int(sys["s"]))[0]
			var a := Cosmos.build_world(g, int(sys["s"]), int(w0["w"]))
			var team := Cosmos.ref_team(a.rec_level)
			var sum := 0
			for i in 5:
				var probe: Array[FighterData] = []
				for e in a.fights[i].enemies:
					var c: FighterData = e.duplicate()
					c.element = Element.Type.NONE
					probe.append(c)
				var t := BalanceSim.turns_to_win(probe, team, "GOOD")
				if i < 4:
					sum += t
				else:
					boss_ok = boss_ok and t >= 8 and t <= 10
			turns_ok = turns_ok and sum >= 15 and sum <= 18
			var maxed := Cosmos.ref_team(a.rec_level, Cosmos.REF_IDS, 1.2)
			for i in [3, 4]:
				shot = shot and BalanceSim.great_turn(a.fights[i].enemies, maxed)["left"] > 0
			prev_ring[int(sys["ring"])] = maxi(int(prev_ring.get(int(sys["ring"]), 0)), a.fights[4].enemies[0].max_hp)
			n += 1
		for r in range(1, 4):
			if prev_ring.has(r) and prev_ring.has(r - 1):
				stronger = stronger and prev_ring[r] > prev_ring[r - 1]
	_check(turns_ok, "a team at the Recommended Level clears Stages 1-4 in 15-17 good-play turns (%d systems checked)" % n)
	_check(boss_ok, "the Stage 5 boss takes 8-10 good-play turns")
	_check(shot, "no Warden / boss can be one-shot by a maxed team at the Recommended Level (Resolve)")
	_check(stronger, "outer rings are stronger (+4% per ring on top of the level)")


# ---------------------------------------------------------------- U-RECOLOUR / U-DUAL

func _test_recolours() -> void:
	_log("\n== U-RECOLOUR: every character in all 5 affinities ==")
	var variants := Catalog.variant_ids()
	var cover := true
	for id in Catalog.IDS + Catalog.ENEMY_IDS:
		var els := {Catalog.template(id).element: true}
		for v in variants:
			if Catalog.base_of(v) == id:
				els[Catalog.template(v).element] = true
		for r in Catalog.RECOLOR_IDS:
			if Catalog.template(r).art == Catalog.template(id).art:
				els[Catalog.template(r).element] = true
		cover = cover and els.size() == 5
	_check(cover and variants.size() == 110, "every human (20) and enemy (10) exists in all 5 affinities: %d new colour versions + the 10 named ones" % variants.size())
	var same_skills := true
	var tilt_ok := true
	var art_ok := true
	for v in variants:
		var t := Catalog.template(v)
		var b := Catalog.template(Catalog.base_of(v))
		same_skills = same_skills and t.active_skill == b.active_skill and t.leader_skill == b.leader_skill and t.passives == b.passives and t.role == b.role
		for pair in [[t.max_hp, b.max_hp], [t.atk, b.atk], [t.rcv, b.rcv]]:
			if int(pair[1]) > 20:
				var r := float(pair[0]) / float(pair[1])
				tilt_ok = tilt_ok and r >= 0.94 and r <= 1.06
	for v in ["berserker_01_angel_fire@water", "titan_04_void_dark@light", "enemy_spore_sprout@dark"]:
		art_ok = art_ok and Catalog.art(v) != Catalog.template(Catalog.base_of(v)).art and Catalog.art(v, 3) != null
	_check(same_skills, "same design, archetype and skills (they work in the new affinity: skills use the hunter's own affinity)")
	_check(tilt_ok, "stats tilted about 5% (every stat within 94-106% of the original)")
	_check(art_ok, "recoloured in code from the original PNGs (Stage 1-3 art), no new art files")
	var in_fights := false
	for a in Cosmos.ACTS:
		for f in a.fights:
			for e in f.enemies:
				in_fights = in_fights or Catalog.is_colour_version(e.design_id)
	var lab_ok: bool = not Catalog.lab_ids().any(func(id: String) -> bool: return Catalog.is_colour_version(id))
	var pool: Array = Catalog.pool_for_rarity(0)
	var pool_ok: bool = pool.has("berserker_01_angel_fire@water") and pool.has("enemy_ember_drone@light") and not pool.has("friend_jake")
	_check(not in_fights and lab_ok and pool_ok, "Recruit / fight drops only: never in fights, never in the Lab (no Essence)")


func _test_dual() -> void:
	_log("\n== U-DUAL: dual affinity (Stage 3 only) ==")
	var humans := 0
	var enemies := 0
	for id in Catalog.DUAL:
		if id in Catalog.IDS:
			humans += 1
		elif id in Catalog.ENEMY_IDS:
			enemies += 1
	_check(humans == 5 and enemies == 3, "8 of 30 Stage 3 final evolutions (27%): 5 of 20 humans + 3 of 10 enemies")
	for id in Catalog.DUAL:
		_log("INFO  %s (%s) + %s: %s" % [Catalog.display_name(id), Element.display_name(Catalog.template(id).element), Element.display_name(Catalog.DUAL[id]), Catalog.DUAL_WHY[id]])
	var p := Profile.new({})
	var uid := p.add_unit("berserker_01_angel_fire", 3)
	var u := p.unit(uid)
	var s1 := p.fighter(uid).sub_element
	u["stage"] = 3
	u["level"] = 30
	var hero := p.fighter(uid)
	_check(s1 == -1 and hero.sub_element == Element.Type.LIGHT, "the sub affinity only appears at Stage 3 (Kaela: Fire + Light)")
	# Damage: a dummy hit with ONLY Light orbs (the sub) = 1/3 of a main hit.
	var dummy := FighterData.new()
	dummy.role = FighterData.Role.ENEMY
	dummy.element = Element.Type.NONE
	dummy.max_hp = 10000000
	var team: Array[FighterData] = [hero]
	var main_hit := BalanceSim.attack(team, [BalanceSim.group(Element.Type.FIRE, 3)], 1, BalanceSim.fresh_enemies([dummy]))
	var sub_hit := BalanceSim.attack(team, [BalanceSim.group(Element.Type.LIGHT, 3)], 1, BalanceSim.fresh_enemies([dummy]))
	var same: FighterData = hero.duplicate()
	same.sub_element = same.element
	var same_team: Array[FighterData] = [same]
	var same_hit := BalanceSim.attack(same_team, [BalanceSim.group(Element.Type.FIRE, 3)], 1, BalanceSim.fresh_enemies([dummy]))
	var ratio := float(sub_hit) / float(main_hit)
	var same_ratio := float(same_hit - main_hit) / float(main_hit)
	_check(ratio > 0.3 and ratio < 0.37 and same_ratio > 0.07 and same_ratio < 0.13,
		"sub affinity hits for 1/3 (%.2f of a main hit), or 10%% if the same affinity (%.2f): versatility, not raw power" % [ratio, same_ratio])
	var t10 := BalanceSim.leveled_team([Catalog.template("berserker_01_angel_fire"), Catalog.template("biotech_01_medic_water"), Catalog.template("titan_01_shield_wood")], 10)
	var none_dual := t10.all(func(f: FighterData) -> bool: return f.sub_element < 0)
	_check(none_dual, "Act 1 is unchanged (nobody can be Stage 3 there, so no dual affinity)")


# ---------------------------------------------------------------- flow through the real game

func _test_flow() -> void:
	_log("\n== U-WORLD / U-COUNT / U-DANGER: the real game ==")
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var main := MainScene.instantiate()
	main.save_path = SAVE
	add_child(main)
	await _frames(3)
	main.save["intro_seen"] = true
	main.save["slot4_notice"] = true
	main.profile.choose_starter(Profile.STARTERS[0])
	for n in range(1, 11):
		main.save["cleared_acts"].append(n)
	for id in ["biotech_01_medic_water", "titan_01_shield_wood", "spectre_01_rogue_dark"]:
		main.profile.auto_slot(main.profile.add_unit(id, 2, 1))
	# The post-game story beats are tested in U-STORY-B; here they'd sit on top.
	main.journey.c["story_seen"] = ["final_arc", "ring1", "galaxy2", "cleanse_popup"]
	main.show_map()
	await _frames(3)
	var m: CosmosMap = main.map
	_check(m.counter_label.text == "Worlds 10/%d  •  Singularities 10/107" % Cosmos.total_worlds(), "top bar counters on the universe map: \"%s\"" % m.counter_label.text)
	var key: String = Cosmos.worlds(2, 1)[0]["key"]
	# Danger: a Lv1 team, a Lv31 world -> Skull warning, but PLAY still works.
	m.request_play(key, 0)
	await _frames(2)
	_check(m.warn_panel.visible and m.warn_title.text.contains("LETHAL") and m.warn_text.text.contains("Recommended Lv 31, your team is Lv 1") and m.warn_text.text.contains("will probably kill you"),
		"Skull (10+ below): \"%s\"" % m.warn_text.text.replace("\n", " "))
	await _click(m.warn_go)
	await _frames(4)
	var b = main.battle
	_check(b != null and b.act.world_key == key and b.act.fights.size() == 5 and b.team.members.size() == 4,
		"Skull does NOT block: PLAY ANYWAY starts the world (5 stages, a team of 4)")
	_check(b != null and b.act.fights[4].enemies[0].is_boss and b.act.fights[3].enemies[0].is_boss and not b.act.fights[0].enemies[0].is_boss,
		"Stage 4 = Warden, Stage 5 = boss, Stages 1-3 regular")
	_check(Journey.danger(30, 30) == "green" and Journey.danger(27, 31) == "yellow" and Journey.danger(25, 31) == "red" and Journey.danger(21, 31) == "skull",
		"danger: at / above = Green, 1-4 below = Yellow, 5-9 = Red, 10+ = Skull")
	# Win Stages 1-4: not cleansed. Win Stage 5: cleansed (+ singularity if gate).
	for i in 4:
		b.fight_index = i
		b._show_result(true)
		await _frames(2)
	var after4: bool = main.journey.world_cleansed(key)
	var wardens4: int = main.journey.wardens_defeated()
	b.fight_index = 4
	b._show_result(true)
	await _frames(3)
	_check(not after4 and main.journey.world_cleansed(key) and main.journey.worlds_cleansed() == 11,
		"Stages 1-4 do NOT cleanse the world; the Stage 5 boss does (Worlds Cleansed 10 -> 11)")
	_check(wardens4 == 1 and main.journey.wardens_defeated() == 2, "Wardens Defeated counts Stage 4 and a non-gate Stage 5 (%d)" % main.journey.wardens_defeated())
	# A gate world: its boss is the system's singularity.
	var ws := Cosmos.worlds(2, 1)
	var gate: String = ws[ws.size() - 1]["key"]
	main.play_world(gate, 4)
	await _frames(4)
	main.battle.fight_index = 4
	main.battle._show_result(true)
	await _frames(3)
	_check(main.journey.singularities_defeated() == 11 and main.profile.data["keys"] >= 1, "a gate world's Stage 5 = the system's singularity: Singularities 10 -> 11, +1 Key")
	main._write()
	var stats: String = m.stats_text()
	_check(stats.contains("Worlds Cleansed:  12 /") and stats.contains("Singularities Defeated:  11 / 107") and stats.contains("Acts Cleared:  10 / 10") and stats.contains("Total Fights Won:  6"),
		"Profile / Stats: %s" % stats.replace("\n", " | "))
	main.queue_free()
	await _frames(2)
	var again := MainScene.instantiate()
	again.save_path = SAVE
	add_child(again)
	await _frames(3)
	_check(again.journey.worlds_cleansed() == 12 and again.journey.singularities_defeated() == 11 and again.journey.wardens_defeated() == 2,
		"counters survive a restart (12 worlds, 11 singularities, 2 wardens)")
	# Map: colours are NOT re-rolled when the map loads again.
	again.show_map()
	await _frames(2)
	var m2: CosmosMap = again.map
	m2.open_galaxy(2)
	var h1: float = m2.node_buttons[3].get_child(0).material.get_shader_parameter("hue_shift")
	m2.open_universe()
	m2.open_galaxy(2)
	var h2: float = m2.node_buttons[3].get_child(0).material.get_shader_parameter("hue_shift")
	_check(is_equal_approx(h1, h2) and is_equal_approx(h1, fposmod(float(Cosmos.system(2, 4)["hue"]), 1.0)), "opening a map again keeps every colour (hue %.3f)" % h1)
	# Yellow warns once per world; Red / Skull every time.
	var y_key: String = Cosmos.worlds(2, 1)[1]["key"]
	again.journey.c["cleansed"].append(Cosmos.worlds(2, 1)[0]["key"])
	for uid in again.profile.team_uids(4):
		again.profile.unit(uid)["level"] = 30
	var rec: int = Cosmos.world_by_key(y_key)["rec"]
	var d := Journey.danger(30, rec)
	m2.request_play(y_key, 0)
	var first: bool = m2.warn_panel.visible
	await _click(m2.warn_go)
	await _frames(3)
	again.show_map()
	await _frames(2)
	m2.request_play(y_key, 0)
	var second: bool = again.map.warn_panel.visible
	_check(d == "yellow" and first and not second, "Yellow (1-4 below) warns once per world (rec Lv%d, team Lv30)" % rec)
	again.queue_free()
	await _frames(2)
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


# ---------------------------------------------------------------- U-POPUP

func _test_popup() -> void:
	_log("\n== U-POPUP: combat pop-up (20 taps) ==")
	var main := MainScene.instantiate()
	main.save_path = SAVE
	add_child(main)
	await _frames(3)
	main.save["intro_seen"] = true
	main.save["slot4_notice"] = true
	main.save["act_intros"] = [1, 2]
	main.save["cleared_acts"] = [1]
	main.profile.choose_starter(Profile.STARTERS[0])
	for id in ["biotech_01_medic_water", "titan_01_shield_wood", "spectre_01_rogue_dark"]:
		main.profile.auto_slot(main.profile.add_unit(id, 2, 10))
	main.start_act(2, 0, false)
	await _frames(8)
	var b = main.battle
	for k in 200:
		if b.board.state == Board.State.READY and b._player_turn:
			break
		await _frames(1)
	var pop: SkillPopup = b.skill_popup
	_check(not "replace_button" in pop and pop.use_button.text == "USE" and pop.details_button.text == "DETAILS" and pop.close_button.text == "CLOSE",
		"pop-up buttons: USE, DETAILS, CLOSE only (no REPLACE / SWAP / team change in combat)")
	var stayed := 0
	var inside_ok := true
	var lock_ok := true
	for t in 20:
		var i: int = t % b.team_views.size()
		await _tap_plate(b, i)
		var opened: bool = pop.visible and pop.member_index == i
		if t == 0:
			await _click(pop.close_button)   # within 0.2 s of opening: ignored
			lock_ok = pop.visible
		await get_tree().create_timer(0.25).timeout
		_tap(pop._title.get_global_rect().get_center())   # inside the box: nothing happens
		await _frames(3)
		inside_ok = inside_ok and pop.visible
		var still: bool = pop.visible
		await _click(pop.close_button)
		await _frames(3)
		if opened and still and not pop.visible:
			stayed += 1
	_log("INFO  20 taps on head plates in a real battle: %d opened and stayed open until CLOSE" % stayed)
	_check(stayed == 20, "tap a portrait 20 times: %d/20 open and stay open until CLOSE" % stayed)
	_check(lock_ok, "for 0.2 s after opening, a tap can't close it (the tap that opened it can't also close it)")
	_check(inside_ok, "tapping inside the pop-up does NOT close it")
	await _tap_plate(b, 0)
	await get_tree().create_timer(0.25).timeout
	_tap(Vector2(540, 60))   # the dark area outside the box
	await _frames(3)
	_check(not pop.visible, "a tap on the dark area OUTSIDE the pop-up closes it")
	b.team.skill_turns[0] = 3
	await _tap_plate(b, 0)
	var greyed: bool = pop.use_button.disabled
	await get_tree().create_timer(0.25).timeout
	await _click(pop.close_button)
	b.team.skill_turns[0] = 0
	await _tap_plate(b, 0)
	var ready: bool = not pop.use_button.disabled
	await get_tree().create_timer(0.25).timeout
	await _click(pop.details_button)
	await _frames(3)
	var ud = b.unit_detail
	_check(greyed and ready, "USE is greyed out until the skill is READY, then it works")
	_check(ud.visible and not ud.use_core_button.visible and not ud.evolve_button.visible and not ud.lock_button.visible and not ud.retire_button.visible,
		"DETAILS: the full detail screen, read-only in combat (no train / evolve / lock / retire)")
	ud.close()
	main.queue_free()
	await _frames(2)
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


# ---------------------------------------------------------------- U-STORY-B (Part B story)

func _test_story_b() -> void:
	_log("\n== U-STORY-B: the post-game story (after Reaper-0) ==")
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var main := MainScene.instantiate()
	main.save_path = SAVE
	add_child(main)
	await _frames(3)
	main.save["intro_seen"] = true
	main.profile.choose_starter(Profile.STARTERS[0])
	main.save["cleared_acts"] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	main.show_map()
	await _frames(3)
	var m: CosmosMap = main.map
	var beat: StoryBeat = m.story_beat
	_check(not beat.is_open(), "before Reaper-0: no Final Arc Intro")
	main.save["cleared_acts"].append(10)
	for a in Cosmos.ACTS:
		main.save["codex"].append(a.singularity_name)
	main.show_map()
	await _frames(3)
	var arc := "\n".join(PackedStringArray(StoryText.FINAL_ARC_INTRO))
	_check(beat.is_open() and beat.shown_text() == arc, "after Reaper-0: the Final Arc Intro (6 lines, full screen) the first time the universe map opens")
	await _shot("story_b1_final_arc_intro")
	beat.close()
	await _frames(2)
	main.show_map()
	await _frames(3)
	_check(not beat.is_open() and main.journey.story_seen("final_arc"), "... and only once")
	# Ring 1 + Tide Galaxy intros, chained, the first time you enter Galaxy 2.
	m.open_galaxy(2)
	await _frames(3)
	var ring1: bool = beat.is_open() and beat._speaker.text == "RING 1  ·  GALAXIES 2-4" and beat.shown_text() == "\n".join(PackedStringArray(StoryText.RING_INTROS[1]))
	await _shot("story_b2_ring1_intro")
	beat.close()
	await _frames(3)
	var tide: bool = beat.is_open() and beat._speaker.text.contains("TIDE GALAXY") and beat.shown_text() == "\n".join(PackedStringArray(StoryText.GALAXY_INTROS[2]))
	await _shot("story_b3_tide_galaxy_intro")
	beat.close()
	await _frames(2)
	_check(ring1 and tide, "entering Galaxy 2: the Ring 1 intro, then the Tide Galaxy intro")
	m.open_universe()
	m.open_galaxy(3)
	await _frames(3)
	var thorn_only: bool = beat.is_open() and beat._speaker.text.contains("THORN GALAXY")
	beat.close()
	await _frames(2)
	m.open_universe()
	m.open_galaxy(2)
	await _frames(3)
	var none_again: bool = not beat.is_open()
	m.open_universe()
	m.open_galaxy(6)
	await _frames(3)
	var locked_quiet: bool = not beat.is_open()
	_check(thorn_only and none_again and locked_quiet, "Ring intros once per ring, galaxy intros once per galaxy; previewing a locked galaxy (Ember) plays nothing")
	# The cleansing pop-up: the first world cleansed outside the Acts.
	m.open_universe()
	main.journey.c["cleansed"].append(Cosmos.worlds(2, 1)[0]["key"])
	main.show_map()
	await _frames(3)
	var popup: bool = beat.is_open() and beat._speaker.text == "WORLD CLEANSED" and beat.shown_text().contains("Technomancy can no longer spread from this world")
	await _shot("story_b4_cleanse_popup")
	var vw := get_viewport().get_visible_rect().size.x
	popup = popup and beat._panel.get_global_rect().end.x <= vw
	beat.close()
	await _frames(2)
	main.show_map()
	await _frames(3)
	_check(popup and not beat.is_open(), "first world cleansed in free exploration: the WORLD CLEANSED pop-up, once")
	# The codex, from the map: 4-line entries, Year 61, Cleansing (with Bailey's fix 1).
	await _click(m.codex_button)
	var cx: CodexScreen = main.codex
	var entry := cx.page_text()
	_check(cx.visible and entry.contains("REAPER-0") and entry.contains("THE COLONY") and entry.contains("WHY IT WAS ABANDONED") and entry.contains(Cosmos.ACTS[9].codex_abandoned),
		"CODEX on the map: readable any time; opens on the last singularity defeated (Reaper-0), 4 lines")
	await _shot("story_b5_codex_reaper0")
	await _click(cx.prev_button)
	var browsed: bool = cx.page_text().contains("SERAPH ENFORCER")
	await _click(cx.tab_timeline)
	var tl := cx.page_text()
	await _shot("story_b6_codex_timeline_year61")
	await _click(cx.tab_cleansing)
	var cl := cx.page_text()
	await _shot("story_b7_codex_cleansing")
	_check(browsed and tl.contains("Year 61 · The real first splice") and tl.find("Year 61") > tl.find("Year 0-80") and tl.find("Year 61") < tl.find("Year 82"),
		"< > browse the 10 entries; after Reaper-0 the timeline adds \"Year 61 · The real first splice\" (between Year 0-80 and Year 82)")
	_check(cl.contains("Each exploration solar system's farthest world hides that system's singularity") and cl.contains("/ %d" % Cosmos.total_worlds()) and cl.contains("Your record:"),
		"CLEANSING page: what Cleansed means (\"Each exploration solar system's farthest world...\"), the totals and your record")
	await _click(cx.close_button)
	# The final outro: every world cleansed, all 107 singularities down.
	for g in range(1, 11):
		for sys in Cosmos.systems(g):
			for w in Cosmos.worlds(g, int(sys["s"])):
				if int(w["act"]) == 0 and not w["key"] in main.journey.c["cleansed"]:
					main.journey.c["cleansed"].append(w["key"])
					if w["gate"]:
						main.journey.c["singularities"].append(w["key"])
	main.show_map()
	await _frames(3)
	var fin: bool = beat.is_open() and beat.shown_text() == "\n".join(PackedStringArray(StoryText.FINAL_OUTRO))
	await _shot("story_b8_final_outro")
	beat.close()
	await _frames(2)
	_check(main.journey.universe_cleansed() and fin and not beat.shown_text().contains("The end") and not beat.shown_text().contains("thanks for playing"),
		"Worlds Cleansed %d/%d + Singularities %d/107: the final outro, no new boss, the universe stays open" % [main.journey.worlds_cleansed(), Cosmos.total_worlds(), main.journey.singularities_defeated()])
	main._write()
	main.queue_free()
	await _frames(2)
	var again := MainScene.instantiate()
	again.save_path = SAVE
	add_child(again)
	await _frames(3)
	again.show_map()
	await _frames(3)
	_check(not again.map.story_beat.is_open() and again.journey.story_seen("final_outro") and again.journey.story_seen("galaxy3"),
		"after a restart nothing replays (seen beats are saved)")
	# Part A layout: the longest Act outro fits its beat box.
	var b2: StoryBeat = again.map.story_beat
	b2.play([Cosmos.ACTS[5].outro_line], Cosmos.ACTS[5].outro_seconds, "")
	await _frames(3)
	var r := b2._panel.get_global_rect()
	_check(r.end.y < b2._timer_bar.get_global_rect().position.y, "the longest Act outro (Act 6, 3 lines) fits above the timer bar")
	await _shot("story_a_act06_outro")
	b2.close()
	again.queue_free()
	await _frames(2)
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _shot(n: String) -> void:
	await get_tree().create_timer(0.4).timeout   # story beats fade in over 0.25 s
	await _frames(2)
	if not DisplayServer.window_can_draw():
		RenderingServer.force_draw(false)
	var img := get_viewport().get_texture().get_image()
	if img and not img.is_empty():
		img.save_png(ProjectSettings.globalize_path("res://tests/screenshots/%s.png" % n))


func _tap_plate(b: Node, i: int) -> void:
	var v = b.team_views[i]
	var local: Vector2 = v.position + (v.hit_rect() as Rect2).get_center()
	var p: Vector2 = b.world.get_global_transform_with_canvas() * local
	_tap(p)
	await _frames(4)


func _tap(p: Vector2) -> void:
	_mouse(p, true)
	_mouse(p, false)


func _mouse(p: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	e.position = p
	e.global_position = p
	get_viewport().push_input(e, true)


func _click(button: Control) -> void:
	var p := button.get_global_rect().get_center()
	_mouse(p, true)
	await _frames(1)
	_mouse(p, false)
	await _frames(3)


# ---------------------------------------------------------------- helpers

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	_log(("PASS  " if ok else "FAIL  ") + what)


func _log(s: String) -> void:
	print(s)
	lines.append(s)


func _finish() -> void:
	var passed := 0
	for l in lines:
		if l.begins_with("PASS"):
			passed += 1
	_log("\n%d PASS, %d FAIL" % [passed, fails])
	var f := FileAccess.open("res://tests/report_universe.txt", FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	get_tree().quit()
