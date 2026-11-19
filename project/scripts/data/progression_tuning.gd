class_name ProgressionTuning
extends Resource
## Levelling numbers in one place.
##
## Plain English:
##   - Lv1-30 (Galaxy 1, locked since Stage 6): stats grow in a straight line from
##     Lv1 (x1) to Lv30 (x2.5). XP for the next level = 50 x level, and from Lv10
##     each level costs an extra +25% on top (Lv10 x1.25, Lv11 x1.5, Lv12 x1.75 ...).
##       Lv1->2 = 50, Lv5->6 = 250, Lv9->10 = 450, Lv10->11 = 625, Lv14->15 = 1,575.
##   - Lv31-120 (the rest of the universe): each level is +2% of the Lv30 stats
##     (Lv60 = x1.6 of Lv30, Lv120 = x2.8 of Lv30). XP for the next level =
##     75 x level, and the extra steps go from +25% to +35% per level, carrying on
##     from where Lv30 stopped (so Lv31 costs more than Lv30, never less).
##   - Level cap per evolution stage: Stage 1 = Lv15, Stage 2 = Lv30, Stage 3 = Lv60,
##     Stage 4 = Lv90, Stage 5 = Lv120. Stages 4 and 5 are RESERVED (no art or code
##     yet), so for now a hunter stops at Lv60.
##   - On top of that each galaxy has a cap (Galaxy 1 = Lv30): see Cosmos.

@export var max_level := 120
@export var stat_mult_at_max := 2.5   ## the multiplier at stat_linear_until (Lv30)
## Stats grow in a straight line up to this level...
@export var stat_linear_until := 30
## ...then each level adds this share of the Lv30 stats (+2%).
@export var stat_per_level_after := 0.02
@export var xp_per_level := 50
## From this level on, every level costs xp_steep_step more (x1.25, x1.5, ...).
@export var xp_steep_from := 10
@export var xp_steep_step := 0.25
## After stat_linear_until: XP base per level and the bigger step (+35%).
@export var xp_per_level_after := 75
@export var xp_steep_step_after := 0.35
## Highest level for evolution stage 1, 2, 3, 4, 5 (4 and 5 reserved).
@export var stage_level_caps: Array[int] = [15, 30, 60, 90, 120]
## The highest evolution stage that is actually built (art + code).
@export var built_stages := 3

## Until Phase 6 adds real levelling, each fight shows the team at the level a
## player would normally have reached by then (FightData.expected_level).
@export var preview_expected_level := true


## Stat multiplier at a level: 1.0 at Lv1, 2.5 at Lv30, then +2% of that per level.
func stat_mult(level: int) -> float:
	var l := clampi(level, 1, max_level)
	var top := stat_linear_until
	if l <= top:
		return 1.0 + (stat_mult_at_max - 1.0) * (l - 1) / float(top - 1)
	return stat_mult_at_max * (1.0 + stat_per_level_after * (l - top))


## XP needed to go from `level` to level + 1.
func xp_to_next(level: int) -> int:
	if level <= stat_linear_until:
		var steep := 1.0 + xp_steep_step * maxi(level - xp_steep_from + 1, 0)
		return roundi(xp_per_level * level * steep)
	# Carry on from Lv30's multiplier (x6.25), +35% per level instead of +25%.
	var at_top := 1.0 + xp_steep_step * maxi(stat_linear_until - xp_steep_from + 1, 0)
	var steep_after := at_top + xp_steep_step_after * (level - stat_linear_until)
	return roundi(xp_per_level_after * level * steep_after)


## The level cap for an evolution stage (1-5).
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
