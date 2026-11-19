class_name SkillTuning
extends Resource
## Every skill number in one place, so balance changes never touch code.
##
## Plain English: open res://data/skills/skill_tuning.tres in Godot and change
## any value in the Inspector (cooldowns, multipliers, percentages).

@export_group("Charging")
## The first fight of an Act starts with skills half charged (rounded up).
@export var act_start_charge_ratio := 0.5

@export_group("Active: Overrun (Berserker)")
@export var overrun_cooldown := 7

@export_group("Active: Bulwark (Titan)")
@export var bulwark_cooldown := 8
@export var bulwark_damage_taken := 0.5   ## 0.5 = the team takes 50% less.
@export var bulwark_attacks := 2          ## How many enemy attacks it covers.

@export_group("Active: Execute (Spectre)")
@export var execute_cooldown := 8
@export var execute_atk_mult := 4.0
@export var execute_threshold := 0.25     ## Below 25% HP = instant defeat.
@export var execute_boss_mult := 6.0      ## Bosses take this instead of dying.

@export_group("Active: Mend (Biotech)")
@export var mend_cooldown := 5
@export var mend_heal_ratio := 0.3        ## 30% of max HP.
@export var mend_hearts := 3              ## Orbs turned into Hearts.

@export_group("Active: Night Rend (Corvin)")
@export var night_rend_cooldown := 8
@export var night_rend_atk_mult := 2.0         ## Hits EVERY enemy, breaks armour.

@export_group("Active: Solar Flare (Sol)")
@export var solar_flare_cooldown := 7
@export var solar_flare_atk_mult := 1.5        ## Its element's hunters, this turn.

@export_group("Active: Ember Lance (Joren)")
@export var ember_lance_cooldown := 7
@export var ember_lance_atk_mult := 5.0

@export_group("Active: Thorn Snipe (Wren)")
@export var thorn_snipe_cooldown := 6
@export var thorn_snipe_atk_mult := 3.0
@export var thorn_snipe_vulnerable := 1.25     ## Target takes +25% from everything...
@export var thorn_snipe_turns := 2             ## ...for this many turns.

@export_group("Active: Undertow Strike (Kai)")
@export var undertow_cooldown := 8
@export var undertow_atk_mult := 3.0
@export var undertow_low_atk_mult := 5.0       ## If the target is below...
@export var undertow_low_ratio := 0.5          ## ...50% HP.

@export_group("Active: Radiant Pierce (Lyra)")
@export var radiant_pierce_cooldown := 7
@export var radiant_pierce_atk_mult := 3.0
@export var radiant_pierce_orbs := 3           ## Random orbs turned into its element.

@export_group("Active: Forge Guard (Freya)")
@export var forge_guard_cooldown := 7
@export var forge_guard_damage_taken := 0.65   ## 35% less...
@export var forge_guard_attacks := 3           ## ...for the next 3 enemy attacks.
@export var forge_guard_counter_mult := 1.0    ## She strikes back for ATK x this.

@export_group("Active: Tidewall (Rowan)")
@export var tidewall_cooldown := 7
@export var tidewall_heal_ratio := 0.15
@export var tidewall_damage_taken := 0.6
@export var tidewall_attacks := 2

@export_group("Active: Gravity Well (Dmitri)")
@export var gravity_well_cooldown := 8
@export var gravity_well_atk_mult := 0.7       ## Every enemy's ATK -30%...
@export var gravity_well_turns := 2            ## ...for their next 2 attacks.

@export_group("Active: Sanctuary (Aurelia)")
@export var sanctuary_cooldown := 9
@export var sanctuary_heal_ratio := 0.1
@export var sanctuary_blocks := 1              ## Enemy attacks blocked completely.

@export_group("Active: Spore Bloom (Silas)")
@export var spore_bloom_cooldown := 6

@export_group("Active: Cauterize (Ash)")
@export var cauterize_cooldown := 7
@export var cauterize_heal_ratio := 0.2
@export var cauterize_atk_mult := 1.5

@export_group("Active: Night Bloom (Selene)")
@export var night_bloom_cooldown := 8
@export var night_bloom_heal_ratio := 0.12     ## At the start of each of the next...
@export var night_bloom_turns := 3             ## ...3 turns.

@export_group("Active: Dawn Chorus (Luca)")
@export var dawn_chorus_cooldown := 6
@export var dawn_chorus_hearts := 4
@export var dawn_chorus_seconds := 2.0

@export_group("Enemy actives (Stage 3 Part B)")
@export var cinder_burst_cooldown := 6
@export var cinder_burst_atk_mult := 1.5        ## Hits EVERY enemy.
@export var coolant_flush_cooldown := 6
@export var coolant_flush_heal_ratio := 0.1     ## + every orb of the element it beats -> Heart.
@export var spore_puff_cooldown := 5
@export var spore_puff_heal_ratio := 0.15
@export var spore_puff_atk_mult := 0.8          ## Every enemy's NEXT attack.
@export var sunburst_cooldown := 7
@export var sunburst_hearts := 2                ## + the top row -> its element.
@export var twin_shiv_cooldown := 6
@export var twin_shiv_atk_mult := 2.0           ## Per hit; 2 hits.
@export var heat_vent_cooldown := 7
@export var heat_vent_damage_taken := 0.6
@export var heat_vent_attacks := 2
@export var heat_vent_atk_mult := 1.3           ## Its element's hunters, this turn.
@export var trident_wall_cooldown := 8
@export var trident_wall_damage_taken := 0.7
@export var trident_wall_attacks := 3
@export var trident_wall_heal_ratio := 0.1
@export var strangle_cooldown := 7
@export var strangle_atk_mult := 3.0
@export var strangle_weaken_mult := 0.5         ## The target's next attack.
@export var refract_cooldown := 7
@export var refract_heal_ratio := 0.1           ## + every orb of the element it beats -> its element.
@export var void_bite_cooldown := 6
@export var void_bite_atk_mult := 2.5
@export var void_bite_lifesteal := 0.5          ## Heals the team for this share of damage dealt.

@export_group("Leader skills")
@export var leader_berserker_group := 4
@export var leader_berserker_mult := 2.0
@export var leader_titan_damage_taken := 0.75   ## 25% less on the next enemy hit.
@export var leader_titan_hp_mult := 1.3
@export var leader_spectre_low_combos := 5
@export var leader_spectre_low_mult := 1.5
@export var leader_spectre_high_combos := 7
@export var leader_spectre_high_mult := 2.5
@export var leader_biotech_affinities := 3
@export var leader_biotech_mult := 1.5
@export var leader_biotech_heal_ratio := 0.1
@export var leader_riptide_mult := 1.75
@export var leader_riptide_damage_taken := 0.85   ## Next enemy hit 15% weaker.
@export var leader_overgrowth_mult := 1.75
@export var leader_overgrowth_heal_ratio := 0.05
@export var leader_bloodmoon_mult := 1.15
@export var leader_bloodmoon_low_mult := 2.0
@export var leader_bloodmoon_hp_ratio := 0.5
@export var leader_zenith_orbs := 7
@export var leader_zenith_mult := 1.75
@export var leader_kindled_combos := 5
@export var leader_kindled_mult := 2.25
@export var leader_mark_mult := 1.75
@export var leader_cold_hp_ratio := 0.5
@export var leader_cold_mult := 2.0
@export var leader_halo_combos := 4
@export var leader_halo_mult := 1.25
@export var leader_halo_element_mult := 1.75
@export var leader_molten_hp_mult := 1.2
@export var leader_molten_atk_mult := 1.3
@export var leader_deep_hp_mult := 1.2
@export var leader_deep_rcv_mult := 1.5
@export var leader_iron_hp_mult := 1.25
@export var leader_iron_hp_ratio := 0.5
@export var leader_iron_damage_taken := 0.7
@export var leader_aegis_hp_mult := 1.15
@export var leader_aegis_damage_taken := 0.85
@export var leader_rootwork_heal_mult := 1.5
@export var leader_rootwork_atk_mult := 1.5
@export var leader_second_wind_rcv_mult := 1.3
@export var leader_second_wind_atk_mult := 1.5
@export var leader_umbral_rcv_mult := 1.3
@export var leader_umbral_elements := 3
@export var leader_umbral_mult := 2.0
@export var leader_radiance_seconds := 1.0
@export var leader_radiance_mult := 1.3
# Enemy leaders (Stage 3 Part B), tuned in the balance sim so they are never
# faster than a human leader with the same team.
@export var leader_kindling_groups := 2
@export var leader_kindling_mult := 1.15
@export var leader_coolant_rcv_mult := 1.25
@export var leader_coolant_mult := 1.15
@export var leader_germinate_seconds := 1.0
@export var leader_germinate_mult := 1.2
@export var leader_solar_mult := 1.15
@export var leader_solar_combos := 4
@export var leader_solar_high_mult := 1.6
@export var leader_backstab_hp_ratio := 0.8
@export var leader_backstab_mult := 1.25
@export var leader_heat_hp_mult := 1.2
@export var leader_heat_mult := 1.15
@export var leader_heat_damage_taken := 0.8      ## From enemies of the leader's element.
@export var leader_wave_hp_mult := 1.15
@export var leader_wave_rcv_mult := 1.15
@export var leader_wave_mult := 1.15
@export var leader_constrict_combos := 5
@export var leader_constrict_mult := 1.75
@export var leader_refraction_mult := 1.2
@export var leader_refraction_elements := 2
@export var leader_refraction_high_mult := 1.4
@export var leader_refraction_heal_ratio := 0.08
@export var leader_void_hp_ratio := 0.5
@export var leader_void_mult := 1.4

@export_group("Passives")
@export var cleave_group := 4
@export var cleave_mult := 1.5
@export var skill_boost_turns := 1
@export var breaker_mult := 2.5
@export var counter_atk_mult := 1.0
## Last Stand: once per fight, a hit that would defeat the team leaves it at 1 HP.
@export var bind_resist_chance := 0.5
@export var regrowth_heal_ratio := 0.04
@export var bloodlust_hp_ratio := 0.5
@export var bloodlust_mult := 1.3
@export var orb_enhance_group := 5
@export var orb_enhance_mult := 1.3
@export var hp_up_ratio := 0.15
@export var rcv_up_ratio := 0.25
@export var retaliation_hp_ratio := 0.5
@export var retaliation_mult := 2.0
@export var damage_resist_taken := 0.9
@export var heart_charge_hearts := 5
@export var heart_charge_turns := 1
@export var fire_atk_up_mult := 1.1
@export var ambush_mult := 2.0
@export var combo_boost_combos := 7
@export var combo_boost_mult := 2.0
@export var finisher_hp_ratio := 0.5
@export var finisher_mult := 1.5
@export var time_extend_seconds := 1.0
@export var overflow_group := 5
@export var overflow_mult := 1.5
@export var field_medic_turns := 1

@export_group("Bosses")
## Resolve: a boss or mini-boss can lose at most this share of its max HP in
## ONE turn (skills + orbs together), so no team can one-shot it. 1.0 = off.
@export var boss_turn_cap := 0.5
