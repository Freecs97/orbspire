class_name ProgressionTuning
extends Resource
## Levelling numbers in one place.
##
## Plain English:
##   - Stats grow in a straight line from Lv1 (x1) to max level (x2.5 by default).
##   - XP needed for the next level = 50 x current level, and it gets steeper
##     from Lv10: each level from 10 on costs an extra +25% on top (Lv10 x1.25,
##     Lv11 x1.5, Lv12 x1.75 ...).
##       Lv1->2 = 50, Lv5->6 = 250, Lv9->10 = 450, Lv10->11 = 625, Lv14->15 = 1,575.
##     Total to reach Lv10 = 2,250 (what Act 1 pays), Lv10 -> Lv15 = 5,375 more.
##   - Level cap per evolution stage: Stage 1 = Lv15, Stage 2 = Lv30, Stage 3 = Lv30
##     (the top stage). Nothing (fights, Training Cores) can push past the cap.

@export var max_level := 30
@export var stat_mult_at_max := 2.5
@export var xp_per_level := 50
## From this level on, every level costs xp_steep_step more (x1.25, x1.5, ...).
@export var xp_steep_from := 10
@export var xp_steep_step := 0.25
## Highest level for evolution stage 1, 2, 3.
@export var stage_level_caps: Array[int] = [15, 30, 30]

## Until Phase 6 adds real levelling, each fight shows the team at the level a
## player would normally have reached by then (FightData.expected_level).
@export var preview_expected_level := true


## Stat multiplier at a level: 1.0 at Lv1, stat_mult_at_max at max_level.
func stat_mult(level: int) -> float:
	var l := clampi(level, 1, max_level)
	return 1.0 + (stat_mult_at_max - 1.0) * (l - 1) / float(max_level - 1)


## XP needed to go from `level` to level + 1.
func xp_to_next(level: int) -> int:
	var steep := 1.0 + xp_steep_step * maxi(level - xp_steep_from + 1, 0)
	return roundi(xp_per_level * level * steep)


## The level cap for an evolution stage (1-3).
func level_cap(stage: int) -> int:
	return stage_level_caps[clampi(stage, 1, stage_level_caps.size()) - 1]


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
