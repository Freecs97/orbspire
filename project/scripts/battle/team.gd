class_name Team
extends RefCounted
## The player's team: 3-4 hunters sharing ONE HP pool (like the genre does).
##
## Plain English: we add up everyone's HP into one bar and everyone's RCV into
## one healing number. Enemies hit the shared bar; Hearts refill it.
## Slot 1 (members[0]) is the leader.
##
## This also holds the team's live battle effects:
##   - skill_turns[i]: turns until hunter i's active skill is ready (0 = ready)
##   - bulwark_attacks: enemy attacks still softened by Bulwark
##   - guard_next_hit: the Titan leader's "next hit does less" is armed

var members: Array[FighterData] = []
var max_hp := 0
var hp := 0
var total_rcv := 0
var skill_turns: Array[int] = []
var bulwark_attacks := 0
var guard_next_hit := false
## Spectre's Ambush: has hunter i already attacked in this fight?
var has_attacked: Array[bool] = []


func _init(member_data: Array[FighterData]) -> void:
	members = member_data
	for m in members:
		max_hp += m.max_hp
		total_rcv += m.rcv
		skill_turns.append(Skills.cooldown(m.active_skill))
		has_attacked.append(false)
	# Titan leader skill: team HP x1.3.
	max_hp = roundi(max_hp * CombatRules.team_hp_multiplier(leader()))
	hp = max_hp


func leader() -> FighterData:
	return members[0] if not members.is_empty() else null


## Returns how much damage was actually taken.
func take_damage(amount: int) -> int:
	var dealt := mini(amount, hp)
	hp -= dealt
	return dealt


## Returns how much was actually healed (healing can't go above max HP).
func heal(amount: int) -> int:
	var healed := mini(amount, max_hp - hp)
	hp += healed
	return healed


func is_defeated() -> bool:
	return hp <= 0


func skill_ready(i: int) -> bool:
	return skill_turns[i] <= 0 and Skills.cooldown(members[i].active_skill) > 0


## A turn with at least one match: every skill charges by one turn.
func tick_skills(turns := 1) -> void:
	for i in skill_turns.size():
		skill_turns[i] = maxi(skill_turns[i] - turns, 0)


func hp_ratio() -> float:
	return float(hp) / maxi(max_hp, 1)
