class_name CombatRules
extends RefCounted
## Turn rules that sit on top of the base damage formula.
##
## Plain English: DamageCalculator does the core maths
## (ATK x orbs/3 x combo x element). This file answers the other questions:
##   - Who does each hunter hit? (one target, or every enemy)
##   - Which enemy is "the target" right now?
## Leader skills and passives add their multipliers here too (see below).
##
## A "group" is one matched cluster from the board:
##   { "type": orb type, "cells": [Vector2i, ...] }

## A Berserker hits EVERY enemy when this many of its orbs match in one group.
const AOE_MIN_ORBS := 4


## Size of the biggest matched group of one orb type this turn (0 if none).
static func largest_group(groups: Array, type: int) -> int:
	var best := 0
	for g in groups:
		if g["type"] == type:
			best = maxi(best, (g["cells"] as Array).size())
	return best


## True if any group of this type had at least `size` orbs.
static func has_group(groups: Array, type: int, size: int) -> bool:
	return largest_group(groups, type) >= size


## Berserkers hit all enemies on a 4+ group of their own element; everyone else
## (and a Berserker with only 3-orb groups) hits one enemy. Spectres always hit one.
static func hits_all(member: FighterData, groups: Array) -> bool:
	return member.role == FighterData.Role.BERSERKER and has_group(groups, member.element, AOE_MIN_ORBS)


## Which enemy a single-target attack goes to: the tapped enemy if it is still
## alive, otherwise the front one (first alive, left to right). -1 if none left.
static func pick_target(enemies: Array, tapped: int) -> int:
	if tapped >= 0 and tapped < enemies.size() and not (enemies[tapped] as Enemy).is_defeated():
		return tapped
	for i in enemies.size():
		if not (enemies[i] as Enemy).is_defeated():
			return i
	return -1


## Every enemy this hunter's attack lands on this turn (indexes into `enemies`).
static func targets_for(member: FighterData, groups: Array, enemies: Array, tapped: int) -> Array[int]:
	var out: Array[int] = []
	if hits_all(member, groups):
		for i in enemies.size():
			if not (enemies[i] as Enemy).is_defeated():
				out.append(i)
	else:
		var t := pick_target(enemies, tapped)
		if t >= 0:
			out.append(t)
	return out


## True if this hunter's attack this turn came from a 4+ group (breaks armour).
static func breaks_armor(member: FighterData, groups: Array) -> bool:
	return has_group(groups, member.element, AOE_MIN_ORBS)


# ---------------------------------------------------------------- levels and DEF

const PROGRESSION: ProgressionTuning = preload("res://data/progression.tres")


## A copy of a hunter's data card with HP / ATK / RCV grown to `level`.
## (Phase 6 will store real levels; until then fights preview the expected level.)
static func at_level(d: FighterData, level: int) -> FighterData:
	if level <= 1:
		return d
	var c: FighterData = d.duplicate()
	var m := PROGRESSION.stat_mult(level)
	c.max_hp = roundi(d.max_hp * m)
	c.atk = roundi(d.atk * m)
	c.rcv = roundi(d.rcv * m)
	return c


## Preview level for fights with no save behind them (tests, the balance tools):
## like at_level, but above the Stage 1 cap (Lv15) a hunter must have evolved once
## in the real game, so it gets Evolution 1's +10% stats and cooldown -1 too.
## Above Lv30 (the Stage 2 cap) it must have evolved twice: Evolution 2 too.
static func preview_at_level(d: FighterData, level: int) -> FighterData:
	var c := at_level(d, level)
	var evos := 0
	for s in range(1, PROGRESSION.built_stages):
		if level > PROGRESSION.level_cap(s):
			evos = s
	if evos == 0:
		return c
	var m := 1.0 + ECONOMY.evo_stat_bonus * evos
	c.max_hp = roundi(c.max_hp * m)
	c.atk = roundi(c.atk * m)
	c.rcv = roundi(c.rcv * m)
	c.stage = maxi(c.stage, 1 + evos)
	c.cooldown_cut = maxi(c.cooldown_cut, evos)
	return c


const ECONOMY: EconomyTuning = preload("res://data/economy.tres")


## DEF: an orb attack loses the enemy's DEF in damage, but always does at least 1.
## Element Shield (exploration Wardens and bosses only; approved by Bailey
## 2026-11-19): an orb attack of the element it RESISTS does nothing at all (a
## Water boss shrugs off Fire), so a team of one affinity can't clear a galaxy.
static func after_def(damage: int, enemy: Enemy, attacker_element := -1) -> int:
	if attacker_element >= 0 and shields_against(enemy.data, attacker_element):
		return 0
	if enemy.data.def <= 0 or damage <= 0:
		return damage
	return maxi(damage - enemy.data.def, 1)


## Dual affinity: the sub affinity hits for 1/3 of ATK, or 10% if it is the same
## as the main affinity.
const SUB_SHARE := 1.0 / 3.0
const SUB_SAME_SHARE := 0.1


static func sub_share(m: FighterData) -> float:
	return SUB_SAME_SHARE if m.sub_element == m.element else SUB_SHARE


static func shields_against(d: FighterData, attacker_element: int) -> bool:
	return d.element_shield and Element.multiplier(attacker_element, d.element) < 1.0


# ---------------------------------------------------------------- board patterns

## True if a group of this type is EXACTLY a 3x3 square (9 orbs).
static func has_square(groups: Array, type: int) -> bool:
	for g in groups:
		var cells: Array = g["cells"]
		if g["type"] != type or cells.size() != 9:
			continue
		var lo := Vector2i(99, 99)
		var hi := Vector2i(-1, -1)
		for c in cells:
			lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
			hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
		if hi - lo == Vector2i(2, 2):
			return true
	return false


## How many different attack elements were matched this turn (Hearts don't count).
static func distinct_attack_types(groups: Array) -> int:
	var seen := {}
	for g in groups:
		if g["type"] in Element.ATTACK_TYPES:
			seen[g["type"]] = true
	return seen.size()


## Total orbs of one type matched this turn, over every group.
static func orbs_matched(groups: Array, type: int) -> int:
	var n := 0
	for g in groups:
		if g["type"] == type:
			n += (g["cells"] as Array).size()
	return n


static func hearts_matched(groups: Array) -> bool:
	return orbs_matched(groups, Element.Type.HEART) > 0


# ---------------------------------------------------------------- leader skills (slot 1 only)

## ATK multiplier the LEADER's skill gives this member this turn.
## Only slot 1 leads, so leader skills never stack.
##   enemy  - the enemy being hit (Cold Precision checks its HP)
##   team   - the live team (Bloodmoon checks team HP); null in paper sims = full HP
##   marked - this hit is on the enemy the player TAPPED (Hunter's Mark)
static func leader_multiplier(leader: FighterData, member: FighterData, groups: Array, combos: int, enemy: Enemy = null, team: Team = null, marked := false) -> float:
	if leader == null:
		return 1.0
	var t := Skills.TUNING
	var el := leader.element
	var same := member.element == el
	var four := has_group(groups, el, t.leader_berserker_group)
	match leader.leader_skill:
		&"leader_berserker":
			# 4+ orbs of the leader's element in one group: that element's hunters x2.
			if same and four:
				return t.leader_berserker_mult
		&"leader_riptide":
			if same and four:
				return t.leader_riptide_mult
		&"leader_overgrowth":
			if same and four:
				return t.leader_overgrowth_mult
		&"leader_bloodmoon":
			if same:
				var low := team != null and team.hp_ratio() < t.leader_bloodmoon_hp_ratio
				return t.leader_bloodmoon_low_mult if low else t.leader_bloodmoon_mult
		&"leader_zenith":
			if orbs_matched(groups, el) >= t.leader_zenith_orbs:
				return t.leader_zenith_mult
		&"leader_spectre":
			# x1.5 at 5 combos, x2.5 at 7+. 6 combos sits in between (x2.0).
			if combos >= t.leader_spectre_high_combos:
				return t.leader_spectre_high_mult
			if combos >= t.leader_spectre_low_combos:
				var steps := t.leader_spectre_high_combos - t.leader_spectre_low_combos
				var k := float(combos - t.leader_spectre_low_combos) / steps
				return lerpf(t.leader_spectre_low_mult, t.leader_spectre_high_mult, k)
		&"leader_kindled_focus":
			if same and combos >= t.leader_kindled_combos:
				return t.leader_kindled_mult
		&"leader_hunters_mark":
			if marked:
				return t.leader_mark_mult
		&"leader_cold_precision":
			# Regular enemies only: on bosses / mini-bosses it would just beat Resolve a turn early.
			if enemy != null and not enemy.data.is_boss and enemy.hp_ratio() < t.leader_cold_hp_ratio:
				return t.leader_cold_mult
		&"leader_halo_sight":
			if combos >= t.leader_halo_combos:
				return t.leader_halo_element_mult if same else t.leader_halo_mult
		&"leader_molten_ward":
			if same:
				return t.leader_molten_atk_mult
		&"leader_biotech":
			if distinct_attack_types(groups) >= t.leader_biotech_affinities:
				return t.leader_biotech_mult
		&"leader_rootwork":
			if same and hearts_matched(groups):
				return t.leader_rootwork_atk_mult
		&"leader_second_wind":
			if same and hearts_matched(groups):
				return t.leader_second_wind_atk_mult
		&"leader_umbral_pact":
			if same and distinct_attack_types(groups) >= t.leader_umbral_elements:
				return t.leader_umbral_mult
		&"leader_radiance":
			if hearts_matched(groups):
				return t.leader_radiance_mult
		# ---- enemy leaders (Stage 3 Part B)
		&"leader_kindling_swarm":
			if same and groups.filter(func(g: Dictionary) -> bool: return g["type"] == el).size() >= t.leader_kindling_groups:
				return t.leader_kindling_mult
		&"leader_coolant_loop":
			if same and hearts_matched(groups):
				return t.leader_coolant_mult
		&"leader_germinate":
			if same:
				return t.leader_germinate_mult
		&"leader_solar_array":
			if same:
				return t.leader_solar_high_mult if combos >= t.leader_solar_combos else t.leader_solar_mult
		&"leader_backstab":
			if enemy != null and enemy.hp_ratio() > t.leader_backstab_hp_ratio:
				return t.leader_backstab_mult
		&"leader_heat_shielding":
			if same:
				return t.leader_heat_mult
		&"leader_wave_wall":
			if same:
				return t.leader_wave_mult
		&"leader_constrict":
			if combos >= t.leader_constrict_combos:
				return t.leader_constrict_mult
		&"leader_refraction":
			if same:
				return t.leader_refraction_high_mult if distinct_attack_types(groups) >= t.leader_refraction_elements else t.leader_refraction_mult
		&"leader_void_hunger":
			if same and enemy != null and enemy.hp_ratio() < t.leader_void_hp_ratio:
				return t.leader_void_mult
		# ---- friend leaders (ultra-rare drops)
		&"leader_hammerfall":
			if same:
				return t.leader_hammerfall_high_mult if groups_of(groups, el) >= t.leader_hammerfall_groups else t.leader_hammerfall_mult
		&"leader_bedrock":
			if same:
				return t.leader_bedrock_mult
		&"leader_neural_link":
			if distinct_attack_types(groups) >= t.leader_neural_elements:
				return t.leader_neural_mult
		&"leader_executioner":
			if same and enemy != null and enemy.hp_ratio() < t.leader_executioner_hp_ratio:
				return t.leader_executioner_mult
	return 1.0


## How many separate groups of this type were matched this turn.
static func groups_of(groups: Array, type: int) -> int:
	return groups.filter(func(g: Dictionary) -> bool: return g["type"] == type).size()


## Executioner (Logan leader): skill charge for every enemy defeated (0 = other leaders).
static func leader_kill_charge(leader: FighterData) -> int:
	if leader and leader.leader_skill == &"leader_executioner":
		return Skills.TUNING.leader_executioner_kill_turns
	return 0


## Neural Link (Khoel leader): extra skill charge this turn (0 if it didn't trigger).
static func leader_skill_charge(leader: FighterData, groups: Array) -> int:
	if leader and leader.leader_skill == &"leader_neural_link" and distinct_attack_types(groups) >= Skills.TUNING.leader_neural_elements:
		return Skills.TUNING.leader_neural_turns
	return 0


## Team max HP from the leader (applied when the team is built).
static func team_hp_multiplier(leader: FighterData) -> float:
	if leader == null:
		return 1.0
	var t := Skills.TUNING
	match leader.leader_skill:
		&"leader_titan": return t.leader_titan_hp_mult
		&"leader_molten_ward": return t.leader_molten_hp_mult
		&"leader_deep_current": return t.leader_deep_hp_mult
		&"leader_iron_pact": return t.leader_iron_hp_mult
		&"leader_dawn_aegis": return t.leader_aegis_hp_mult
		&"leader_heat_shielding": return t.leader_heat_hp_mult
		&"leader_wave_wall": return t.leader_wave_hp_mult
		&"leader_bedrock": return t.leader_bedrock_hp_mult
	return 1.0


## Team RCV from the leader (applied when the team is built).
static func team_rcv_multiplier(leader: FighterData) -> float:
	if leader == null:
		return 1.0
	var t := Skills.TUNING
	match leader.leader_skill:
		&"leader_deep_current": return t.leader_deep_rcv_mult
		&"leader_second_wind": return t.leader_second_wind_rcv_mult
		&"leader_umbral_pact": return t.leader_umbral_rcv_mult
		&"leader_coolant_loop": return t.leader_coolant_rcv_mult
		&"leader_wave_wall": return t.leader_wave_rcv_mult
	return 1.0


## How much of an enemy hit the team takes because of the leader (1.0 = all).
## `attacker` = the enemy hitting (Heat Shielding cares about its element).
static func leader_damage_taken(team: Team, attacker: Enemy = null) -> float:
	var leader := team.leader()
	if leader == null:
		return 1.0
	var t := Skills.TUNING
	match leader.leader_skill:
		&"leader_dawn_aegis":
			return t.leader_aegis_damage_taken
		&"leader_iron_pact":
			if team.hp_ratio() < t.leader_iron_hp_ratio:
				return t.leader_iron_damage_taken
		&"leader_heat_shielding":
			if attacker != null and attacker.data.element == leader.element:
				return t.leader_heat_damage_taken
		&"leader_bedrock":
			return t.leader_bedrock_damage_taken
	return 1.0


# ---------------------------------------------------------------- passives

## ATK multiplier from this member's OWN unlocked passives, against `enemy`,
## plus TEAM passives that boost it (Fire ATK Up). `team` null = paper sim.
static func passive_multiplier(member: FighterData, groups: Array, combos: int, enemy: Enemy, first_attack: bool, team: Team = null) -> float:
	var t := Skills.TUNING
	var m := 1.0
	if member.has_passive(&"cleave") and has_group(groups, member.element, t.cleave_group):
		m *= t.cleave_mult
	if member.has_passive(&"breaker") and has_square(groups, member.element):
		m *= t.breaker_mult
	if member.has_passive(&"ambush") and first_attack:
		m *= t.ambush_mult
	if member.has_passive(&"combo_boost") and combos >= t.combo_boost_combos:
		m *= t.combo_boost_mult
	if member.has_passive(&"finisher") and enemy and enemy.hp_ratio() < t.finisher_hp_ratio:
		m *= t.finisher_mult
	if member.has_passive(&"orb_enhance") and has_group(groups, member.element, t.orb_enhance_group):
		m *= t.orb_enhance_mult
	if member.has_passive(&"double_swing") and groups_of(groups, member.element) >= t.double_swing_groups:
		m *= t.double_swing_mult
	if team != null:
		if member.has_passive(&"bloodlust") and team.hp_ratio() < t.bloodlust_hp_ratio:
			m *= t.bloodlust_mult
		if member.element == Element.Type.FIRE and team_has(team, &"fire_atk_up"):
			m *= t.fire_atk_up_mult   # TEAM passive: counts once
	return m


## Breaker: a 3x3 square of its element ignores enemy armour.
## Molten Edge (Logan): every attack ignores enemy armour.
static func ignores_armor(member: FighterData, groups: Array) -> bool:
	return member.has_passive(&"molten_edge") or (member.has_passive(&"breaker") and has_square(groups, member.element))


## Any team member with this unlocked passive?
static func team_has(team: Team, id: StringName) -> bool:
	for m in team.members:
		if m.has_passive(id):
			return true
	return false


## Seconds to move orbs: 5, +1 with Time Extend on the team (counts once),
## +1 with the Radiance leader.
static func move_time(team: Team) -> float:
	var s := Board.MOVE_TIME
	if team_has(team, &"time_extend"):
		s += Skills.TUNING.time_extend_seconds
	if team_has(team, &"thruster_boost"):
		s += Skills.TUNING.thruster_boost_seconds
	var leader := team.leader()
	if leader and leader.leader_skill == &"leader_radiance":
		s += Skills.TUNING.leader_radiance_seconds
	if leader and leader.leader_skill == &"leader_germinate":
		s += Skills.TUNING.leader_germinate_seconds
	return s


## Total healing this turn (never above max HP: Team.heal caps it):
##   Hearts x team RCV x combo multiplier (Stage 4)
##     (x1.5 Overflow Heal on a 5+ Heart group; x1.5 Rootwork leader)
##   + Lifeline leader 10% when 2+ elements were matched
##   + Overgrowth leader 5% on a 4+ group of its element
##   + Regrowth 4% for each hunter with it whose element was matched
static func turn_heal(team: Team, hearts: int, groups: Array) -> int:
	var t := Skills.TUNING
	var amount := team.total_rcv * (hearts / 3.0)   # same as DamageCalculator.healing, before rounding
	# Combo multiplier on the Hearts part (each matched group is one combo).
	if t.combo_boosts_healing and hearts > 0:
		amount *= DamageCalculator.combo_multiplier(groups.size())
	if hearts > 0 and team_has(team, &"overflow_heal") and has_group(groups, Element.Type.HEART, t.overflow_group):
		amount *= t.overflow_mult
	var leader := team.leader()
	if leader:
		match leader.leader_skill:
			&"leader_biotech":
				if distinct_attack_types(groups) >= t.leader_biotech_affinities:
					amount += team.max_hp * t.leader_biotech_heal_ratio
			&"leader_rootwork":
				amount *= t.leader_rootwork_heal_mult
			&"leader_overgrowth":
				if has_group(groups, leader.element, t.leader_berserker_group):
					amount += team.max_hp * t.leader_overgrowth_heal_ratio
			&"leader_refraction":
				if distinct_attack_types(groups) >= t.leader_refraction_elements:
					amount += team.max_hp * t.leader_refraction_heal_ratio
	for m in team.members:
		if m.has_passive(&"regrowth") and orbs_matched(groups, m.element) > 0:
			amount += team.max_hp * t.regrowth_heal_ratio
	return roundi(amount)


## A damage skill's hit: ATK x mult x element (no combo maths, ignores DEF).
static func skill_hit(member: FighterData, enemy: Enemy, mult: float) -> int:
	return roundi(member.atk * mult * Element.multiplier(member.element, enemy.data.element))


# ---------------------------------------------------------------- active skills

## Turns until this hunter's skill is ready at the start of an Act:
## half charged, plus Skill Boost if it has it.
static func act_start_turns(member: FighterData) -> int:
	var turns := ceili(member.skill_cooldown() * (1.0 - Skills.TUNING.act_start_charge_ratio))
	if member.has_passive(&"skill_boost"):
		turns -= Skills.TUNING.skill_boost_turns
	return maxi(turns, 0)


## Execute: ATK x4 to the target. Below 25% HP it is defeated instantly,
## except bosses, which take ATK x6 instead. (No combo / element maths:
## it is a skill hit, not an orb attack.)
static func execute_damage(member: FighterData, enemy: Enemy) -> int:
	var t := Skills.TUNING
	if enemy.hp_ratio() < t.execute_threshold:
		if enemy.data.is_boss:
			return roundi(member.atk * t.execute_boss_mult)
		return enemy.hp
	return roundi(member.atk * t.execute_atk_mult)
