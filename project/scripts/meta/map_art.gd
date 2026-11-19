class_name MapArt
extends RefCounted
## Bailey's World_Building art (orbspire-art-organized/World_Building) and how the
## maps colour it.
##
## Plain English: there are only a few pictures (1 universe, 2 galaxies, 3 solar
## systems, 5 planets). Every galaxy / solar system / world picks one of them and
## gets its OWN hue shift from the fixed universe seed (Cosmos.SEED), so it looks
## the same for every player and after every restart.
##
## Colour is random VISUAL diversity. Affinity is gameplay, shown by the orb icon
## and the label. A blue planet can be a Fire world. Do NOT infer affinity from colour.
##
## The universe picture is NOT recoloured (it already has mixed colours). Orbs,
## characters, enemies and bosses are never recoloured by this (their own system).
## Measurements below come from tools/analyze_world_art.gd.

const SHADER := preload("res://assets/shaders/map_recolor.gdshader")

## Source file in World_Building -> file in this project (renamed: the originals
## have long auto-generated names). Folder, original name, project file.
const SOURCES := [
	["Universe", "gpt-image-2_5-flare_massive_universe_seen_from_far_away_dark_space_thousands_of_stars_10_distinct_ga-3_c004e9a3-a3a6-40bf-ab46-ae80212006bb.jpg", "universe_01.jpg"],
	["Galaxies", "gpt-image-2_5-flare_vast_barred_spiral_galaxy_dark_space_thousands_of_stars_mixed_gold_white_and_pur-0_8fc75eca-1175-442b-8162-d1b82222c540.jpg", "galaxy_a_barred_spiral.jpg"],
	["Galaxies", "gpt-image-2_5-flare_vast_spiral_galaxy_dark_space_thousands_of_stars_mixed_green_pink_and_gold_nebul-0_341a8cb3-838c-4d50-a015-2186cd36658c.jpg", "galaxy_b_spiral.jpg"],
	["Solar_System", "gpt-image-2_5-flare_solar_system_background_dark_space_one_large_sun_in_the_distance_3_small_planets-0_0b91ea6e-ae83-45ca-9b11-498fa3e5d009.jpg", "system_a.jpg"],
	["Solar_System", "gpt-image-2_5-flare_solar_system_background_dark_space_one_large_sun_in_the_distance_3_small_planets-0_97d3e096-b688-4fce-baf5-1a677630a35a.jpg", "system_b.jpg"],
	["Solar_System", "gpt-image-2_5-flare_solar_system_background_dark_space_one_large_sun_in_the_distance_3_small_planets-0_f589b37f-b3ab-4913-bd6b-ff551495d88e.jpg", "system_c.jpg"],
	["Worlds", "gpt-image-2_5-flare_single_planet_icon_desert_planet_sand_dunes_rocky_canyons_pale_atmosphere_isolat-0_6884a120-4ff3-494b-ba51-4f8c7d81a21b.jpg", "world_desert.jpg"],
	["Worlds", "gpt-image-2_5-flare_single_planet_icon_forest_planet_lush_continents_atmosphere_glow_clouds_and_rive-0_f9beb83c-1854-4275-abc2-72ea7673255c.jpg", "world_forest.jpg"],
	["Worlds", "gpt-image-2_5-flare_single_planet_icon_ice_planet_frozen_surface_glowing_cracks_cold_atmosphere_isol-0_276fdb92-f5cd-4db8-9f5a-ec73053fa2a3.jpg", "world_ice.jpg"],
	["Worlds", "gpt-image-2_5-flare_single_planet_icon_ocean_planet_deep_water_white_clouds_atmosphere_glow_isolated-0_ad81bbaa-a5d5-48e8-b17b-d9e043bd3dd1.jpg", "world_ocean.jpg"],
	["Worlds", "gpt-image-2_5-flare_single_planet_icon_volcanic_planet_glowing_lava_cracks_dark_rocky_surface_atmosp-0_1d71126c-77b9-4809-bf1f-1a690a8f11cd.jpg", "world_volcanic.jpg"],
]
## How many pictures each folder was expected to have (the master prompt) vs got.
const EXPECTED := {"Universe": 1, "Galaxies": 10, "Solar_System": 5, "Worlds": 6}
## Expected but not given yet (placeholder: the other pictures, recoloured).
const MISSING := ["Galaxies: 8 of 10 (2 given, recoloured for all 10)",
	"Solar_System: 2 of 5 templates (3 given)", "Worlds: City template (5 of 6 given)"]

const UNIVERSE := preload("res://assets/maps/universe_01.jpg")
const GALAXY_TEX: Array[Texture2D] = [preload("res://assets/maps/galaxy_a_barred_spiral.jpg"), preload("res://assets/maps/galaxy_b_spiral.jpg")]
## Main colour (hue 0-1) of each picture before any shift.
const GALAXY_HUE := [0.864, 0.062]
const SYSTEM_TEX: Array[Texture2D] = [preload("res://assets/maps/system_a.jpg"), preload("res://assets/maps/system_b.jpg"), preload("res://assets/maps/system_c.jpg")]
const SYSTEM_HUE := [0.922, 0.324, 0.871]
## Where the sun is in each solar-system picture (0-1).
const SYSTEM_SUN := [Vector2(0.850, 0.123), Vector2(0.811, 0.146), Vector2(0.862, 0.126)]
const WORLD_NAMES := ["Desert", "Forest", "Ice", "Ocean", "Volcanic"]
const WORLD_TEX: Array[Texture2D] = [preload("res://assets/maps/world_desert.jpg"), preload("res://assets/maps/world_forest.jpg"),
	preload("res://assets/maps/world_ice.jpg"), preload("res://assets/maps/world_ocean.jpg"), preload("res://assets/maps/world_volcanic.jpg")]
const WORLD_HUE := [0.070, 0.499, 0.575, 0.574, 0.030]
## The planet circle in each planet picture: centre x, centre y, radius (0-1).
const WORLD_CIRCLE := [Vector3(0.505, 0.526, 0.452), Vector3(0.495, 0.502, 0.463), Vector3(0.498, 0.509, 0.437),
	Vector3(0.498, 0.503, 0.462), Vector3(0.494, 0.494, 0.451)]


const SHADER_ADD := preload("res://assets/shaders/map_recolor_add.gdshader")


## A recolour material. circle.z > 0 cuts out a soft circle (centre x, y, radius).
## add = glow on top (dark parts vanish) instead of covering.
static func material(hue_shift: float, sat := 1.0, val := 1.0, circle := Vector3.ZERO, add := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER_ADD if add else SHADER
	m.set_shader_parameter("hue_shift", fposmod(hue_shift, 1.0))
	m.set_shader_parameter("sat_mul", sat)
	m.set_shader_parameter("val_mul", val)
	m.set_shader_parameter("circle_mask", circle.z > 0.0)
	if circle.z > 0.0:
		m.set_shader_parameter("mask_center", Vector2(circle.x, circle.y))
		m.set_shader_parameter("mask_radius", circle.z)
	return m


## circle = the map icon: a soft round crop that glows over the universe picture.
static func galaxy_material(gal: Dictionary, circle := false) -> ShaderMaterial:
	return material(gal["hue"], gal["sat"], gal["val"], Vector3(0.5, 0.5, 0.48) if circle else Vector3.ZERO, circle)


static func system_material(sys: Dictionary, sun_crop := false) -> ShaderMaterial:
	var sun: Vector2 = SYSTEM_SUN[sys["art"]]
	return material(sys["hue"], sys["sat"], sys["val"], Vector3(sun.x, sun.y, SUN_CROP) if sun_crop else Vector3.ZERO)


const SUN_CROP := 0.115


static func world_material(w: Dictionary) -> ShaderMaterial:
	var c: Vector3 = WORLD_CIRCLE[w["template"]]
	return material(w["hue"], w["sat"], w["val"], Vector3(c.x, c.y, c.z * 0.985))


## A small square around the sun of a solar-system picture (its map icon).
static func sun_icon(sys: Dictionary) -> AtlasTexture:
	var tex: Texture2D = SYSTEM_TEX[sys["art"]]
	var sun: Vector2 = SYSTEM_SUN[sys["art"]]
	var s := tex.get_size()
	var half := SUN_CROP * s.x
	var a := AtlasTexture.new()
	a.atlas = tex
	var rect := Rect2(sun.x * s.x - half, sun.y * s.y - half, half * 2.0, half * 2.0)
	# Keep the square inside the picture (the shader mask uses picture-wide UVs).
	rect.position.x = clampf(rect.position.x, 0.0, s.x - rect.size.x)
	rect.position.y = clampf(rect.position.y, 0.0, s.y - rect.size.y)
	a.region = rect
	return a


## The colour the player actually sees (picture's main colour + shift), 0-1.
static func seen_hue(source_hue: float, shift: float) -> float:
	return fposmod(source_hue + shift, 1.0)


## Distance between two hues round the colour wheel (0 - 0.5).
static func hue_gap(a: float, b: float) -> float:
	var d := absf(fposmod(a, 1.0) - fposmod(b, 1.0))
	return minf(d, 1.0 - d)
