class_name Team
extends RefCounted
## The player's team: 1-4 hunters sharing ONE HP pool (like the genre does).
##
## Plain English: we add up everyone's HP into one bar and everyone's RCV into
## one healing number. Enemies hit the shared bar; Hearts refill it.
## Slot 1 (members[0]) is the leader.
##
## This also holds the team's live battle effects:
##   - skill_turns[i]: turns until hunter i's active skill is ready (0 = ready)
##   - bulwark_attacks: enemy attacks still softened by Bulwark
##   - shields: other "next N attacks do less" skills (Forge Guard, Tidewall, Sanctuary)
##   - guard_next_hit / guard_mult: a leader's "next hit does less" (Stone Wall, Riptide)
##   - last_stand_used: Last Stand already saved the team this fight
##   - regen_turns: Night Bloom heals left (start of each turn)
##   - boost_element / boost_mult: one-turn ATK boost from a skill (Solar Flare, Cauterize)

var members: Array[FighterData] = []
var max_hp := 0
var hp := 0
var total_rcv := 0
var skill_turns: Array[int] = []
var bulwark_attacks := 0
var guard_next_hit := false
var guard_mult := 1.0
## Each: {"name": String, "attacks": int, "mult": float, "counter": member index or -1}
var shields: Array = []
var last_stand_used := false
var regen_turns := 0
var regen_ratio := 0.0
var boost_element := -1
var boost_mult := 1.0
## Spectre's Ambush: has hunter i already attacked in this fight?
var has_attacked: Array[bool] = []


func _init(member_data: Array[FighterData]) -> void:
	members = member_data
	var t := Skills.TUNING
	var rcv := 0.0
	var hp_sum := 0.0
	for m in members:
		hp_sum += m.max_hp * (1.0 + (t.hp_up_ratio if m.has_passive(&"hp_up") else 0.0))
		rcv += m.rcv * (1.0 + (t.rcv_up_ratio if m.has_passive(&"rcv_up") else 0.0))
		skill_turns.append(m.skill_cooldown())
		has_attacked.append(false)
	# Leader skills: team HP x (Stone Wall, Molten Ward, ...), team RCV x (Deep Current, ...).
	max_hp = roundi(hp_sum * CombatRules.team_hp_multiplier(leader()))
	total_rcv = roundi(rcv * CombatRules.team_rcv_multiplier(leader()))
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
	return skill_turns[i] <= 0 and members[i].skill_cooldown() > 0


## A turn with at least one match: every skill charges by one turn.
func tick_skills(turns := 1) -> void:
	for i in skill_turns.size():
		skill_turns[i] = maxi(skill_turns[i] - turns, 0)


func hp_ratio() -> float:
	return float(hp) / maxi(max_hp, 1)


func add_shield(shield_name: String, attacks: int, mult: float, counter := -1) -> void:
	shields.append({"name": shield_name, "attacks": attacks, "mult": mult, "counter": counter})


## One-turn skill boost for this member (x1 if none).
func boost_for(member: FighterData) -> float:
	return boost_mult if boost_element >= 0 and member.element == boost_element else 1.0
