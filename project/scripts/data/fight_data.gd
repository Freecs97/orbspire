class_name FightData
extends Resource
## One fight: a name, the enemies in it (1 to 3), and what winning gives.
##
## Plain English: an Act is a list of these. Edit the .tres files in
## res://data/fights/ to change who you fight. The first enemy in the list
## stands on the left.

@export var display_name: String = "FIGHT"
@export var enemies: Array[FighterData] = []
## XP each team member gets for winning (Phase 6 turns this into levels).
@export var xp: int = 0
## The level the story team is expected to be at during this fight, if the
## player wins each fight once. Balance is tuned against this level.
@export_range(1, 120) var expected_level: int = 1
