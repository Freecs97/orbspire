class_name ActData
extends Resource
## One Act = one colony and the singularity that took it.
##
## Plain English: all of an Act's story lives here, short and skippable:
##   - intel_lines:  3 lines for the star map (what the colony was for, what
##                   singularity took it, what the Progenitors did about it)
##   - intro_lines:  2 lines before the first fight (once, skippable)
##   - boss_taunt:   1-2 lines when the boss fight starts (skippable)
##   - outro_line:   2-3 lines after the boss falls (skippable)
##   - codex_*:      the singularity's 4-line codex entry, unlocked when you kill it
## The approved text lives in scripts/data/story_text.gd; tools/apply_story.gd
## copies it into the .tres files in res://data/acts/.

@export var act_number: int = 1
@export var colony_name: String = ""
@export var colony_kind: String = ""                 ## e.g. "Furnace Colony"
@export var singularity_name: String = ""
@export var singularity_kind: String = ""            ## e.g. "Plasma Wolf"
@export var element: Element.Type = Element.Type.FIRE
## The fights in order. Empty = this Act isn't built yet.
@export var fights: Array[FightData] = []
## Your arena background for this Act's fights.
@export var arena: Texture2D
## Your boss art (also shown in the codex).
@export var boss_art: Texture2D

@export_group("Story (light, skippable)")
@export var intel_lines: Array[String] = []
@export var intro_lines: Array[String] = []
@export_multiline var boss_taunt: String = ""
@export_multiline var outro_line: String = ""
@export var intro_seconds := 10.0
@export var taunt_seconds := 5.0
@export var outro_seconds := 10.0

@export_group("Singularity codex (4 lines, approved 2026-11-19)")
## What the colony was.
@export_multiline var codex_colony: String = ""
## What the Progenitors rationed / quarantined there.
@export_multiline var codex_rationed: String = ""
## What the singularity was spliced from, when and why.
@export_multiline var codex_spliced_from: String = ""
## Why it was abandoned.
@export_multiline var codex_abandoned: String = ""


@export_group("Exploration world (made by Cosmos, never saved)")
## "g-s-w" for a generated world; "" = a story Act.
@export var world_key := ""
@export var rec_level := 0
## Highest level reachable from these fights (the galaxy cap; Galaxy 1 = 30).
@export var level_cap := 30
## Credits are paid as if this were Act N (0 = act_number).
@export var reward_act := 0
## Its Stage 5 boss is the solar system's singularity.
@export var is_gate := false
## All stages one affinity.
@export var pure := false
## The arena picture is an Act arena, hue-shifted by this much (0 = as drawn).
@export var arena_hue := 0.0


func is_world() -> bool:
	return world_key != ""


func is_built() -> bool:
	return not fights.is_empty()
