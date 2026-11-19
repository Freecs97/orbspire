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

@export_group("Passives")
@export var cleave_group := 4
@export var cleave_mult := 1.5
@export var skill_boost_turns := 1
@export var breaker_mult := 2.5
@export var counter_atk_mult := 1.0
@export var last_stand_hp_ratio := 0.3
@export var last_stand_damage_taken := 0.7
@export var bind_resist_chance := 0.5
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
