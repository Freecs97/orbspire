class_name FighterData
extends Resource
## Stats, skills and placeholder look for one fighter (a hunter or an enemy).
##
## Plain English: this is a "data card". The actual numbers live in the .tres
## files in res://data/. Double-click one in Godot's FileSystem panel and you
## can change HP / ATK / skills / colour in the Inspector without touching code.
##
## Type (role) only sets the HP / ATK / RCV pattern. Skills belong to the DESIGN,
## so two Berserker designs could have completely different skills.

## The 4 types (PAD-style). ENEMY is for monsters.
enum Role { BERSERKER, TITAN, SPECTRE, BIOTECH, ENEMY }

## The name shown in game (e.g. "KAELA RYNN", "HELIOS", "EMBER DRONE").
@export var display_name: String = ""
## What it is, shown next to the name (e.g. "Fire Berserker", "Solar Drone"). Empty = none.
@export var title: String = ""
@export var element: Element.Type = Element.Type.FIRE
@export var role: Role = Role.BERSERKER
@export var max_hp: int = 300
@export var atk: int = 100
@export var rcv: int = 0

@export_group("Skills (belong to the design)")
## Which design this is (art + skills). Example: "berserker_proto".
@export var design_id: String = ""
## Leader skill id (see scripts/skills/skills.gd). Only used in team slot 1.
@export var leader_skill: StringName = &""
## Active skill id (tap the card when it glows).
@export var active_skill: StringName = &""
## Passives in unlock order: [Lv10, Evolution 1, Evolution 2].
@export var passives: Array[StringName] = []
## How many passives are unlocked right now (0-3). Phase 6 sets this from
## level / evolution. A new Lv1 character has 0.
@export_range(0, 3) var passives_unlocked: int = 0

@export_group("Enemy only")
## DEF: every orb attack on this enemy loses this much damage (never below 1).
## Skill hits (Execute) ignore DEF. Act 1 uses 0 everywhere.
@export var def: int = 0
## Shield gimmick: takes half damage until a 4+ orb group or a skill hit breaks it.
@export var armored := false
## Bosses can't be killed instantly by Execute (they take a bigger hit instead).
@export var is_boss := false
## Which placeholder body to draw: blob, drone, slime, human, sprout, golem, wolf.
@export var kind: StringName = &"blob"

@export_group("Later phases (data only, not used yet)")
## Reserved for branching evolution / Reincarnation / variants. Not coded yet.
@export var evolution_branch: StringName = &""

@export_group("Art")
## Your PNG for this fighter (transparent). Empty = draw the code placeholder.
## figure_height below sets how tall it is drawn on screen.
@export var art: Texture2D

@export_group("Placeholder look")
## Main colour of the drawn body.
@export var body_color: Color = Color.WHITE
## How tall the drawn figure is, in pixels (feet to top of head).
@export var figure_height: float = 220.0
## How wide the body is, in pixels.
@export var figure_width: float = 70.0


func is_enemy() -> bool:
	return role == Role.ENEMY


## True if this passive is unlocked on this character right now.
func has_passive(id: StringName) -> bool:
	var i := passives.find(id)
	return i >= 0 and i < passives_unlocked
