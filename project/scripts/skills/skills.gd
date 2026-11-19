class_name Skills
extends RefCounted
## The skill catalogue: names, cooldowns and plain-English descriptions.
##
## Plain English: every skill has an id (like &"overrun"). Character .tres
## files list the ids they use: each CHARACTER has its own active skill, leader
## skill and 3 passives (Stage 3, table in docs/stage3_skill_table.md).
## The NUMBERS come from skill_tuning.tres, so the descriptions below always
## match what the game actually does. The EFFECTS are coded in battle.gd
## (actives) and combat_rules.gd (leader skills and passives).
##
## Rules: only the slot-1 leader's skill counts (leader skills never stack).
## Passives marked TEAM count once even if two hunters have them.

const TUNING: SkillTuning = preload("res://data/skills/skill_tuning.tres")

const NAMES := {
	# Active skills
	&"overrun": "Overrun",
	&"bulwark": "Bulwark",
	&"execute": "Shadow Verdict",
	&"mend": "Mend",
	&"night_rend": "Night Rend",
	&"solar_flare": "Solar Flare",
	&"ember_lance": "Ember Lance",
	&"thorn_snipe": "Thorn Snipe",
	&"undertow_strike": "Undertow Strike",
	&"radiant_pierce": "Radiant Pierce",
	&"forge_guard": "Forge Guard",
	&"tidewall": "Tidewall",
	&"gravity_well": "Gravity Well",
	&"sanctuary": "Sanctuary",
	&"spore_bloom": "Spore Bloom",
	&"cauterize": "Cauterize",
	&"night_bloom": "Night Bloom",
	&"dawn_chorus": "Dawn Chorus",
	&"cinder_burst": "Cinder Burst",
	&"coolant_flush": "Coolant Flush",
	&"spore_puff": "Spore Puff",
	&"sunburst_charge": "Sunburst Charge",
	&"twin_shiv": "Twin Shiv",
	&"heat_vent": "Heat Vent",
	&"trident_wall": "Trident Wall",
	&"strangle": "Strangle",
	&"refract": "Refract",
	&"void_bite": "Void Bite",
	&"twin_comet": "Twin Comet",
	&"thunder_hammer": "Thunder Hammer",
	&"overclock": "Overclock",
	&"inferno_cleaver": "Inferno Cleaver",
	# Leader skills
	&"leader_kindling_swarm": "Kindling Swarm",
	&"leader_coolant_loop": "Coolant Loop",
	&"leader_germinate": "Germinate",
	&"leader_solar_array": "Solar Array",
	&"leader_backstab": "Backstab",
	&"leader_heat_shielding": "Heat Shielding",
	&"leader_wave_wall": "Wave Wall",
	&"leader_constrict": "Constrict",
	&"leader_refraction": "Refraction",
	&"leader_void_hunger": "Void Hunger",
	&"leader_berserker": "Furnace Heart",
	&"leader_riptide": "Riptide",
	&"leader_overgrowth": "Overgrowth",
	&"leader_bloodmoon": "Bloodmoon",
	&"leader_zenith": "Zenith",
	&"leader_spectre": "Nightfall",
	&"leader_kindled_focus": "Kindled Focus",
	&"leader_hunters_mark": "Hunter's Mark",
	&"leader_cold_precision": "Cold Precision",
	&"leader_halo_sight": "Halo Sight",
	&"leader_titan": "Stone Wall",
	&"leader_molten_ward": "Molten Ward",
	&"leader_deep_current": "Deep Current",
	&"leader_iron_pact": "Iron Pact",
	&"leader_dawn_aegis": "Dawn Aegis",
	&"leader_biotech": "Lifeline",
	&"leader_rootwork": "Rootwork",
	&"leader_second_wind": "Second Wind",
	&"leader_umbral_pact": "Umbral Pact",
	&"leader_radiance": "Radiance",
	&"leader_hammerfall": "Hammerfall",
	&"leader_bedrock": "Bedrock",
	&"leader_neural_link": "Neural Link",
	&"leader_executioner": "Executioner",
	# Passives
	&"cleave": "Cleave",
	&"skill_boost": "Skill Boost",
	&"breaker": "Breaker",
	&"counter": "Counter",
	&"last_stand": "Last Stand",
	&"bind_resist": "Bind Resist",
	&"ambush": "Ambush",
	&"combo_boost": "Combo Boost",
	&"finisher": "Finisher",
	&"time_extend": "Time Extend",
	&"overflow_heal": "Overflow Heal",
	&"field_medic": "Field Medic",
	&"regrowth": "Regrowth",
	&"bloodlust": "Bloodlust",
	&"orb_enhance": "Orb Enhance",
	&"hp_up": "HP Up",
	&"rcv_up": "RCV Up",
	&"retaliation": "Retaliation",
	&"damage_resist": "Damage Resist",
	&"heart_charge": "Heart Charge",
	&"fire_atk_up": "Fire ATK Up",
	&"double_swing": "Double Swing",
	&"storm_battery": "Storm Battery",
	&"thruster_boost": "Thruster Boost",
	&"molten_edge": "Molten Edge",
}

## Passives that work for the whole TEAM and count once (never stack).
const TEAM_PASSIVES := [&"time_extend", &"overflow_heal", &"last_stand", &"damage_resist", &"fire_atk_up", &"thruster_boost"]

## When each passive unlocks, by its position in the character's list.
const UNLOCK_TEXT := ["Lv10", "Evolution 1", "Evolution 2"]


static func display_name(id: StringName) -> String:
	return NAMES.get(id, String(id))


static func is_leader_skill(id: StringName) -> bool:
	return String(id).begins_with("leader_")


## Base cooldown (turns) of an active skill. 0 if unknown.
static func cooldown(id: StringName) -> int:
	var t := TUNING
	match id:
		&"overrun": return t.overrun_cooldown
		&"bulwark": return t.bulwark_cooldown
		&"execute": return t.execute_cooldown
		&"mend": return t.mend_cooldown
		&"night_rend": return t.night_rend_cooldown
		&"solar_flare": return t.solar_flare_cooldown
		&"ember_lance": return t.ember_lance_cooldown
		&"thorn_snipe": return t.thorn_snipe_cooldown
		&"undertow_strike": return t.undertow_cooldown
		&"radiant_pierce": return t.radiant_pierce_cooldown
		&"forge_guard": return t.forge_guard_cooldown
		&"tidewall": return t.tidewall_cooldown
		&"gravity_well": return t.gravity_well_cooldown
		&"sanctuary": return t.sanctuary_cooldown
		&"spore_bloom": return t.spore_bloom_cooldown
		&"cauterize": return t.cauterize_cooldown
		&"night_bloom": return t.night_bloom_cooldown
		&"dawn_chorus": return t.dawn_chorus_cooldown
		&"cinder_burst": return t.cinder_burst_cooldown
		&"coolant_flush": return t.coolant_flush_cooldown
		&"spore_puff": return t.spore_puff_cooldown
		&"sunburst_charge": return t.sunburst_cooldown
		&"twin_shiv": return t.twin_shiv_cooldown
		&"heat_vent": return t.heat_vent_cooldown
		&"trident_wall": return t.trident_wall_cooldown
		&"strangle": return t.strangle_cooldown
		&"refract": return t.refract_cooldown
		&"void_bite": return t.void_bite_cooldown
		&"twin_comet": return t.twin_comet_cooldown
		&"thunder_hammer": return t.thunder_hammer_cooldown
		&"overclock": return t.overclock_cooldown
		&"inferno_cleaver": return t.inferno_cleaver_cooldown
	return 0


## Turns left before a skill is ready at the start of an Act (half charged).
static func act_start_turns(id: StringName) -> int:
	return ceili(cooldown(id) * (1.0 - TUNING.act_start_charge_ratio))


## Plain-English text. `element` = the owner's element (fills in "Fire hunters"
## etc.); -1 = generic wording.
static func describe(id: StringName, element := -1) -> String:
	var t := TUNING
	var el := "its element's" if element < 0 else Element.display_name(element).capitalize()
	var own := "its own element" if element < 0 else Element.display_name(element).capitalize()
	var beats := "the element it beats" if element < 0 else Element.display_name(Element.BEATS.get(element, Element.Type.NONE)).capitalize()
	match id:
		# ---- actives
		&"overrun":
			return "Every %s orb turns into %s." % [beats, own]
		&"bulwark":
			return "The team takes %d%% less damage from the next %d enemy attacks." % [_pct(1.0 - t.bulwark_damage_taken), t.bulwark_attacks]
		&"execute":
			return "Hits the target for ATK x%s. A regular enemy below %d%% HP is defeated instantly; bosses and mini-bosses take ATK x%s instead (never instantly)." % [_num(t.execute_atk_mult), _pct(t.execute_threshold), _num(t.execute_boss_mult)]
		&"mend":
			return "Heals %d%% of max HP and turns %d random orbs into Hearts." % [_pct(t.mend_heal_ratio), t.mend_hearts]
		&"night_rend":
			return "Hits EVERY enemy for ATK x%s (%s damage) and breaks their armour." % [_num(t.night_rend_atk_mult), own]
		&"solar_flare":
			return "The bottom row turns into %s orbs, and %s hunters hit x%s this turn." % [own, el, _num(t.solar_flare_atk_mult)]
		&"ember_lance":
			return "Hits the target for ATK x%s (%s damage), straight through its armour." % [_num(t.ember_lance_atk_mult), own]
		&"thorn_snipe":
			return "Hits the target for ATK x%s; it then takes +%d%% damage from everything for %d turns." % [_num(t.thorn_snipe_atk_mult), _pct(t.thorn_snipe_vulnerable - 1.0), t.thorn_snipe_turns]
		&"undertow_strike":
			return "Hits the target for ATK x%s, or x%s if it is below %d%% HP." % [_num(t.undertow_atk_mult), _num(t.undertow_low_atk_mult), _pct(t.undertow_low_ratio)]
		&"radiant_pierce":
			return "Hits the target for ATK x%s, breaks its armour, and turns %d random orbs into %s." % [_num(t.radiant_pierce_atk_mult), t.radiant_pierce_orbs, own]
		&"forge_guard":
			return "The next %d enemy attacks do %d%% less, and this hunter strikes back at each attacker for ATK x%s." % [t.forge_guard_attacks, _pct(1.0 - t.forge_guard_damage_taken), _num(t.forge_guard_counter_mult)]
		&"tidewall":
			return "Heals %d%% of max HP; the next %d enemy attacks do %d%% less." % [_pct(t.tidewall_heal_ratio), t.tidewall_attacks, _pct(1.0 - t.tidewall_damage_taken)]
		&"gravity_well":
			return "Every enemy's ATK -%d%% for their next %d attacks." % [_pct(1.0 - t.gravity_well_atk_mult), t.gravity_well_turns]
		&"sanctuary":
			return "Blocks the next enemy attack completely and heals %d%% of max HP." % _pct(t.sanctuary_heal_ratio)
		&"spore_bloom":
			return "Every Dark orb turns into a Heart."
		&"cauterize":
			return "Heals %d%% of max HP, and %s hunters hit x%s this turn." % [_pct(t.cauterize_heal_ratio), el, _num(t.cauterize_atk_mult)]
		&"night_bloom":
			return "Heals %d%% of max HP at the start of each of your next %d turns." % [_pct(t.night_bloom_heal_ratio), t.night_bloom_turns]
		&"dawn_chorus":
			return "Turns %d random orbs into Hearts and gives +%s s to move orbs this turn." % [t.dawn_chorus_hearts, _num(t.dawn_chorus_seconds)]
		&"cinder_burst":
			return "Hits EVERY enemy for ATK x%s (%s damage)." % [_num(t.cinder_burst_atk_mult), own]
		&"coolant_flush":
			return "Every %s orb turns into a Heart, and heals %d%% of max HP." % [beats, _pct(t.coolant_flush_heal_ratio)]
		&"spore_puff":
			return "Heals %d%% of max HP; every enemy's next attack is %d%% weaker." % [_pct(t.spore_puff_heal_ratio), _pct(1.0 - t.spore_puff_atk_mult)]
		&"sunburst_charge":
			return "The TOP row turns into %s orbs, and %d random orbs into Hearts." % [own, t.sunburst_hearts]
		&"twin_shiv":
			return "Hits the target TWICE for ATK x%s each (%s damage)." % [_num(t.twin_shiv_atk_mult), own]
		&"heat_vent":
			return "The next %d enemy attacks do %d%% less, and %s hunters hit x%s this turn." % [t.heat_vent_attacks, _pct(1.0 - t.heat_vent_damage_taken), el, _num(t.heat_vent_atk_mult)]
		&"trident_wall":
			return "The next %d enemy attacks do %d%% less, and heals %d%% of max HP." % [t.trident_wall_attacks, _pct(1.0 - t.trident_wall_damage_taken), _pct(t.trident_wall_heal_ratio)]
		&"strangle":
			return "Hits the target for ATK x%s (%s damage); its next attack is %d%% weaker." % [_num(t.strangle_atk_mult), own, _pct(1.0 - t.strangle_weaken_mult)]
		&"refract":
			return "Every %s orb turns into %s, and heals %d%% of max HP." % [beats, own, _pct(t.refract_heal_ratio)]
		&"void_bite":
			return "Hits the target for ATK x%s (%s damage) and heals the team for %d%% of the damage dealt." % [_num(t.void_bite_atk_mult), own, _pct(t.void_bite_lifesteal)]
		&"twin_comet":
			return "Hits EVERY enemy %d times for ATK x%s each (%s damage), and turns %d random orbs into %s." % [t.twin_comet_hits, _num(t.twin_comet_atk_mult), own, t.twin_comet_orbs, own]
		&"thunder_hammer":
			return "Hits the target for ATK x%s (%s damage) and stuns it: it skips its next attack. Bosses and mini-bosses can't be stunned; their next attack is %d%% weaker instead." % [_num(t.thunder_hammer_atk_mult), own, _pct(1.0 - t.thunder_hammer_boss_weaken)]
		&"overclock":
			return "Every OTHER hunter's skill charges %d turns, and heals %d%% of max HP." % [t.overclock_turns, _pct(t.overclock_heal_ratio)]
		&"inferno_cleaver":
			return "Hits the target for ATK x%s (%s damage), then it BURNS for ATK x%s at the start of each of your next %d turns." % [_num(t.inferno_cleaver_atk_mult), own, _num(t.inferno_burn_mult), t.inferno_burn_turns]
		# ---- leader skills (slot 1 only, never stack)
		&"leader_kindling_swarm":
			return "Match %d+ separate %s groups: %s hunters ATK x%s." % [t.leader_kindling_groups, own, el, _num(t.leader_kindling_mult)]
		&"leader_coolant_loop":
			return "Team RCV x%s. Match Hearts: %s hunters ATK x%s." % [_num(t.leader_coolant_rcv_mult), el, _num(t.leader_coolant_mult)]
		&"leader_germinate":
			return "+%s s to move orbs, and %s hunters ATK x%s." % [_num(t.leader_germinate_seconds), el, _num(t.leader_germinate_mult)]
		&"leader_solar_array":
			return "%s hunters ATK x%s; x%s at %d+ combos." % [el, _num(t.leader_solar_mult), _num(t.leader_solar_high_mult), t.leader_solar_combos]
		&"leader_backstab":
			return "Attacks on enemies above %d%% HP hit x%s." % [_pct(t.leader_backstab_hp_ratio), _num(t.leader_backstab_mult)]
		&"leader_heat_shielding":
			return "Team HP x%s, %s hunters ATK x%s, and the team takes %d%% less from %s enemies." % [_num(t.leader_heat_hp_mult), el, _num(t.leader_heat_mult), _pct(1.0 - t.leader_heat_damage_taken), own]
		&"leader_wave_wall":
			return "Team HP x%s, team RCV x%s, and %s hunters ATK x%s." % [_num(t.leader_wave_hp_mult), _num(t.leader_wave_rcv_mult), el, _num(t.leader_wave_mult)]
		&"leader_constrict":
			return "%d+ combos: every hunter ATK x%s." % [t.leader_constrict_combos, _num(t.leader_constrict_mult)]
		&"leader_refraction":
			return "%s hunters ATK x%s; x%s and heal %d%% of max HP when %d+ elements are matched." % [el, _num(t.leader_refraction_mult), _num(t.leader_refraction_high_mult), _pct(t.leader_refraction_heal_ratio), t.leader_refraction_elements]
		&"leader_void_hunger":
			return "%s hunters hit x%s against enemies below %d%% HP." % [el, _num(t.leader_void_mult), _pct(t.leader_void_hp_ratio)]
		&"leader_berserker":
			return "%d+ %s orbs in one group: %s hunters ATK x%s this turn." % [t.leader_berserker_group, own, el, _num(t.leader_berserker_mult)]
		&"leader_riptide":
			return "%d+ %s orbs in one group: %s hunters ATK x%s, and the next enemy hit does %d%% less." % [t.leader_berserker_group, own, el, _num(t.leader_riptide_mult), _pct(1.0 - t.leader_riptide_damage_taken)]
		&"leader_overgrowth":
			return "%d+ %s orbs in one group: %s hunters ATK x%s, and heal %d%% of max HP." % [t.leader_berserker_group, own, el, _num(t.leader_overgrowth_mult), _pct(t.leader_overgrowth_heal_ratio)]
		&"leader_bloodmoon":
			return "%s hunters ATK x%s; x%s instead while team HP is below %d%%." % [el, _num(t.leader_bloodmoon_mult), _num(t.leader_bloodmoon_low_mult), _pct(t.leader_bloodmoon_hp_ratio)]
		&"leader_zenith":
			return "Match %d+ %s orbs in one turn (any groups): every hunter ATK x%s." % [t.leader_zenith_orbs, own, _num(t.leader_zenith_mult)]
		&"leader_spectre":
			return "Team ATK x%s at %d combos, rising to x%s at %d+ combos." % [_num(t.leader_spectre_low_mult), t.leader_spectre_low_combos, _num(t.leader_spectre_high_mult), t.leader_spectre_high_combos]
		&"leader_kindled_focus":
			return "%d+ combos: %s hunters ATK x%s." % [t.leader_kindled_combos, el, _num(t.leader_kindled_mult)]
		&"leader_hunters_mark":
			return "Attacks on the enemy you TAPPED hit x%s (no target tapped = no bonus)." % _num(t.leader_mark_mult)
		&"leader_cold_precision":
			return "Attacks on regular enemies below %d%% HP hit x%s (not bosses or mini-bosses)." % [_pct(t.leader_cold_hp_ratio), _num(t.leader_cold_mult)]
		&"leader_halo_sight":
			return "%d+ combos: every hunter ATK x%s, %s hunters x%s instead." % [t.leader_halo_combos, _num(t.leader_halo_mult), el, _num(t.leader_halo_element_mult)]
		&"leader_titan":
			return "Team HP x%s. Match Hearts: the next enemy hit does %d%% less damage." % [_num(t.leader_titan_hp_mult), _pct(1.0 - t.leader_titan_damage_taken)]
		&"leader_molten_ward":
			return "Team HP x%s, and %s hunters ATK x%s." % [_num(t.leader_molten_hp_mult), el, _num(t.leader_molten_atk_mult)]
		&"leader_deep_current":
			return "Team HP x%s and team RCV x%s." % [_num(t.leader_deep_hp_mult), _num(t.leader_deep_rcv_mult)]
		&"leader_iron_pact":
			return "Team HP x%s; while team HP is below %d%%, the team takes %d%% less damage." % [_num(t.leader_iron_hp_mult), _pct(t.leader_iron_hp_ratio), _pct(1.0 - t.leader_iron_damage_taken)]
		&"leader_dawn_aegis":
			return "Team HP x%s, and the team takes %d%% less from every hit." % [_num(t.leader_aegis_hp_mult), _pct(1.0 - t.leader_aegis_damage_taken)]
		&"leader_biotech":
			return "Match %d+ different elements in one turn (Hearts don't count): team ATK x%s and heal %d%% of max HP." % [t.leader_biotech_affinities, _num(t.leader_biotech_mult), _pct(t.leader_biotech_heal_ratio)]
		&"leader_rootwork":
			return "Match Hearts: Hearts heal x%s and %s hunters ATK x%s." % [_num(t.leader_rootwork_heal_mult), el, _num(t.leader_rootwork_atk_mult)]
		&"leader_second_wind":
			return "Team RCV x%s. Match Hearts: %s hunters ATK x%s." % [_num(t.leader_second_wind_rcv_mult), el, _num(t.leader_second_wind_atk_mult)]
		&"leader_umbral_pact":
			return "Team RCV x%s. Match %d+ different elements: %s hunters ATK x%s." % [_num(t.leader_umbral_rcv_mult), t.leader_umbral_elements, el, _num(t.leader_umbral_mult)]
		&"leader_radiance":
			return "+%s s to move orbs. Match Hearts: every hunter ATK x%s." % [_num(t.leader_radiance_seconds), _num(t.leader_radiance_mult)]
		&"leader_hammerfall":
			return "%s hunters ATK x%s; x%s when %d+ separate %s groups are matched." % [el, _num(t.leader_hammerfall_mult), _num(t.leader_hammerfall_high_mult), t.leader_hammerfall_groups, own]
		&"leader_bedrock":
			return "Team HP x%s, the team takes %d%% less from every hit, and %s hunters ATK x%s." % [_num(t.leader_bedrock_hp_mult), _pct(1.0 - t.leader_bedrock_damage_taken), el, _num(t.leader_bedrock_mult)]
		&"leader_neural_link":
			return "Match %d+ different elements (Hearts don't count): team ATK x%s, and every skill charges %d extra turn." % [t.leader_neural_elements, _num(t.leader_neural_mult), t.leader_neural_turns]
		&"leader_executioner":
			return "%s hunters hit x%s against enemies below %d%% HP. Every enemy defeated charges every skill %d turn." % [el, _num(t.leader_executioner_mult), _pct(t.leader_executioner_hp_ratio), t.leader_executioner_kill_turns]
		# ---- passives
		&"cleave":
			return "%d+ orbs of its element in one group: its ATK x%s." % [t.cleave_group, _num(t.cleave_mult)]
		&"skill_boost":
			return "Its skill starts each Act %d extra turn charged." % t.skill_boost_turns
		&"breaker":
			return "A 3x3 square of its element: ATK x%s and it ignores enemy armour." % _num(t.breaker_mult)
		&"counter":
			return "When the team is hit, strikes back at that enemy for ATK x%s." % _num(t.counter_atk_mult)
		&"last_stand":
			return "TEAM: once per fight, a hit that would defeat the team leaves it at 1 HP instead."
		&"bind_resist":
			return "%d%% chance to ignore a bind. (No enemy binds yet.)" % _pct(t.bind_resist_chance)
		&"ambush":
			return "Its first attack in each fight does ATK x%s (striking from hiding)." % _num(t.ambush_mult)
		&"combo_boost":
			return "ATK x%s at %d+ combos." % [_num(t.combo_boost_mult), t.combo_boost_combos]
		&"finisher":
			return "x%s damage against enemies below %d%% HP." % [_num(t.finisher_mult), _pct(t.finisher_hp_ratio)]
		&"time_extend":
			return "TEAM: +%s s to move orbs (doesn't stack)." % _num(t.time_extend_seconds)
		&"overflow_heal":
			return "TEAM: %d+ Hearts in one group heal x%s (never above max HP; doesn't stack)." % [t.overflow_group, _num(t.overflow_mult)]
		&"field_medic":
			return "Using its skill also charges every ally's skill by %d turn." % t.field_medic_turns
		&"regrowth":
			return "Every turn it attacks, heal %d%% of max HP." % _pct(t.regrowth_heal_ratio)
		&"bloodlust":
			return "Its ATK x%s while team HP is below %d%%." % [_num(t.bloodlust_mult), _pct(t.bloodlust_hp_ratio)]
		&"orb_enhance":
			return "Groups of %d+ of its orbs hit x%s." % [t.orb_enhance_group, _num(t.orb_enhance_mult)]
		&"hp_up":
			return "Its HP +%d%% in battle." % _pct(t.hp_up_ratio)
		&"rcv_up":
			return "Its RCV +%d%% in battle." % _pct(t.rcv_up_ratio)
		&"retaliation":
			return "Its Counter hits x%s while team HP is below %d%%." % [_num(t.retaliation_mult), _pct(t.retaliation_hp_ratio)]
		&"damage_resist":
			return "TEAM: the team takes %d%% less damage (doesn't stack)." % _pct(1.0 - t.damage_resist_taken)
		&"heart_charge":
			return "Match %d+ Hearts in one turn: its skill charges %d extra turn." % [t.heart_charge_hearts, t.heart_charge_turns]
		&"fire_atk_up":
			return "TEAM: Fire hunters ATK +%d%% (doesn't stack)." % _pct(t.fire_atk_up_mult - 1.0)
		&"double_swing":
			return "%d+ separate groups of its element in one turn: its ATK x%s." % [t.double_swing_groups, _num(t.double_swing_mult)]
		&"storm_battery":
			return "When the team is hit, its skill charges %d extra turn (once per enemy turn)." % t.storm_battery_turns
		&"thruster_boost":
			return "TEAM: +%s s to move orbs (adds to Time Extend; doesn't stack with itself)." % _num(t.thruster_boost_seconds)
		&"molten_edge":
			return "Its attacks ignore enemy armour (full damage, armour stays up)."
	return ""


static func _pct(ratio: float) -> int:
	return roundi(ratio * 100.0)


static func _num(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else str(snappedf(v, 0.01))
