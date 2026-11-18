class_name Enemy
extends RefCounted
## One enemy's live battle state (its data card, current HP, armour).
##
## Armour (the Act 1 "Shield" gimmick): while it is up, the enemy takes HALF
## damage. A hit that "breaks armour" (from a 4+ orb group, or any active-skill
## hit) knocks it off first and then deals FULL damage. A hit that "ignores
## armour" (the Breaker passive) deals full damage but leaves the armour up.

const ARMOR_FACTOR := 0.5

var data: FighterData
var hp := 0
var armor_up := false


func _init(enemy_data: FighterData) -> void:
	data = enemy_data
	hp = data.max_hp
	armor_up = data.armored


## Apply one hit. Returns the damage actually dealt (after armour, capped by HP).
func take_hit(amount: int, breaks_armor := false, ignores_armor := false) -> int:
	if armor_up and breaks_armor:
		armor_up = false
	elif armor_up and not ignores_armor:
		amount = roundi(amount * ARMOR_FACTOR)
	var dealt := mini(amount, hp)
	hp -= dealt
	return dealt


## Old name kept for simple callers: a plain hit with no armour rules.
func take_damage(amount: int) -> int:
	return take_hit(amount)


func hp_ratio() -> float:
	return float(hp) / maxi(data.max_hp, 1)


func is_defeated() -> bool:
	return hp <= 0
