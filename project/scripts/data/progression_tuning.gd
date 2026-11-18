class_name ProgressionTuning
extends Resource
## Levelling numbers in one place (Phase 6 builds the full levelling system).
##
## Plain English:
##   - Stats grow in a straight line from Lv1 (x1) to max level (x3 by default).
##   - XP needed for the next level = xp_base + xp_step x (current level - 1).
##     With 50 / 25: Lv1->2 needs 50, Lv2->3 needs 75, ... Lv9->10 needs 250.
##     Total to reach Lv10 = 1,350, which is exactly Act 1's total XP.

@export var max_level := 30
@export var stat_mult_at_max := 3.0
@export var xp_base := 50
@export var xp_step := 25

## Until Phase 6 adds real levelling, each fight shows the team at the level a
## player would normally have reached by then (FightData.expected_level).
@export var preview_expected_level := true


## Stat multiplier at a level: 1.0 at Lv1, stat_mult_at_max at max_level.
func stat_mult(level: int) -> float:
	var l := clampi(level, 1, max_level)
	return 1.0 + (stat_mult_at_max - 1.0) * (l - 1) / float(max_level - 1)


## XP needed to go from `level` to level + 1.
func xp_to_next(level: int) -> int:
	return xp_base + xp_step * (level - 1)


## Total XP needed to reach `level` from Lv1.
func total_xp_for(level: int) -> int:
	var total := 0
	for l in range(1, level):
		total += xp_to_next(l)
	return total


## Level reached with this much total XP (starting at Lv1).
func level_for_xp(xp: int) -> int:
	var level := 1
	while level < max_level and xp >= total_xp_for(level + 1):
		level += 1
	return level
