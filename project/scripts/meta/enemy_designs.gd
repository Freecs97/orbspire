class_name EnemyDesigns
extends RefCounted
## All 50 enemy designs (assets/enemies/*.png): element, name, and the size they
## are drawn at in the Acts. The exploration worlds pick their enemies from here.
## Made by tools/list_enemy_designs.gd (re-run it if enemy art is added).
##   key: [element, NAME, figure_height, figure_width]
const DESIGNS := {
	"enemy_dark_dark_hacker": [6, "DARK HACKER", 310, 160],
	"enemy_dark_eclipse_assassin": [6, "ECLIPSE ASSASSIN", 310, 160],
	"enemy_dark_glitch_ghost": [6, "GLITCH GHOST", 240, 210],
	"enemy_dark_night_stalker": [6, "NIGHT STALKER", 310, 160],
	"enemy_dark_nightmare_drone": [6, "NIGHTMARE DRONE", 240, 210],
	"enemy_dark_reaper_acolyte": [6, "REAPER ACOLYTE", 310, 160],
	"enemy_dark_shadow_thief": [6, "SHADOW THIEF", 260, 199],
	"enemy_dark_umbra_hound": [6, "UMBRA HOUND", 260, 260],
	"enemy_dark_void_cultist": [6, "VOID CULTIST", 310, 160],
	"enemy_dark_void_imp": [6, "VOID IMP", 240, 210],
	"enemy_fire_ash_imp": [0, "ASH IMP", 240, 210],
	"enemy_fire_ember_drone": [0, "EMBER DRONE", 260, 254],
	"enemy_fire_flame_turret": [0, "FLAME TURRET", 260, 260],
	"enemy_fire_forge_brute": [0, "FORGE BRUTE", 330, 230],
	"enemy_fire_furnace_worker": [0, "FURNACE WORKER", 260, 176],
	"enemy_fire_inferno_biker": [0, "INFERNO BIKER", 260, 151],
	"enemy_fire_molten_scrapbot": [0, "MOLTEN SCRAPBOT", 260, 192],
	"enemy_fire_plasma_hound": [0, "PLASMA HOUND", 260, 260],
	"enemy_fire_pyro_cultist": [0, "PYRO CULTIST", 310, 160],
	"enemy_fire_solar_flare_sprite": [0, "SOLAR FLARE SPRITE", 240, 210],
	"enemy_light_beacon_sniper": [5, "BEACON SNIPER", 310, 160],
	"enemy_light_dawn_acolyte": [5, "DAWN ACOLYTE", 310, 160],
	"enemy_light_halo_guard": [5, "HALO GUARD", 260, 190],
	"enemy_light_holo_decoy": [5, "HOLO DECOY", 310, 160],
	"enemy_light_light_cultist": [5, "LIGHT CULTIST", 310, 160],
	"enemy_light_mirror_mimic": [5, "MIRROR MIMIC", 310, 160],
	"enemy_light_prism_wisp": [5, "PRISM WISP", 240, 210],
	"enemy_light_radiant_sprite": [5, "RADIANT SPRITE", 240, 210],
	"enemy_light_solar_drone": [5, "SOLAR DRONE", 260, 208],
	"enemy_light_sun_squire": [5, "SUN SQUIRE", 310, 160],
	"enemy_water_bubble_bomber": [1, "BUBBLE BOMBER", 240, 210],
	"enemy_water_coolant_slime": [1, "COOLANT SLIME", 280, 190],
	"enemy_water_deep_diver_mutant": [1, "DEEP DIVER MUTANT", 260, 173],
	"enemy_water_drowned_drifter": [1, "DROWNED DRIFTER", 310, 160],
	"enemy_water_flood_medic": [1, "FLOOD MEDIC", 260, 140],
	"enemy_water_hydro_hacker": [1, "HYDRO HACKER", 310, 160],
	"enemy_water_kraken_spawnling": [1, "KRAKEN SPAWNLING", 240, 210],
	"enemy_water_pipe_crawler": [1, "PIPE CRAWLER", 260, 260],
	"enemy_water_rain_assassin": [1, "RAIN ASSASSIN", 260, 239],
	"enemy_water_tide_guard": [1, "TIDE GUARD", 330, 230],
	"enemy_wood_bio_hound": [2, "BIO HOUND", 260, 260],
	"enemy_wood_chloro_cultist": [2, "CHLORO CULTIST", 260, 138],
	"enemy_wood_greenhouse_mutant": [2, "GREENHOUSE MUTANT", 260, 165],
	"enemy_wood_moss_zombie": [2, "MOSS ZOMBIE", 310, 160],
	"enemy_wood_overgrowth_sproutling": [2, "OVERGROWTH SPROUTLING", 240, 210],
	"enemy_wood_pollen_wisp": [2, "POLLEN WISP", 240, 210],
	"enemy_wood_root_crawler": [2, "ROOT CRAWLER", 260, 260],
	"enemy_wood_spore_sprout": [2, "SPORE SPROUT", 260, 126],
	"enemy_wood_thorn_brute": [2, "THORN BRUTE", 260, 253],
	"enemy_wood_vine_strangler": [2, "VINE STRANGLER", 260, 203],
}

static var _by_element := {}


## Every design key of this element (10 each).
static func of_element(el: int) -> Array:
	if _by_element.is_empty():
		for k in DESIGNS:
			var e: int = DESIGNS[k][0]
			if not _by_element.has(e):
				_by_element[e] = []
			_by_element[e].append(k)
		for e in _by_element:
			_by_element[e].sort()
	return _by_element.get(el, [])


static func display_name(key: String) -> String:
	return DESIGNS[key][1]


## A fresh enemy data card for this design (stats are filled in by the caller).
## size_mult: Wardens and world bosses are drawn bigger.
static func make(key: String, size_mult := 1.0) -> FighterData:
	var d := FighterData.new()
	var row: Array = DESIGNS[key]
	d.display_name = row[1]
	d.element = row[0]
	d.role = FighterData.Role.ENEMY
	d.kind = &"art"
	d.art = load("res://assets/enemies/%s.png" % key)
	d.figure_height = float(row[2]) * size_mult
	d.figure_width = float(row[3]) * size_mult
	return d
