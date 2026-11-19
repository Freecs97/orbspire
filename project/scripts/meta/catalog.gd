class_name Catalog
extends RefCounted
## All collectable characters and which character's Essence each enemy drops.
##   IDS          - the 20 humans (5 per type, one per element)
##   ENEMY_IDS    - 10 enemies made in the Lab from their own Essence (Stage 3 Part B)
##   RECOLOR_IDS  - 10 colour versions of those enemies (recoloured in code)
##   variant_ids() - every human and enemy in all 5 affinities ("<id>@water"...)
##   DUAL         - the proposed dual-affinity Stage 3 characters
##
## Plain English: a character "id" is its art file name, e.g. berserker_02_hulk_wood.
## The 4 story characters keep their data in data/team/, the other 16 in data/characters/.
## Every character uses its TYPE's skill set (shared for now).

const ECONOMY: EconomyTuning = preload("res://data/economy.tres")
const STORY_IDS := {
	"berserker_01_angel_fire": "res://data/team/fire_berserker.tres",
	"biotech_01_medic_water": "res://data/team/water_biotech.tres",
	"titan_01_shield_wood": "res://data/team/wood_titan.tres",
	"spectre_01_rogue_dark": "res://data/team/dark_spectre.tres",
}
const IDS := [
	"berserker_01_angel_fire", "berserker_02_hulk_wood", "berserker_03_thin_water", "berserker_04_void_dark", "berserker_05_solar_light",
	"biotech_01_medic_water", "biotech_02_splicer_wood", "biotech_03_healer_fire", "biotech_04_shadow_dark", "biotech_05_radiant_light",
	"spectre_01_rogue_dark", "spectre_02_mage_fire", "spectre_03_sniper_wood", "spectre_04_assassin_water", "spectre_05_infiltrator_light",
	"titan_01_shield_wood", "titan_02_guardian_fire", "titan_03_anchor_water", "titan_04_void_dark", "titan_05_sanctum_light",
]
## Stage 3 Part B: 10 enemies you can make in the Lab from their own Essence.
const ENEMY_IDS := [
	"enemy_ember_drone", "enemy_coolant_slime", "enemy_spore_sprout", "enemy_helios", "enemy_shade",
	"enemy_furnace_worker", "enemy_tide_guard", "enemy_vine_strangler", "enemy_prisma", "enemy_nix",
]
## Their colour versions (recoloured in code). They never appear in fights, so
## they come from Recruit and fight drops, at their original's rarity.
const RECOLOR_IDS := [
	"enemy_frost_drone", "enemy_moss_drone", "enemy_magma_slime", "enemy_bog_slime", "enemy_ash_sprout",
	"enemy_dew_sprout", "enemy_eclipse_drone", "enemy_glint", "enemy_umbral_wisp", "enemy_lux_imp",
]
## Bailey's friends (their own art + their own skills). Ultra-rare: they only come
## from a tiny chance after any won fight (economy friend_drop_chance), never from
## Recruit, the Lab or Essence. Always Prime rarity (fixed_rarity 3).
const FRIEND_IDS := ["friend_jake", "friend_johnny", "friend_khoel", "friend_logan"]
## Which enemy PNG drops which playable enemy's OWN Essence.
const OWN_ESSENCE := {
	"enemy_fire_ember_drone": "enemy_ember_drone", "enemy_water_coolant_slime": "enemy_coolant_slime",
	"enemy_wood_spore_sprout": "enemy_spore_sprout", "enemy_light_solar_drone": "enemy_helios",
	"enemy_dark_shadow_thief": "enemy_shade", "enemy_fire_furnace_worker": "enemy_furnace_worker",
	"enemy_water_tide_guard": "enemy_tide_guard", "enemy_wood_vine_strangler": "enemy_vine_strangler",
	"enemy_light_prism_wisp": "enemy_prisma", "enemy_dark_void_imp": "enemy_nix",
}
const TYPE_PREFIX := {
	FighterData.Role.BERSERKER: "berserker", FighterData.Role.TITAN: "titan",
	FighterData.Role.SPECTRE: "spectre", FighterData.Role.BIOTECH: "biotech",
}
const ELEMENT_SUFFIX := {
	Element.Type.FIRE: "fire", Element.Type.WATER: "water", Element.Type.WOOD: "wood",
	Element.Type.LIGHT: "light", Element.Type.DARK: "dark",
}

## COLOUR VERSIONS of every human and enemy character (not bosses, not friends):
## the same design, archetype and skills in each of the other 4 affinities,
## recoloured in code (Recolor, no new art), stats tilted about 5%. Ids are
## "<id>@<affinity>", e.g. "berserker_01_angel_fire@water". They come from Recruit
## and fight drops only: never in fights, never in the Lab, no Essence. Pairs the
## 10 named enemy colour versions (RECOLOR_IDS) already cover aren't made twice.
const VARIANT_SEP := "@"
## Stat tilt for the NEW affinity: [HP, ATK, RCV].
const TILT := {
	Element.Type.FIRE: [1.0, 1.05, 0.95], Element.Type.WATER: [1.0, 0.95, 1.05],
	Element.Type.WOOD: [1.05, 0.95, 1.0], Element.Type.LIGHT: [0.95, 1.0, 1.05],
	Element.Type.DARK: [0.95, 1.05, 1.0],
}
## Where each affinity sits on the colour wheel (degrees), to turn one into another.
const HUE_ANCHOR := {Element.Type.FIRE: 20.0, Element.Type.WOOD: 115.0, Element.Type.WATER: 205.0,
	Element.Type.LIGHT: 50.0, Element.Type.DARK: 280.0}

## DUAL AFFINITY (proposed, needs Bailey's OK): 25% of the Stage 3 final
## evolutions get a second (sub) affinity: 5 of 20 humans + 3 of 10 enemies.
## Only at Stage 3. The sub affinity attacks when ITS orbs are matched, for 1/3 of
## ATK (10% if it is the same as the main one): versatility, not raw power.
const DUAL := {
	"berserker_01_angel_fire": Element.Type.LIGHT,
	"berserker_05_solar_light": Element.Type.FIRE,
	"biotech_02_splicer_wood": Element.Type.DARK,
	"spectre_04_assassin_water": Element.Type.DARK,
	"titan_03_anchor_water": Element.Type.WOOD,
	"enemy_ember_drone": Element.Type.LIGHT,
	"enemy_vine_strangler": Element.Type.DARK,
	"enemy_nix": Element.Type.FIRE,
}
## Why each second affinity fits (shown in the report for approval).
const DUAL_WHY := {
	"berserker_01_angel_fire": "an angel of fire: wings of light around the flame",
	"berserker_05_solar_light": "a solar warrior: the sun's light is fire",
	"biotech_02_splicer_wood": "a gene-splicer: living growth bent by forbidden (dark) technomancy",
	"spectre_04_assassin_water": "an assassin: strikes from the shadows through the rain",
	"titan_03_anchor_water": "an anchor: deep-sea growth (kelp, coral) roots it to the seabed",
	"enemy_ember_drone": "an ember drone: its glowing core is a small lamp of light",
	"enemy_vine_strangler": "a strangler vine: grows in the dark and chokes the light out",
	"enemy_nix": "a void imp: hellfire burns in the void",
}

static var _cache := {}
static var _recolor_cache := {}
static var _variants: Array = []


## Everyone you can make in the Lab: the 20 humans + the 10 enemy characters.
static func lab_ids() -> Array:
	return IDS + ENEMY_IDS


## Every playable character (humans, enemies, colour versions, friends).
static func all_ids() -> Array:
	return IDS + ENEMY_IDS + RECOLOR_IDS + FRIEND_IDS + variant_ids()


static func is_friend(id: String) -> bool:
	return id in FRIEND_IDS


## Who Recruit / fight drops can give at this rarity: every human and every
## human colour version (any rarity), plus the enemy colour versions whose fixed
## rarity is exactly this one. (So the odds shown on the Recruit screen stay exact.)
static func pool_for_rarity(rarity: int) -> Array:
	var out: Array = IDS.duplicate()
	for id in variant_ids():
		if base_of(id) in IDS:
			out.append(id)
	for id in RECOLOR_IDS + variant_ids():
		if not base_of(id) in IDS and template(id).fixed_rarity == rarity:
			out.append(id)
	return out


# ---------------------------------------------------------------- colour versions

## Every colour version id (110: 80 human + 30 enemy).
static func variant_ids() -> Array:
	if _variants.is_empty():
		var taken := {}
		for rid in RECOLOR_IDS:
			var rt := template(rid)
			taken["%s|%d" % [rt.art.resource_path, rt.element]] = true
		for id in IDS + ENEMY_IDS:
			var t := template(id)
			for el in ELEMENT_SUFFIX:
				if el == t.element or taken.has("%s|%d" % [t.art.resource_path, el]):
					continue
				_variants.append("%s%s%s" % [id, VARIANT_SEP, ELEMENT_SUFFIX[el]])
	return _variants


static func is_variant(id: String) -> bool:
	return id.contains(VARIANT_SEP)


## Any colour version (a named enemy one or a generated one).
static func is_colour_version(id: String) -> bool:
	return is_variant(id) or id in RECOLOR_IDS


static func base_of(id: String) -> String:
	return id.get_slice(VARIANT_SEP, 0)


static func variant_element(id: String) -> int:
	var suffix := id.get_slice(VARIANT_SEP, 1)
	for el in ELEMENT_SUFFIX:
		if ELEMENT_SUFFIX[el] == suffix:
			return el
	return Element.Type.FIRE


static func _make_variant(id: String) -> FighterData:
	var base := template(base_of(id))
	var el := variant_element(id)
	var v: FighterData = base.duplicate()
	v.element = el
	v.design_id = id
	var old_word := Element.display_name(base.element).capitalize()
	var new_word := Element.display_name(el).capitalize()
	v.title = base.title.replace(old_word, new_word) if base.title.contains(old_word) else "%s %s" % [new_word, base.title]
	var tilt: Array = TILT[el]
	v.max_hp = roundi(base.max_hp * float(tilt[0]))
	v.atk = roundi(base.atk * float(tilt[1]))
	v.rcv = roundi(base.rcv * float(tilt[2]))
	v.recolor_hue = float(HUE_ANCHOR[el]) - float(HUE_ANCHOR.get(base.element, 20.0))
	v.recolor_value = 1.0
	v.recolor_tint = Color(1, 1, 1, 0)
	if el == Element.Type.LIGHT:
		v.recolor_value = 1.3
		v.recolor_tint = Color(1, 0.85, 0.45, 0.3)
	elif el == Element.Type.DARK:
		v.recolor_value = 0.65
		v.recolor_tint = Color(0.65, 0.35, 1, 0.35)
	elif base.element == Element.Type.DARK:
		v.recolor_value = 1.25
	elif base.element == Element.Type.LIGHT:
		v.recolor_value = 0.9
	return v


# ---------------------------------------------------------------- dual affinity

## The sub affinity of a character at this evolution stage (-1 = none). Stage 3 only.
static func sub_element(id: String, stage: int) -> int:
	if stage < 3:
		return -1
	return int(DUAL.get(base_of(id), -1))


## Its planned sub affinity, whatever its stage (-1 = not a dual character).
static func dual_of(id: String) -> int:
	return int(DUAL.get(base_of(id), -1))


## The playable enemy whose OWN Essence this enemy drops ("" if none).
static func own_essence_id(enemy: FighterData) -> String:
	if enemy.art == null:
		return ""
	return OWN_ESSENCE.get(enemy.art.resource_path.get_file().get_basename(), "")


static func template(id: String) -> FighterData:
	if not _cache.has(id):
		if is_variant(id):
			_cache[id] = _make_variant(id)
		else:
			var path: String = STORY_IDS.get(id, "res://data/characters/%s.tres" % id)
			_cache[id] = load(path)
	return _cache[id]


## The character of this type and element (there is exactly one of each).
static func id_for(role: int, element: int) -> String:
	var prefix: String = TYPE_PREFIX[role]
	var suffix: String = ELEMENT_SUFFIX[element]
	for id in IDS:
		if id.begins_with(prefix) and id.ends_with("_" + suffix):
			return id
	return ""


## Which character's Essence an enemy drops: same element, and a type that fits
## what the enemy is (brutes and guards -> Titan, cultists and medics -> Biotech,
## assassins and stalkers -> Spectre, everything else -> Berserker).
## Bosses rotate through the 4 types by Act.
static func essence_for(enemy: FighterData, act_number: int) -> String:
	var element := enemy.element
	if not ELEMENT_SUFFIX.has(element):
		element = Element.Type.FIRE
	var role := FighterData.Role.BERSERKER
	if enemy.is_boss and enemy.kind == &"boss" or (enemy.is_boss and enemy.art and enemy.art.resource_path.contains("/bosses/")):
		role = [FighterData.Role.BERSERKER, FighterData.Role.TITAN, FighterData.Role.SPECTRE, FighterData.Role.BIOTECH][(act_number - 1) % 4]
		return id_for(role, element)
	# Named enemies (e.g. HELIOS) are matched by what they are (their title, "Solar Drone").
	var n := (enemy.title if enemy.title != "" else enemy.display_name).to_lower()
	for w in ["brute", "guard", "golem", "turret", "zombie", "worker", "scrapbot", "biker"]:
		if n.contains(w):
			role = FighterData.Role.TITAN
	for w in ["cultist", "medic", "acolyte", "sprout", "slime", "mutant", "squire"]:
		if n.contains(w):
			role = FighterData.Role.BIOTECH
	for w in ["assassin", "stalker", "thief", "sniper", "hacker", "ghost", "decoy", "mimic", "imp"]:
		if n.contains(w):
			role = FighterData.Role.SPECTRE
	return id_for(role, element)


## The character's art at an evolution stage (1-3). Stage 2 / 3 art lives next to
## the base art as <id>_stage2.png / <id>_stage3.png; falls back to the base art.
static func art(id: String, stage := 1) -> Texture2D:
	if is_variant(id):
		# A colour version: the original's art at this stage, recoloured in code (cached).
		var key := "%s#%d" % [id, stage]
		if not _recolor_cache.has(key):
			var v := template(id)
			_recolor_cache[key] = Recolor.apply(art(base_of(id), stage), v.recolor_hue, v.recolor_value, v.recolor_tint)
		return _recolor_cache[key]
	if stage > 1:
		var path := "res://assets/characters/%s/%s_stage%d.png" % [id.get_slice("_", 0), id, stage]
		if ResourceLoader.exists(path):
			return load(path)
	var t := template(id)
	# Enemy colour versions: recolour the original PNG in code (cached).
	if not is_zero_approx(t.recolor_hue) or not is_equal_approx(t.recolor_value, 1.0) or t.recolor_tint.a > 0.0:
		if not _recolor_cache.has(id):
			_recolor_cache[id] = Recolor.apply(t.art, t.recolor_hue, t.recolor_value, t.recolor_tint)
		return _recolor_cache[id]
	return t.art


static func display_name(id: String) -> String:
	return template(id).display_name


static func rarity_name(r: int) -> String:
	return ECONOMY.rarity_names[clampi(r, 0, 5)]


static func rarity_color(r: int) -> Color:
	return [Color("8a8a96"), Color("9fc6d8"), Color("6dd38a"), Color("4fa8ff"), Color("c06bff"), Color("ffd23f")][clampi(r, 0, 5)]
