class_name Cosmos
extends RefCounted
## The whole universe, made from ONE fixed seed (SEED), so it is the same for every
## player, every time. Nothing here is saved: it is re-made the same on demand.
##
## Plain English:
##   Universe > 10 Galaxies > 10 Solar Systems each > 5-10 Worlds each > Stages.
##   - Galaxy 1 (Orbspire) is the centre. Rings round it: Ring 1 (Galaxies 2-4),
##     Ring 2 (5-7), Ring 3 (8-10). Farther out = higher level. Positions are the
##     10 galaxies painted in Bailey's universe picture (a random scatter).
##   - Inside a galaxy: the main system in the centre, 9 more scattered in 3 rings
##     round it (random angles and distances from the seed, no line, no grid).
##   - Inside a solar system: 5-10 worlds scattered round the STAR; closer to the
##     star = lower level.
##   - Main story = Galaxy 1, Systems 1-3: the 10 Stage 6 Acts, each one WORLD with
##     its 8 fights unchanged (System 1 = Acts 1-3, System 2 = Acts 4-7, System 3 =
##     Acts 8-10), plus optional side worlds so each story system has 5 worlds and
##     all 5 affinities. Everything else is generated exploration content.
##   - Affinities are MIXED everywhere: every galaxy has 2 systems of each affinity
##     (the system's singularity), every system has worlds of all 5 affinities, and
##     a world's Stages 1-4 mix 3+ affinities. About 1 world in 8 is PURE (all its
##     stages one affinity) - Bailey's choice, 2026-11-19.
##   - Colour is random VISUAL diversity (MapArt). Affinity is gameplay, shown by
##     the orb icon and the label. A blue planet can be a Fire world.
## Only the level you look at is built (load on tap); the totals only count.

const SEED := 20261119

## The 10 story Acts (Stage 6), in story order.
const ACTS: Array[ActData] = [
	preload("res://data/acts/act_01.tres"), preload("res://data/acts/act_02.tres"),
	preload("res://data/acts/act_03.tres"), preload("res://data/acts/act_04.tres"),
	preload("res://data/acts/act_05.tres"), preload("res://data/acts/act_06.tres"),
	preload("res://data/acts/act_07.tres"), preload("res://data/acts/act_08.tres"),
	preload("res://data/acts/act_09.tres"), preload("res://data/acts/act_10.tres"),
]

const GALAXY_NAMES := ["Orbspire", "Tide", "Thorn", "Dawn", "Void", "Ember", "Frost", "Storm", "Bloom", "Core"]
## Recommended level band per galaxy (overlaps on purpose inside a ring).
const BANDS := [[1, 30], [31, 50], [41, 60], [51, 70], [61, 80], [71, 90], [81, 100], [91, 105], [101, 115], [111, 120]]
const GALAXY_RING := [0, 1, 1, 1, 2, 2, 2, 3, 3, 3]
## Where each galaxy sits on the universe picture (0-1): the 10 galaxies painted in
## it, measured by tools/analyze_world_art.gd. Positions and colours APPROVED by
## Bailey on 2026-11-19 (calibration screenshots) and LOCKED: see APPROVED_LAYOUT.
const GALAXY_POS := [Vector2(0.501, 0.486),
	Vector2(0.319, 0.849), Vector2(0.859, 0.637), Vector2(0.624, 0.153),
	Vector2(0.251, 0.169), Vector2(0.136, 0.669), Vector2(0.107, 0.407),
	Vector2(0.894, 0.188), Vector2(0.734, 0.846), Vector2(0.903, 0.364)]
## The colour each galaxy is shown in (0-1 hue): the colour of its painted galaxy,
## except Thorn (green) and Bloom (pink), moved so no two galaxies in the same ring
## are within 0.15. Galaxy 1 (multi-coloured centre) gets a seeded random colour.
const GALAXY_SEEN_HUE := [-1.0, 0.661, 0.36, 0.064, 0.771, 0.088, 0.462, 0.606, 0.83, 0.004]

const ALL5 := [Element.Type.FIRE, Element.Type.WATER, Element.Type.WOOD, Element.Type.LIGHT, Element.Type.DARK]
## Story systems: their worlds in order from the star outward. Numbers = Act,
## element names = an optional side world of that affinity.
const STORY_WORLDS := {
	1: [1, Element.Type.LIGHT, 2, Element.Type.DARK, 3],
	2: [4, 5, Element.Type.WOOD, 6, 7],
	3: [8, Element.Type.FIRE, 9, Element.Type.WATER, 10],
}
const STORY_SYSTEM_NAMES := {1: "Orbspire", 2: "Spire", 3: "Core"}
## The singularity affinity of the 3 story systems (their last Act's boss).
const STORY_SYSTEM_ELEMENT := {1: Element.Type.WOOD, 2: Element.Type.WATER, 3: Element.Type.DARK}
## The first Act of each story system (its side worlds open when it is cleared).
const STORY_FIRST_ACT := {1: 1, 2: 4, 3: 8}
const STORY_LAST_ACT := {1: 3, 2: 7, 3: 10}

## Typical team for tuning exploration fights (the Stage 6 reference team).
const REF_IDS := ["berserker_01_angel_fire", "biotech_01_medic_water", "titan_01_shield_wood", "spectre_01_rogue_dark"]
## Per stage (1-5): good-play turns to win and turns a team that does nothing lasts.
## Stages 1-4 add up to 15 turns; the Stage 5 boss takes 9 (8-10 with the ring step).
const GOOD_TURNS := [3, 3, 4, 5, 9]
const IDLE_TURNS := [10, 10, 9, 8, 8]
## XP per stage = XP for the next level at the recommended level x this x STAGE_XP.
const XP_SHARE := 0.10
const XP_SHARE_SIDE := 0.25
const STAGE_XP := [1.0, 1.0, 1.2, 1.5, 2.5]
## Every ring of systems farther out: +4% enemy HP / ATK (as Stage 6, +4% per Act).
const RING_STEP := 1.04
const PURE_SHARE := 0.125

const PRE := ["Kel", "Vor", "Ash", "Ryn", "Tal", "Zer", "Mor", "Cyr", "Lun", "Ves", "Dra", "Hel", "Ix", "Nau",
	"Ora", "Pyr", "Sol", "Tey", "Ul", "Xan", "Bel", "Cor", "Eld", "Fen", "Gal", "Hal", "Ith", "Jor", "Kae",
	"Lyr", "Myr", "Nyx", "Obe", "Quel", "Rho", "Sar", "Thal", "Umb", "Val", "Wyr", "Yss", "Zan"]
const SUF := ["ara", "eon", "is", "ux", "oria", "ane", "eth", "ion", "ari", "ost", "yra", "undra", "esh", "iel",
	"ora", "an", "ix", "ova", "em", "ith"]
const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

static var _galaxies: Array = []
static var _systems := {}
static var _worlds := {}
static var _built := {}


# ---------------------------------------------------------------- galaxies

static func galaxies() -> Array:
	if _galaxies.is_empty():
		var rng := _rng(["galaxy-colours"])
		for i in 10:
			var g := i + 1
			var art := i % 2
			var seen: float = GALAXY_SEEN_HUE[i]
			if seen < 0.0:
				seen = rng.randf()
			var band: Array = BANDS[i]
			_galaxies.append({
				"g": g, "name": GALAXY_NAMES[i] + " Galaxy", "ring": GALAXY_RING[i],
				"band": band, "pos": GALAXY_POS[i], "art": art, "seen_hue": seen,
				"hue": fposmod(seen - float(MapArt.GALAXY_HUE[art]), 1.0),
				"sat": rng.randf_range(0.8, 1.0), "val": rng.randf_range(0.95, 1.05),
			})
	return _galaxies


static func galaxy(g: int) -> Dictionary:
	return galaxies()[g - 1]


## Highest level you can reach while fighting in this galaxy.
static func galaxy_cap(g: int) -> int:
	return int(BANDS[g - 1][1])


static func galaxies_in_ring(ring: int) -> Array:
	return galaxies().filter(func(x: Dictionary) -> bool: return x["ring"] == ring)


# ---------------------------------------------------------------- solar systems

static func systems(g: int) -> Array:
	if not _systems.has(g):
		_systems[g] = _make_systems(g)
	return _systems[g]


static func system(g: int, s: int) -> Dictionary:
	return systems(g)[s - 1]


static func is_story_system(g: int, s: int) -> bool:
	return g == 1 and s <= 3


static func _system_rings(g: int) -> Array:
	return [0, 1, 2, 1, 1, 2, 2, 3, 3, 3] if g == 1 else [0, 1, 1, 1, 2, 2, 2, 3, 3, 3]


## Recommended level band of a system in ring `ring` of galaxy g.
static func system_band(g: int, ring: int) -> Array:
	if g == 1:
		if ring == 0:
			return [1, 14]
		return [22 + 2 * ring, 24 + 2 * ring]
	var lo: int = BANDS[g - 1][0]
	var hi: int = BANDS[g - 1][1]
	var total := hi - lo + 1
	return [lo + roundi(total * ring / 4.0), lo + roundi(total * (ring + 1) / 4.0) - 1]


static func _make_systems(g: int) -> Array:
	var rng := _rng(["systems", g])
	var rings := _system_rings(g)
	var pos := _scatter(rng, rings, Vector2(0.5, 0.5), [Vector2.ZERO, Vector2(0.2, 0.25), Vector2(0.3, 0.35), Vector2(0.39, 0.43)], 0.2)
	# Singularity affinity: 2 of each per galaxy (story systems fixed in Galaxy 1).
	var elements: Array = []
	for e in ALL5:
		elements.append(e)
		elements.append(e)
	if g == 1:
		for s in STORY_SYSTEM_ELEMENT:
			elements.erase(STORY_SYSTEM_ELEMENT[s])
	_shuffle(rng, elements)
	var names := _unique_roots(rng, 10)
	var out: Array = []
	for i in 10:
		var s := i + 1
		var story := is_story_system(g, s)
		var el: int = STORY_SYSTEM_ELEMENT[s] if story else elements.pop_back()
		var ring: int = rings[i]
		var band: Array = [1, 14] if story and s == 1 else ([14, 22] if story and s == 2 else ([22, 30] if story else system_band(g, ring)))
		var root: String = STORY_SYSTEM_NAMES[s] if story else names[i]
		out.append({
			"g": g, "s": s, "key": "%d-%d" % [g, s], "name": root + " System", "root": root,
			"pos": pos[i], "ring": ring, "story": story, "element": el, "band": band,
			"n_worlds": 5 if story else rng.randi_range(5, 10), "art": rng.randi_range(0, 2),
			"sat": rng.randf_range(0.8, 1.0), "val": rng.randf_range(0.95, 1.05),
		})
	# Colours: every system its own, no two neighbours within 0.15, all hues used.
	var src: Array = out.map(func(x: Dictionary) -> float: return MapArt.SYSTEM_HUE[x["art"]])
	var hues := _assign_hues(_rng(["system-colours", g]), pos, src, [])
	for i in 10:
		out[i]["hue"] = hues[i]
		out[i]["seen_hue"] = MapArt.seen_hue(src[i], hues[i])
	return out


# ---------------------------------------------------------------- worlds

static func worlds(g: int, s: int) -> Array:
	var key := "%d-%d" % [g, s]
	if not _worlds.has(key):
		_worlds[key] = _make_worlds(g, s)
	return _worlds[key]


static func world(g: int, s: int, w: int) -> Dictionary:
	return worlds(g, s)[w - 1]


static func world_by_key(key: String) -> Dictionary:
	var p := key.split("-")
	return world(int(p[0]), int(p[1]), int(p[2]))


## In STORY_WORLDS the Act numbers and the side worlds' Element values are both
## ints, so side worlds are told apart by position (these slots, 0-based).
const SIDE_SLOTS := {1: [1, 3], 2: [2], 3: [1, 3]}


## The world that holds story Act n ("g-s-w").
static func act_world_key(n: int) -> String:
	for s in STORY_WORLDS:
		var list: Array = STORY_WORLDS[s]
		for i in list.size():
			if not i in SIDE_SLOTS[s] and int(list[i]) == n:
				return "1-%d-%d" % [s, i + 1]
	return ""


static func _make_worlds(g: int, s: int) -> Array:
	var sys := system(g, s)
	var rng := _rng(["worlds", g, s])
	var n: int = sys["n_worlds"]
	var sun: Vector2 = MapArt.SYSTEM_SUN[sys["art"]]
	var pos := _fan(rng, sun, n)
	var story: bool = sys["story"]
	# Main affinity of each world: all 5 in every system, as even as possible;
	# the farthest world (the gate) holds the system's singularity affinity.
	var els: Array = []
	if story:
		for i in n:
			var slot: int = STORY_WORLDS[s][i]
			els.append(ACTS[slot - 1].element if not i in SIDE_SLOTS[s] else slot)
	else:
		for i in n:
			els.append(ALL5[i % 5])
		els.erase(sys["element"])
		_shuffle(rng, els)
		els.append(sys["element"])
	var band: Array = sys["band"]
	var out: Array = []
	for i in n:
		var act := 0
		var side := false
		if story:
			side = i in SIDE_SLOTS[s]
			act = 0 if side else int(STORY_WORLDS[s][i])
		var rec := 1
		if act > 0:
			rec = ACTS[act - 1].fights[0].expected_level
		elif story:
			rec = _side_rec(s, i)
		else:
			rec = roundi(lerpf(band[0], band[1], float(i) / maxf(n - 1, 1)))
		var ring := 0 if i == 0 else (_world_last_ring(n) if i == n - 1 else 1 + (i - 1) / 3)
		var el: int = els[i]
		var pure: bool = not story and rng.randf() < PURE_SHARE
		var name := ""
		if act > 0:
			name = ACTS[act - 1].colony_name
		else:
			name = "%s %s" % [sys["root"], ROMAN[i]]
		out.append({
			"g": g, "s": s, "w": i + 1, "key": "%d-%d-%d" % [g, s, i + 1], "name": name,
			"pos": pos[i], "ring": ring, "element": el, "pure": pure, "act": act, "side": side,
			"gate": i == n - 1, "rec": rec, "template": rng.randi_range(0, MapArt.WORLD_TEX.size() - 1),
			"sat": rng.randf_range(0.95, 1.2), "val": rng.randf_range(0.95, 1.08),
			"stage_count": ACTS[act - 1].fights.size() if act > 0 else 5,
			"stage_elements": [] if act > 0 else _stage_elements(rng, el, pure),
			"seed": rng.randi(),
		})
	# Colours: own hue each, neighbours >= 0.15 apart, 3+ hues per system, and never
	# the same planet picture with (almost) the same colour twice in one system.
	# Planet pictures shared out evenly (each used at most twice per system); if the
	# colour rules can't be met with them, shuffle them and try again.
	var crng := _rng(["world-colours", g, s])
	var tpl: Array = []
	for i in n:
		tpl.append(i % MapArt.WORLD_TEX.size())
	_shuffle(crng, tpl)
	var hues: Array = []
	for attempt in 30:
		var src: Array = tpl.map(func(t: int) -> float: return MapArt.WORLD_HUE[t])
		hues = _assign_hues(crng, pos, src, tpl, attempt == 29)
		if not hues.is_empty():
			break
		_shuffle(crng, tpl)
	for i in n:
		out[i]["template"] = tpl[i]
		out[i]["hue"] = hues[i]
		out[i]["seen_hue"] = MapArt.seen_hue(MapArt.WORLD_HUE[tpl[i]], hues[i])
	return out


static func _world_last_ring(n: int) -> int:
	return 1 + (n - 3) / 3 + 1 if n > 2 else 1


## Side worlds in story systems: halfway between the Acts on either side.
static func _side_rec(s: int, i: int) -> int:
	var list: Array = STORY_WORLDS[s]
	var before: int = ACTS[int(list[i - 1]) - 1].fights[0].expected_level
	var after: int = ACTS[int(list[i + 1]) - 1].fights[0].expected_level
	return roundi((before + after) / 2.0)


## Enemy affinities for Stages 1-5. Pure: all the world's affinity. Mixed: Stages
## 1-4 use 3+ affinities: the main one, one it is strong / weak against (the
## Stage 4 Warden), and at least one more. Stage 5 (the boss) = the main affinity.
static func _stage_elements(rng: RandomNumberGenerator, main: int, pure: bool) -> Array:
	var counts := [rng.randi_range(1, 2), rng.randi_range(1, 2), 2]
	if pure:
		var out: Array = []
		for c in counts:
			var row: Array = []
			for k in c:
				row.append(main)
			out.append(row)
		out.append([main])
		out.append([main])
		return out
	var related := related_elements(main)
	var r: int = related[rng.randi_range(0, related.size() - 1)]
	var others: Array = ALL5.filter(func(e: int) -> bool: return e != main and e != r)
	var other: int = others[rng.randi_range(0, others.size() - 1)]
	var slots: Array = [main, other]
	var total: int = counts[0] + counts[1] + counts[2]
	while slots.size() < total:
		slots.append(ALL5[rng.randi_range(0, 4)])
	_shuffle(rng, slots)
	var out: Array = []
	var k := 0
	for c in counts:
		out.append(slots.slice(k, k + c))
		k += c
	out.append([r])
	out.append([main])
	return out


## The affinities this one is strong or weak against (Light <-> Dark).
static func related_elements(e: int) -> Array:
	if Element.is_light_or_dark(e):
		return [Element.Type.DARK if e == Element.Type.LIGHT else Element.Type.LIGHT]
	return [Element.BEATS[e], Element.beaten_by(e)]


# ---------------------------------------------------------------- fights

## The fights of a world as an Act: story worlds are the Stage 6 Acts unchanged;
## the rest are made here (enemies from the 50 designs, tuned to the typical team
## at the world's recommended level).
static func build_world(g: int, s: int, w: int) -> ActData:
	var wd := world(g, s, w)
	if int(wd["act"]) > 0:
		return ACTS[int(wd["act"]) - 1]
	var key: String = wd["key"]
	if _built.has(key):
		return _built[key]
	var sys := system(g, s)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(wd["seed"])
	var a := ActData.new()
	a.act_number = 0
	a.world_key = key
	a.colony_name = wd["name"]
	a.colony_kind = "%s world" % MapArt.WORLD_NAMES[wd["template"]]
	a.element = wd["element"]
	a.rec_level = wd["rec"]
	a.level_cap = galaxy_cap(g)
	a.reward_act = clampi(roundi(float(wd["rec"]) / 3.0), 1, 40)
	a.is_gate = wd["gate"]
	a.pure = wd["pure"]
	var arena_act: ActData = ACTS[rng.randi_range(0, ACTS.size() - 1)]
	a.arena = arena_act.arena
	a.arena_hue = wd["hue"]
	var team := ref_team(wd["rec"])
	var used := {}
	var stage_els: Array = wd["stage_elements"]
	# +4% per ring: usually the higher level already makes outer rings stronger;
	# where it doesn't (the narrow bands of Galaxies 8-10) this floor adds the rest.
	var base_ring := 1 if g == 1 else 0
	var base_rec: int = system_band(g, base_ring)[0]
	var power := float(BalanceSim.team_hp(team)) / BalanceSim.team_hp(ref_team(base_rec))
	var ring_mult := maxf(1.0, pow(RING_STEP, maxi(int(sys["ring"]) - base_ring, 0)) / power)
	var share := XP_SHARE_SIDE if bool(wd["side"]) else XP_SHARE
	for i in 5:
		var f := FightData.new()
		var enemies: Array[FighterData] = []
		var row: Array = stage_els[i]
		for el in row:
			var size := 1.0 if i < 3 else (1.25 if i == 3 else 1.45)
			var d := EnemyDesigns.make(_pick_design(rng, el, used), size)
			if i >= 3:
				d.is_boss = true
				d.armored = true
				d.element_shield = true   # the element it resists does nothing (mixed teams needed)
				d.title = "Singularity" if i == 4 and a.is_gate else "Warden"
				if i == 4 and a.is_gate:
					d.display_name = "%s-%d" % [String(sys["root"]).to_upper(), rng.randi_range(2, 99)]
			enemies.append(d)
		tune(enemies, team, GOOD_TURNS[i], IDLE_TURNS[i])
		for d in enemies:
			d.max_hp = roundi(d.max_hp * ring_mult)
			d.atk = roundi(d.atk * ring_mult)
		f.enemies = enemies
		f.expected_level = wd["rec"]
		f.xp = maxi(10, roundi(PROGRESSION.xp_to_next(wd["rec"]) * share * float(STAGE_XP[i])))
		var label := "WARDEN" if i == 3 else ("SINGULARITY" if a.is_gate else "WORLD BOSS") if i == 4 else ""
		f.display_name = "STAGE %d/5%s" % [i + 1, ("  ·  " + label) if label != "" else ""]
		a.fights.append(f)
	a.singularity_name = a.fights[4].enemies[0].display_name
	if _built.size() > 12:
		_built.clear()
	_built[key] = a
	return a


const PROGRESSION: ProgressionTuning = preload("res://data/progression.tres")
const ECONOMY: EconomyTuning = preload("res://data/economy.tres")


static func _pick_design(rng: RandomNumberGenerator, el: int, used: Dictionary) -> String:
	var pool: Array = EnemyDesigns.of_element(el)
	var fresh := pool.filter(func(k: String) -> bool: return not used.has(k))
	if fresh.is_empty():
		fresh = pool
	var key: String = fresh[rng.randi_range(0, fresh.size() - 1)]
	used[key] = true
	return key


## The typical team at a level: the 4 reference hunters, evolved as the real game
## requires at that level, at the rarity most players have by then.
static func ref_team(level: int, ids: Array = REF_IDS, rarity_override := 0.0) -> Array[FighterData]:
	var rarity := 1.0 if level < 20 else (1.07 if level <= 60 else (1.14 if level <= 90 else 1.2))
	if rarity_override > 0.0:
		rarity = rarity_override
	var out: Array[FighterData] = []
	for id in ids:
		var f := CombatRules.preview_at_level(Catalog.template(id), level)
		var c: FighterData = f.duplicate()
		c.max_hp = roundi(f.max_hp * rarity)
		c.atk = roundi(f.atk * rarity)
		c.rcv = roundi(f.rcv * rarity)
		out.append(c)
	return out


## Sets HP and ATK so the team needs `good` turns of good play (element-neutral,
## through the real damage code) and lasts `idle` enemy turns doing nothing.
static func tune(enemies: Array[FighterData], team: Array[FighterData], good: int, idle: int) -> void:
	var probe: Array[FighterData] = []
	for d in enemies:
		var c: FighterData = d.duplicate()
		c.element = Element.Type.NONE
		probe.append(c)
	# HP in the MIDDLE of the range that takes exactly `good` turns (not at its
	# edge), so small changes don't add a turn.
	var top := _max_hp_for(probe, team, good)
	var bottom := _max_hp_for(probe, team, good - 1) if good > 1 else 1
	var team_hp := BalanceSim.team_hp(team)
	var atk := ceili(float(team_hp) / idle / enemies.size())
	for d in enemies:
		d.max_hp = (top + bottom) / 2
		d.atk = atk


## The most HP each enemy can have and still fall within `turns` good turns.
static func _max_hp_for(probe: Array[FighterData], team: Array[FighterData], turns: int) -> int:
	var lo := 1
	var hi := 64
	while _turns_at(probe, team, hi) <= turns and hi < 100000000:
		lo = hi
		hi *= 2
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if _turns_at(probe, team, mid) <= turns:
			lo = mid
		else:
			hi = mid
	return lo


static func _turns_at(probe: Array[FighterData], team: Array[FighterData], hp: int) -> int:
	for d in probe:
		d.max_hp = hp
	return BalanceSim.turns_to_win(probe, team, "GOOD")


# ---------------------------------------------------------------- the approved layout

## Fingerprint of every galaxy / system / world position, colour, picture and
## affinity, as Bailey approved them on 2026-11-19. universe_test fails if a code
## change would move or recolour anything; only change this after a new approval.
const APPROVED_LAYOUT := "e86c7e8ca18f292f0ad73a9b6b081237"


static func layout_fingerprint() -> String:
	var parts := PackedStringArray()
	for gal in galaxies():
		var g: int = gal["g"]
		parts.append("%d/%s/%.4f/%d" % [g, str(gal["pos"]), float(gal["hue"]), int(gal["art"])])
		for sys in systems(g):
			parts.append("%.4f/%s/%d/%d/%d" % [float(sys["hue"]), str(sys["pos"]), int(sys["art"]), int(sys["element"]), int(sys["n_worlds"])])
			for w in worlds(g, int(sys["s"])):
				parts.append("%.4f/%d/%s/%d/%d" % [float(w["hue"]), int(w["template"]), str(w["pos"]), int(w["element"]), int(w["rec"])])
	return "|".join(parts).md5_text()


# ---------------------------------------------------------------- totals

static func total_worlds() -> int:
	var n := 0
	for g in range(1, 11):
		for sys in systems(g):
			n += int(sys["n_worlds"])
	return n


## 10 Act bosses + 1 singularity per exploration system (97) = 107.
static func total_singularities() -> int:
	return ACTS.size() + 10 * 10 - 3


## Wardens: Act mini-bosses, plus Stage 4 and Stage 5 of every generated world
## (Stage 5 of a gate world is its system's singularity, not a Warden).
static func total_wardens() -> int:
	var n := 0
	for act in ACTS:
		for i in act.fights.size() - 1:
			if act.fights[i].enemies[0].is_boss:
				n += 1
	for g in range(1, 11):
		for sys in systems(g):
			var count: int = sys["n_worlds"]
			if sys["story"]:
				n += 2 * SIDE_SLOTS[sys["s"]].size()
			else:
				n += 2 * count - 1
	return n


# ---------------------------------------------------------------- helpers

static func _rng(parts: Array) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash("%d|%s" % [SEED, "|".join(PackedStringArray(parts.map(func(x) -> String: return str(x))))])
	return r


static func _shuffle(rng: RandomNumberGenerator, a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


static func _unique_roots(rng: RandomNumberGenerator, n: int) -> Array:
	var out: Array = []
	while out.size() < n:
		var r: String = PRE[rng.randi_range(0, PRE.size() - 1)] + SUF[rng.randi_range(0, SUF.size() - 1)]
		if not r in out:
			out.append(r)
	return out


## Points scattered round a centre in rings (ring 0 = the centre itself), random
## angles and distances, never closer than min_dist, always inside the picture.
static func _scatter(rng: RandomNumberGenerator, rings: Array, centre: Vector2, radii: Array, min_dist: float) -> Array:
	for attempt in 400:
		var pts: Array = []
		var ok := true
		var offset := {}
		var count := {}
		var seen := {}
		for r in rings:
			count[r] = int(count.get(r, 0)) + 1
		for i in rings.size():
			var r: int = rings[i]
			if r == 0:
				pts.append(centre)
				continue
			if not offset.has(r):
				offset[r] = rng.randf() * TAU
			var k: int = seen.get(r, 0)
			seen[r] = k + 1
			var placed := false
			for t in 40:
				var step := TAU / int(count[r])
				var ang: float = offset[r] + k * step + rng.randf_range(-0.32, 0.32) * step
				var rad := rng.randf_range(radii[r].x, radii[r].y)
				var p := centre + Vector2(cos(ang), sin(ang)) * rad
				p = p.clamp(Vector2(0.09, 0.09), Vector2(0.91, 0.91))
				var clear := true
				for q in pts:
					if (q as Vector2).distance_to(p) < min_dist:
						clear = false
						break
				if clear:
					pts.append(p)
					placed = true
					break
			if not placed:
				ok = false
				break
		if ok:
			return pts
	push_error("Cosmos._scatter: no layout found")
	return []


## Worlds fanned out from a sun near the top-right corner: world 0 nearest the
## star, the last (the gate) farthest; random angles towards the picture's middle.
static func _fan(rng: RandomNumberGenerator, sun: Vector2, n: int) -> Array:
	for attempt in 600:
		var pts: Array = []
		var ok := true
		for i in n:
			var placed := false
			for t in 60:
				var d := lerpf(0.27, 0.83, float(i) / maxf(n - 1, 1)) + rng.randf_range(-0.025, 0.025)
				var ang := deg_to_rad(rng.randf_range(98.0, 174.0))
				var p := sun + Vector2(cos(ang), sin(ang)) * d
				if p.x < 0.08 or p.x > 0.92 or p.y < 0.1 or p.y > 0.93:
					continue
				var clear := true
				for q in pts:
					if (q as Vector2).distance_to(p) < 0.145:
						clear = false
						break
				if clear:
					pts.append(p)
					placed = true
					break
			if not placed:
				ok = false
				break
		if ok:
			return pts
	push_error("Cosmos._fan: no layout found")
	return []


## Each node's 3 nearest neighbours (both ways): the "adjacent" pairs for colours.
static func neighbours(pos: Array) -> Array:
	var adj: Array = []
	for i in pos.size():
		adj.append([])
	for i in pos.size():
		var order: Array = range(pos.size())
		order.erase(i)
		order.sort_custom(func(a: int, b: int) -> bool: return (pos[i] as Vector2).distance_to(pos[a]) < (pos[i] as Vector2).distance_to(pos[b]))
		for j in order.slice(0, mini(3, order.size())):
			if not j in adj[i]:
				adj[i].append(j)
			if not i in adj[j]:
				adj[j].append(i)
	return adj


## Hue SHIFTS (0-1) for nodes at `pos` whose pictures have main colours `src`:
##   - the colours you see (picture colour + shift) are spread round the whole
##     wheel (one slot per node, evenly spaced: reds, golds, greens, blues, purples),
##   - adjacent nodes' hue shifts differ by >= 0.15 (so two neighbours using the
##     same picture never look alike),
##   - templates (worlds only): the same picture is never used twice in a system
##     with shifts within 0.15 (no two red Volcanic worlds).
## Returns [] if no answer was found (unless `must`: then a plain even spread).
static func _assign_hues(rng: RandomNumberGenerator, pos: Array, src: Array, templates: Array, must := true) -> Array:
	var n := pos.size()
	var adj := neighbours(pos)
	for attempt in (300 if must else 12):
		# One colour slot per node, spread evenly round the wheel (so every part of
		# the wheel is used), then a search that places each node on a free slot that
		# keeps every rule with the nodes already placed.
		var slots: Array = []
		for i in n:
			slots.append((i + rng.randf_range(0.4, 0.6)) / n)
		_shuffle(rng, slots)
		var order: Array = range(n)
		_shuffle(rng, order)
		var seen: Array = []
		var shifts: Array = []
		for i in n:
			seen.append(-1.0)
			shifts.append(0.0)
		var used: Array = []
		used.resize(n)
		used.fill(false)
		if _place(0, order, slots, used, seen, shifts, adj, src, templates, [0]):
			return shifts
	if not must:
		return []
	push_error("Cosmos._assign_hues: rules could not all be met")
	var out: Array = []
	for i in n:
		out.append(float(i) / n)
	return out


## steps[0] counts tries; a search that runs too long gives up (a new shuffle is cheaper).
static func _place(k: int, order: Array, slots: Array, used: Array, seen: Array, shifts: Array, adj: Array, src: Array, templates: Array, steps: Array) -> bool:
	if k == order.size():
		return true
	var i: int = order[k]
	for si in slots.size():
		if used[si]:
			continue
		steps[0] += 1
		if steps[0] > 400:
			return false
		var h: float = slots[si]
		var sh := fposmod(h - float(src[i]), 1.0)
		var ok := true
		for j in adj[i]:
			if float(seen[j]) >= 0.0 and MapArt.hue_gap(sh, shifts[j]) < 0.15:
				ok = false
				break
		if ok and not templates.is_empty():
			for j in order.size():
				if j != i and float(seen[j]) >= 0.0 and templates[j] == templates[i] and MapArt.hue_gap(sh, shifts[j]) < 0.15:
					ok = false
					break
		if not ok:
			continue
		used[si] = true
		seen[i] = h
		shifts[i] = sh
		if _place(k + 1, order, slots, used, seen, shifts, adj, src, templates, steps):
			return true
		used[si] = false
		seen[i] = -1.0
	return false
