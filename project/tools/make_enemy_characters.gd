extends SceneTree
## Stage 3 Part B: writes the 10 playable enemies + their 10 colour versions to
## data/characters/enemy_*.tres (the approved table: docs/stage3_partb_enemy_table.md).
## Developer tool. Run:  --headless --path . --quit-after 60 -s res://tools/make_enemy_characters.gd
##
## Colour versions keep the original's archetype and kit (acting on the new
## element), with a small stat tilt, the original's rarity, and a code recolour.

const F := Element.Type.FIRE
const W := Element.Type.WATER
const G := Element.Type.WOOD
const LI := Element.Type.LIGHT
const D := Element.Type.DARK
const B := FighterData.Role.BERSERKER
const TI := FighterData.Role.TITAN
const S := FighterData.Role.SPECTRE
const BI := FighterData.Role.BIOTECH
const ROLE_WORD := ["Berserker", "Titan", "Spectre", "Biotech"]

## id, name, png, element, role, hp, atk, rcv, rarity, active, leader, passives, figure h, figure w
const BASE := [
	["enemy_ember_drone", "EMBER DRONE", "enemy_fire_ember_drone", F, B, 280, 88, 8, 0, &"cinder_burst", &"leader_kindling_swarm", [&"cleave", &"ambush", &"fire_atk_up"], 230.0, 200.0],
	["enemy_coolant_slime", "COOLANT SLIME", "enemy_water_coolant_slime", W, BI, 300, 62, 42, 0, &"coolant_flush", &"leader_coolant_loop", [&"rcv_up", &"overflow_heal", &"damage_resist"], 220.0, 220.0],
	["enemy_spore_sprout", "SPORE SPROUT", "enemy_wood_spore_sprout", G, BI, 320, 60, 40, 0, &"spore_puff", &"leader_germinate", [&"time_extend", &"rcv_up", &"last_stand"], 220.0, 180.0],
	["enemy_helios", "HELIOS", "enemy_light_solar_drone", LI, B, 300, 84, 9, 0, &"sunburst_charge", &"leader_solar_array", [&"cleave", &"orb_enhance", &"skill_boost"], 250.0, 210.0],
	["enemy_shade", "SHADE", "enemy_dark_shadow_thief", D, S, 200, 100, 6, 1, &"twin_shiv", &"leader_backstab", [&"ambush", &"finisher", &"bloodlust"], 320.0, 160.0],
	["enemy_furnace_worker", "FURNACE WORKER", "enemy_fire_furnace_worker", F, TI, 430, 70, 22, 1, &"heat_vent", &"leader_heat_shielding", [&"counter", &"hp_up", &"fire_atk_up"], 330.0, 220.0],
	["enemy_tide_guard", "TIDE GUARD", "enemy_water_tide_guard", W, TI, 420, 68, 24, 1, &"trident_wall", &"leader_wave_wall", [&"counter", &"rcv_up", &"last_stand"], 330.0, 220.0],
	["enemy_vine_strangler", "VINE STRANGLER", "enemy_wood_vine_strangler", G, S, 210, 98, 7, 2, &"strangle", &"leader_constrict", [&"finisher", &"combo_boost", &"skill_boost"], 340.0, 180.0],
	["enemy_prisma", "PRISMA", "enemy_light_prism_wisp", LI, BI, 310, 64, 42, 1, &"refract", &"leader_refraction", [&"rcv_up", &"field_medic", &"heart_charge"], 240.0, 200.0],
	["enemy_nix", "NIX", "enemy_dark_void_imp", D, S, 215, 92, 7, 1, &"void_bite", &"leader_void_hunger", [&"ambush", &"bloodlust", &"combo_boost"], 240.0, 210.0],
]

## id, name, base id, new element, hue turn (deg), brightness, tint
const VERSIONS := [
	["enemy_frost_drone", "FROST DRONE", "enemy_ember_drone", W, 185.0, 1.0, Color(1, 1, 1, 0)],
	["enemy_moss_drone", "MOSS DRONE", "enemy_ember_drone", G, 95.0, 1.0, Color(1, 1, 1, 0)],
	["enemy_magma_slime", "MAGMA SLIME", "enemy_coolant_slime", F, 170.0, 1.0, Color(1, 1, 1, 0)],
	["enemy_bog_slime", "BOG SLIME", "enemy_coolant_slime", G, -90.0, 1.0, Color(1, 1, 1, 0)],
	["enemy_ash_sprout", "ASH SPROUT", "enemy_spore_sprout", F, -65.0, 1.0, Color(1, 1, 1, 0)],
	["enemy_dew_sprout", "DEW SPROUT", "enemy_spore_sprout", W, 130.0, 1.0, Color(1, 1, 1, 0)],
	["enemy_eclipse_drone", "ECLIPSE DRONE", "enemy_helios", D, 230.0, 0.6, Color(0.65, 0.35, 1.0, 0.35)],
	["enemy_glint", "GLINT", "enemy_shade", LI, 130.0, 1.4, Color(1.0, 0.85, 0.45, 0.3)],
	["enemy_umbral_wisp", "UMBRAL WISP", "enemy_prisma", D, 230.0, 0.6, Color(0.65, 0.35, 1.0, 0.35)],
	["enemy_lux_imp", "LUX IMP", "enemy_nix", LI, 130.0, 1.4, Color(1.0, 0.85, 0.45, 0.3)],
]


func _init() -> void:
	var made := {}
	for r in BASE:
		var d := FighterData.new()
		d.display_name = r[1]
		d.element = r[3]
		d.role = r[4]
		d.title = "%s %s" % [Element.display_name(r[3]).capitalize(), ROLE_WORD[r[4]]]
		d.max_hp = r[5]
		d.atk = r[6]
		d.rcv = r[7]
		d.fixed_rarity = r[8]
		d.active_skill = r[9]
		d.leader_skill = r[10]
		var ps: Array[StringName] = []
		for p in r[11]:
			ps.append(p)
		d.passives = ps
		d.figure_height = r[12]
		d.figure_width = r[13]
		d.design_id = r[0]
		d.art = load("res://assets/enemies/%s.png" % r[2])
		_save(d, r[0])
		made[r[0]] = d
	for v in VERSIONS:
		var base: FighterData = made[v[2]]
		var d: FighterData = base.duplicate()
		d.display_name = v[1]
		d.element = v[3]
		d.title = "%s %s" % [Element.display_name(v[3]).capitalize(), ROLE_WORD[base.role]]
		d.recolor_hue = v[4]
		d.recolor_value = v[5]
		d.recolor_tint = v[6]
		d.design_id = v[0]
		# ~5% stat tilt by element.
		var tilt: Array = {F: [0.97, 1.05, 1.0], W: [1.0, 0.97, 1.12], G: [1.05, 1.0, 1.0], LI: [1.03, 0.97, 1.05], D: [0.97, 1.05, 1.0]}[v[3]]
		d.max_hp = roundi(base.max_hp * tilt[0])
		d.atk = roundi(base.atk * tilt[1])
		d.rcv = roundi(base.rcv * tilt[2])
		_save(d, v[0])
	quit()


func _save(d: FighterData, id: String) -> void:
	var path := "res://data/characters/%s.tres" % id
	var err := ResourceSaver.save(d, path)
	print("%s %-22s %-16s %-16s %3d/%3d/%2d  %s" % ["OK " if err == OK else "ERR", id, d.display_name, d.title, d.max_hp, d.atk, d.rcv, Catalog.rarity_name(d.fixed_rarity)])
