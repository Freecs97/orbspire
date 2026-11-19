class_name Catalog
extends RefCounted
## All collectable characters and which character's Essence each enemy drops.
##   IDS          - the 20 humans (5 per type, one per element)
##   ENEMY_IDS    - 10 enemies made in the Lab from their own Essence (Stage 3 Part B)
##   RECOLOR_IDS  - 10 colour versions of those enemies (recoloured in code)
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

static var _cache := {}
static var _recolor_cache := {}


## Everyone you can make in the Lab: the 20 humans + the 10 enemy characters.
static func lab_ids() -> Array:
	return IDS + ENEMY_IDS


## Every playable character (humans, enemies, enemy colour versions, friends).
static func all_ids() -> Array:
	return IDS + ENEMY_IDS + RECOLOR_IDS + FRIEND_IDS


static func is_friend(id: String) -> bool:
	return id in FRIEND_IDS


## Who Recruit / fight drops can give at this rarity: every human (any rarity)
## plus the enemy colour versions whose fixed rarity is exactly this one.
## (So the odds shown on the Recruit screen stay exact.)
static func pool_for_rarity(rarity: int) -> Array:
	var out: Array = IDS.duplicate()
	for id in RECOLOR_IDS:
		if template(id).fixed_rarity == rarity:
			out.append(id)
	return out


## The playable enemy whose OWN Essence this enemy drops ("" if none).
static func own_essence_id(enemy: FighterData) -> String:
	if enemy.art == null:
		return ""
	return OWN_ESSENCE.get(enemy.art.resource_path.get_file().get_basename(), "")


static func template(id: String) -> FighterData:
	if not _cache.has(id):
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
