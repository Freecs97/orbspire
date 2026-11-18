class_name DamageCalculator
extends RefCounted
## All battle maths lives here, in one place, so it is easy to check and tune.
##
## Damage per character = ATK x (orbs of its element cleared / 3)
##                        x Combo Multiplier x Element Multiplier
##                        x leader skill x passives (if any)
## Combo Multiplier      = 1 + 0.25 x (combos - 1)
## Healing               = team RCV x (Hearts cleared / 3)   (capped by Team.heal)

const COMBO_STEP := 0.25


static func combo_multiplier(combos: int) -> float:
	return 1.0 + COMBO_STEP * maxi(combos - 1, 0)


## Returns 0 if the character's element was not cleared this turn (no attack).
## `bonus` = leader skill x passives (1.0 = none). Rounded ONCE, at the end.
static func attack_damage(atk: int, orbs_cleared: int, combos: int, attacker: int, defender: int, bonus := 1.0) -> int:
	if orbs_cleared <= 0:
		return 0
	var raw := atk * (orbs_cleared / 3.0) * combo_multiplier(combos) * Element.multiplier(attacker, defender) * bonus
	return roundi(raw)


static func healing(total_rcv: int, hearts_cleared: int) -> int:
	if hearts_cleared <= 0:
		return 0
	return roundi(total_rcv * (hearts_cleared / 3.0))
