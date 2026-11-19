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


## DEF: an orb attack loses the enemy's DEF in damage, but always does at least 1.
static func after_def(damage: int, enemy: Enemy) -> int:
	if enemy.data.def <= 0 or damage <= 0:
		return damage
	return maxi(damage - enemy.data.def, 1)


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


# ---------------------------------------------------------------- leader skills (slot 1 only)

## ATK multiplier the LEADER's skill gives this member this turn.
static func leader_multiplier(leader: FighterData, member: FighterData, groups: Array, combos: int) -> float:
	if leader == null:
		return 1.0
	var t := Skills.TUNING
	match leader.leader_skill:
		&"leader_berserker":
			# 4+ orbs of the leader's element in one group: that element's hunters x2.
			if member.element == leader.element and has_group(groups, leader.element, t.leader_berserker_group):
				return t.leader_berserker_mult
		&"leader_spectre":
			# x1.5 at 5 combos, x2.5 at 7+. 6 combos sits in between (x2.0).
			if combos >= t.leader_spectre_high_combos:
				return t.leader_spectre_high_mult
			if combos >= t.leader_spectre_low_combos:
				var steps := t.leader_spectre_high_combos - t.leader_spectre_low_combos
				var k := float(combos - t.leader_spectre_low_combos) / steps
				return lerpf(t.leader_spectre_low_mult, t.leader_spectre_high_mult, k)
		&"leader_biotech":
			if distinct_attack_types(groups) >= t.leader_biotech_affinities:
				return t.leader_biotech_mult
	return 1.0


## Titan leader: team max HP x1.3 (applied when the team is built).
static func team_hp_multiplier(leader: FighterData) -> float:
	if leader and leader.leader_skill == &"leader_titan":
		return Skills.TUNING.leader_titan_hp_mult
	return 1.0


# ---------------------------------------------------------------- passives

## ATK multiplier from this member's OWN unlocked passives, against `enemy`.
static func passive_multiplier(member: FighterData, groups: Array, combos: int, enemy: Enemy, first_attack: bool) -> float:
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
	return m


## Breaker: a 3x3 square of its element ignores enemy armour.
static func ignores_armor(member: FighterData, groups: Array) -> bool:
	return member.has_passive(&"breaker") and has_square(groups, member.element)


## Any team member with this unlocked passive?
static func team_has(team: Team, id: StringName) -> bool:
	for m in team.members:
		if m.has_passive(id):
			return true
	return false


## Seconds to move orbs: 5, +1 with Time Extend on the team.
static func move_time(team: Team) -> float:
	var s := Board.MOVE_TIME
	if team_has(team, &"time_extend"):
		s += Skills.TUNING.time_extend_seconds
	return s


## Total healing this turn: Hearts (x1.5 with Overflow Heal on a 5+ Heart group)
## plus the Biotech leader's 10% when 3+ elements were matched.
static func turn_heal(team: Team, hearts: int, groups: Array) -> int:
	var t := Skills.TUNING
	var amount := team.total_rcv * (hearts / 3.0)   # same as DamageCalculator.healing, before rounding
	if hearts > 0 and team_has(team, &"overflow_heal") and has_group(groups, Element.Type.HEART, t.overflow_group):
		amount *= t.overflow_mult
	var leader := team.leader()
	if leader and leader.leader_skill == &"leader_biotech" and distinct_attack_types(groups) >= t.leader_biotech_affinities:
		amount += team.max_hp * t.leader_biotech_heal_ratio
	return roundi(amount)


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
