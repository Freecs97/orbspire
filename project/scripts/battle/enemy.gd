class_name Enemy
extends RefCounted
## One enemy's live battle state (its data card, current HP, armour).
##
## Armour (the Act 1 "Shield" gimmick): while it is up, the enemy takes HALF
## damage. A hit that "breaks armour" (from a 4+ orb group, or any active-skill
## hit) knocks it off first and then deals FULL damage. A hit that "ignores
## armour" (the Breaker passive) deals full damage but leaves the armour up.

##
## Resolve (bosses and mini-bosses): they can lose at most half their max HP
## in one player turn (Skills.TUNING.boss_turn_cap), so nothing one-shots them.

const ARMOR_FACTOR := 0.5

var data: FighterData
var hp := 0
var armor_up := false
## Damage taken so far this player turn (for Resolve). new_turn() resets it.
var turn_taken := 0
## false = no Resolve (only the balance tools use this, to measure raw damage).
var resolve := true
## Thorn Snipe: takes x vulnerable_mult damage from everything for this many player turns.
var vulnerable_turns := 0
var vulnerable_mult := 1.0
## Gravity Well: its next N attacks are weaker.
var weakened_attacks := 0
var weakened_mult := 1.0
## Thunder Hammer (Johnny): it skips its next N attacks (never bosses).
var stunned_attacks := 0
## Inferno Cleaver (Logan): takes burn_damage at the start of each of the next burn_turns player turns.
var burn_turns := 0
var burn_damage := 0


## Call at the start of every player turn.
func new_turn() -> void:
	turn_taken = 0
	vulnerable_turns = maxi(vulnerable_turns - 1, 0)


## Its attack this enemy turn (Gravity Well softens it and uses up one charge).
func attack_power() -> float:
	if weakened_attacks > 0:
		weakened_attacks -= 1
		return data.atk * weakened_mult
	return float(data.atk)


## How much more damage this enemy can take this turn (Resolve), or -1 = no limit.
func turn_room() -> int:
	var cap := Skills.TUNING.boss_turn_cap
	if not data.is_boss or not resolve or cap >= 1.0:
		return -1
	return maxi(ceili(data.max_hp * cap) - turn_taken, 0)


func _init(enemy_data: FighterData) -> void:
	data = enemy_data
	hp = data.max_hp
	armor_up = data.armored


## Apply one hit. Returns the damage actually dealt (after armour, capped by HP).
func take_hit(amount: int, breaks_armor := false, ignores_armor := false) -> int:
	if vulnerable_turns > 0:
		amount = roundi(amount * vulnerable_mult)
	if armor_up and breaks_armor:
		armor_up = false
	elif armor_up and not ignores_armor:
		amount = roundi(amount * ARMOR_FACTOR)
	var dealt := mini(amount, hp)
	var room := turn_room()
	if room >= 0:
		dealt = mini(dealt, room)
	hp -= dealt
	turn_taken += dealt
	return dealt


## Old name kept for simple callers: a plain hit with no armour rules.
func take_damage(amount: int) -> int:
	return take_hit(amount)


func hp_ratio() -> float:
	return float(hp) / maxi(data.max_hp, 1)


func is_defeated() -> bool:
	return hp <= 0
