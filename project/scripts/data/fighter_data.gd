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
## Evolution: each evolution cuts the active skill's cooldown by 1 (never below 1).
@export var cooldown_cut: int = 0
## Evolution stage 1-3 (set from the save; templates are Stage 1).
@export var stage: int = 1
## Dual affinity (Stage 3 only, Catalog.DUAL): the second affinity, -1 = none.
## It attacks when ITS orbs are matched, for 1/3 of ATK (10% if same as main).
@export var sub_element: int = -1
## Rarity 0-5 of the owned unit (set from the save; -1 = a template / test fighter).
## Stage 3 or Singularity (5) = the long 2 s skill cut-in.
@export var rarity: int = -1

@export_group("Enemy only")
## DEF: every orb attack on this enemy loses this much damage (never below 1).
## Skill hits (Execute) ignore DEF. Act 1 uses 0 everywhere.
@export var def: int = 0
## Shield gimmick: takes half damage until a 4+ orb group or a skill hit breaks it.
@export var armored := false
## Bosses can't be killed instantly by Execute (they take a bigger hit instead).
@export var is_boss := false
## Exploration Wardens / bosses: orb attacks of the element it resists do nothing.
@export var element_shield := false
## Which placeholder body to draw: blob, drone, slime, human, sprout, golem, wolf.
@export var kind: StringName = &"blob"

@export_group("Playable enemies (Stage 3 Part B)")
## >= 0: this character always comes at this rarity (enemy characters: Scrap 0,
## Alloy 1, Forged 2). -1 = the rarity is rolled (humans).
@export var fixed_rarity := -1
## Recolour, done in CODE on the existing PNG (no new art): turn the hue by this
## many degrees, scale brightness, then mix in a tint (tint alpha = how much).
@export var recolor_hue := 0.0
@export var recolor_value := 1.0
@export var recolor_tint := Color(1, 1, 1, 0)

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


## Turns between uses of this fighter's active skill (0 = no active skill).
func skill_cooldown() -> int:
	var cd := Skills.cooldown(active_skill)
	return maxi(cd - cooldown_cut, 1) if cd > 0 else 0


## True if this passive is unlocked on this character right now.
func has_passive(id: StringName) -> bool:
	var i := passives.find(id)
	return i >= 0 and i < passives_unlocked
