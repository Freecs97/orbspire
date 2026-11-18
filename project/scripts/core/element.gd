class_name Element
extends RefCounted
## Elements (affinities) and the element wheel.
##
## Plain English: every orb and every fighter has an element.
## Fire beats Wood, Wood beats Water, Water beats Fire.
## Light and Dark beat EACH OTHER (both ways).
## Hitting an element you beat = 2x damage. Hitting the one that beats you = 0.5x.
## Light vs Dark is 2x in both directions, and Light/Dark vs Fire/Water/Wood is 1x.
## Heart is not an attack element: Heart orbs only heal.
##
## The numbers in the enum are saved inside the .tres data files, so new
## elements are added at the END (LIGHT = 5, DARK = 6) to keep old files valid.

enum Type { FIRE, WATER, WOOD, HEART, NONE, LIGHT, DARK }

const STRONG := 2.0
const NEUTRAL := 1.0
const WEAK := 0.5

## Every orb type that can appear on the board (6 types from Act 1).
const BOARD_TYPES := [Type.FIRE, Type.WATER, Type.WOOD, Type.LIGHT, Type.DARK, Type.HEART]
## The orb types that make a character attack (everything except Heart).
const ATTACK_TYPES := [Type.FIRE, Type.WATER, Type.WOOD, Type.LIGHT, Type.DARK]

## Key beats value.
const BEATS := {
	Type.FIRE: Type.WOOD,
	Type.WOOD: Type.WATER,
	Type.WATER: Type.FIRE,
	Type.LIGHT: Type.DARK,
	Type.DARK: Type.LIGHT,
}


## Element multiplier for an attacker hitting a defender.
static func multiplier(attacker: int, defender: int) -> float:
	if BEATS.get(attacker, -1) == defender:
		return STRONG
	if BEATS.get(defender, -1) == attacker:
		return WEAK
	return NEUTRAL


## Which element is strong against this one (e.g. WOOD -> FIRE). NONE if nothing.
static func beaten_by(type: int) -> int:
	for attacker in BEATS:
		if BEATS[attacker] == type:
			return attacker
	return Type.NONE


## True for Light and Dark (they have no "resists" side).
static func is_light_or_dark(type: int) -> bool:
	return type == Type.LIGHT or type == Type.DARK


static func color(type: int) -> Color:
	match type:
		Type.FIRE:
			return Color("ff4a2b")
		Type.WATER:
			return Color("2fa8ff")
		Type.WOOD:
			return Color("3ddc5a")
		Type.LIGHT:
			return Color("ffd23f")
		Type.DARK:
			return Color("a64dff")
		Type.HEART:
			return Color("ff6fb5")
	return Color("9a9aa8")


static func display_name(type: int) -> String:
	match type:
		Type.FIRE:
			return "FIRE"
		Type.WATER:
			return "WATER"
		Type.WOOD:
			return "WOOD"
		Type.LIGHT:
			return "LIGHT"
		Type.DARK:
			return "DARK"
		Type.HEART:
			return "HEART"
	return "NONE"
