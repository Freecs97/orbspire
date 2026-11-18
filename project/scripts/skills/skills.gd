class_name Skills
extends RefCounted
## The skill catalogue: names, cooldowns and plain-English descriptions.
##
## Plain English: every skill has an id (like &"overrun"). Character .tres
## files list the ids they use. The NUMBERS come from skill_tuning.tres, so
## the descriptions below always match what the game actually does.
## The skill EFFECTS are coded in battle.gd (actives) and combat_rules.gd
## (leader skills and passives).

const TUNING: SkillTuning = preload("res://data/skills/skill_tuning.tres")

const NAMES := {
	# Active skills
	&"overrun": "Overrun",
	&"bulwark": "Bulwark",
	&"execute": "Execute",
	&"mend": "Mend",
	# Leader skills
	&"leader_berserker": "Leader skill",
	&"leader_titan": "Leader skill",
	&"leader_spectre": "Leader skill",
	&"leader_biotech": "Leader skill",
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
}

## When each passive unlocks, by its position in the character's list.
const UNLOCK_TEXT := ["Lv10", "Evolution 1", "Evolution 2"]


static func display_name(id: StringName) -> String:
	return NAMES.get(id, String(id))


## Base cooldown (turns) of an active skill. 0 if unknown.
static func cooldown(id: StringName) -> int:
	match id:
		&"overrun":
			return TUNING.overrun_cooldown
		&"bulwark":
			return TUNING.bulwark_cooldown
		&"execute":
			return TUNING.execute_cooldown
		&"mend":
			return TUNING.mend_cooldown
	return 0


## Turns left before a skill is ready at the start of an Act (half charged).
static func act_start_turns(id: StringName) -> int:
	return ceili(cooldown(id) * (1.0 - TUNING.act_start_charge_ratio))


static func describe(id: StringName) -> String:
	var t := TUNING
	match id:
		&"overrun":
			return "Every orb of the element this hunter beats turns into its own element."
		&"bulwark":
			return "The team takes %d%% less damage from the next %d enemy attacks." % [_pct(1.0 - t.bulwark_damage_taken), t.bulwark_attacks]
		&"execute":
			return "Hits the target for ATK x%s. Below %d%% HP it is defeated instantly (bosses take ATK x%s instead)." % [_num(t.execute_atk_mult), _pct(t.execute_threshold), _num(t.execute_boss_mult)]
		&"mend":
			return "Heals %d%% of max HP and turns %d random orbs into Hearts." % [_pct(t.mend_heal_ratio), t.mend_hearts]
		&"leader_berserker":
			return "Match %d+ orbs of the leader's element in one group: hunters of that element ATK x%s this turn." % [t.leader_berserker_group, _num(t.leader_berserker_mult)]
		&"leader_titan":
			return "Team HP x%s. Match Hearts: the next enemy hit does %d%% less damage." % [_num(t.leader_titan_hp_mult), _pct(1.0 - t.leader_titan_damage_taken)]
		&"leader_spectre":
			return "Team ATK x%s at %d combos, rising to x%s at %d+ combos." % [_num(t.leader_spectre_low_mult), t.leader_spectre_low_combos, _num(t.leader_spectre_high_mult), t.leader_spectre_high_combos]
		&"leader_biotech":
			return "Match %d+ different elements in one turn (Hearts don't count): team ATK x%s and heal %d%% of max HP." % [t.leader_biotech_affinities, _num(t.leader_biotech_mult), _pct(t.leader_biotech_heal_ratio)]
		&"cleave":
			return "%d+ orbs of its element in one group: its ATK x%s." % [t.cleave_group, _num(t.cleave_mult)]
		&"skill_boost":
			return "Its skill starts each Act %d extra turn charged." % t.skill_boost_turns
		&"breaker":
			return "A 3x3 square of its element: ATK x%s and it ignores enemy armour." % _num(t.breaker_mult)
		&"counter":
			return "When the team is hit, strikes back at that enemy for ATK x%s." % _num(t.counter_atk_mult)
		&"last_stand":
			return "While team HP is below %d%%, the team takes %d%% less damage." % [_pct(t.last_stand_hp_ratio), _pct(1.0 - t.last_stand_damage_taken)]
		&"bind_resist":
			return "%d%% chance to ignore a bind. (No enemy binds yet.)" % _pct(t.bind_resist_chance)
		&"ambush":
			return "Its first attack in each fight does ATK x%s (striking from hiding)." % _num(t.ambush_mult)
		&"combo_boost":
			return "ATK x%s at %d+ combos." % [_num(t.combo_boost_mult), t.combo_boost_combos]
		&"finisher":
			return "x%s damage against enemies below %d%% HP." % [_num(t.finisher_mult), _pct(t.finisher_hp_ratio)]
		&"time_extend":
			return "+%s s to move orbs while it is on the team." % _num(t.time_extend_seconds)
		&"overflow_heal":
			return "%d+ Hearts in one group: healing x%s." % [t.overflow_group, _num(t.overflow_mult)]
		&"field_medic":
			return "Using its skill also charges every ally's skill by %d turn." % t.field_medic_turns
	return ""


static func _pct(ratio: float) -> int:
	return roundi(ratio * 100.0)


static func _num(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else str(snappedf(v, 0.01))
