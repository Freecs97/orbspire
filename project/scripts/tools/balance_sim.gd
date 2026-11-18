class_name BalanceSim
extends RefCounted
## Plays fights on paper, through the REAL damage code, to measure balance.
## Used by the automated test (section B) and by the Act generator.
##
## Plain English: no board, no animation. Each "turn" is a fixed template of
## matched groups, fed to the same CombatRules / DamageCalculator / Enemy code
## the game uses:
##   GOOD    = 3 combos: the 2 best team colours (3 orbs each) + 3 Hearts.
##             If an armoured enemy still has its armour, the best colour is a 4-group.
##   AVERAGE = 2 combos: the best team colour (3 orbs) + 3 Hearts.
##   GREAT   = 6 combos in ONE turn: 5 Fire, 3 Water, 3 Wood, 3 Light, 3 Dark, 3 Hearts.
##   IDLE    = match nothing: how many enemy turns until the team falls.


static func leveled_team(members: Array, level: int) -> Array[FighterData]:
	var out: Array[FighterData] = []
	for d in members:
		out.append(CombatRules.at_level(d, level))
	return out


static func fresh_enemies(enemy_data: Array) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for d in enemy_data:
		out.append(Enemy.new(d))
	return out


## The team ranked by how hard each hunter hits this element.
static func ranked(team: Array[FighterData], defender: int) -> Array:
	var r := team.duplicate()
	r.sort_custom(func(a: FighterData, b: FighterData) -> bool:
		return a.atk * Element.multiplier(a.element, defender) > b.atk * Element.multiplier(b.element, defender))
	return r


static func group(type: int, n: int) -> Dictionary:
	var cells := []
	for k in n:
		cells.append(Vector2i(k, 0))
	return {"type": type, "cells": cells}


## One turn of attacks. Returns damage dealt.
static func attack(team: Array[FighterData], groups: Array, combos: int, enemies: Array[Enemy]) -> int:
	var total := 0
	for m in team:
		var orbs := 0
		for g in groups:
			if g["type"] == m.element:
				orbs += (g["cells"] as Array).size()
		if orbs == 0:
			continue
		for t in CombatRules.targets_for(m, groups, enemies, -1):
			var e := enemies[t]
			var bonus := CombatRules.leader_multiplier(team[0], m, groups, combos) * CombatRules.passive_multiplier(m, groups, combos, e, false)
			var dmg := CombatRules.after_def(DamageCalculator.attack_damage(m.atk, orbs, combos, m.element, e.data.element, bonus), e)
			total += e.take_hit(dmg, CombatRules.breaks_armor(m, groups), CombatRules.ignores_armor(m, groups))
	return total


## Turns to win with GOOD or AVERAGE play (50 = never).
static func turns_to_win(enemy_data: Array, team: Array[FighterData], mode: String) -> int:
	var enemies := fresh_enemies(enemy_data)
	for turn in range(1, 51):
		var front := CombatRules.pick_target(enemies, -1)
		if front < 0:
			return turn - 1
		var r := ranked(team, enemies[front].data.element)
		var best_size := 4 if enemies[front].armor_up else 3
		var groups := [group(r[0].element, best_size), group(Element.Type.HEART, 3)]
		if mode == "GOOD":
			groups.append(group(r[1].element, 3))
		attack(team, groups, groups.size(), enemies)
		if CombatRules.pick_target(enemies, -1) < 0:
			return turn
	return 50


static func team_hp(team: Array[FighterData]) -> int:
	var hp := 0
	for m in team:
		hp += m.max_hp
	return hp


static func idle_turns(enemy_data: Array, team: Array[FighterData]) -> int:
	var hit := 0
	for d in enemy_data:
		hit += d.atk
	return ceili(float(team_hp(team)) / maxi(hit, 1))


## Average play heals 3 Hearts each turn while enemies hit: alive when it wins?
static func avg_survives(enemy_data: Array, team: Array[FighterData]) -> bool:
	var t := Team.new(team)
	var enemies := fresh_enemies(enemy_data)
	for turn in range(1, 51):
		t.heal(CombatRules.turn_heal(t, 3, []))
		var front := CombatRules.pick_target(enemies, -1)
		var r := ranked(team, enemies[front].data.element)
		attack(team, [group(r[0].element, 4 if enemies[front].armor_up else 3), group(Element.Type.HEART, 3)], 2, enemies)
		if CombatRules.pick_target(enemies, -1) < 0:
			return true
		for e in enemies:
			if not e.is_defeated():
				t.take_damage(e.data.atk)
		if t.is_defeated():
			return false
	return false


## Damage of one perfect 6-combo turn on fresh enemies, and HP left after it.
static func great_turn(enemy_data: Array, team: Array[FighterData]) -> Dictionary:
	var enemies := fresh_enemies(enemy_data)
	var groups := [group(Element.Type.FIRE, 5), group(Element.Type.WATER, 3), group(Element.Type.WOOD, 3),
		group(Element.Type.LIGHT, 3), group(Element.Type.DARK, 3), group(Element.Type.HEART, 3)]
	var dealt := attack(team, groups, 6, enemies)
	var left := 0
	for e in enemies:
		left += e.hp
	return {"dealt": dealt, "left": left}
