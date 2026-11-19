class_name EconomyTuning
extends Resource
## Every number for levels, rewards, drops and recruiting, in one place.
## Open res://data/economy.tres in Godot and change anything in the Inspector.

@export_group("Rarity (Scrap, Alloy, Forged, Prime, Ascendant, Singularity)")
@export var rarity_names: Array[String] = ["Scrap", "Alloy", "Forged", "Prime", "Ascendant", "Singularity"]
## Stat multiplier by rarity (HP / ATK / RCV).
@export var rarity_stat_mult: Array[float] = [0.85, 0.92, 1.0, 1.07, 1.14, 1.2]
## Training Cores you get back when retiring, by rarity (plus a share of cores invested).
@export var retire_base_cores: Array[int] = [2, 5, 15, 30, 60, 150]
@export var retire_invested_share := 0.5
## Rarity of the story characters (never below Forged).
@export var story_rarity := 2

@export_group("Levels")
## Catch-up XP: characters 3-5 levels below your highest get x1.5, 6+ below get x2.
@export var catch_up_small_gap := 3
@export var catch_up_small_mult := 1.5
@export var catch_up_big_gap := 6
@export var catch_up_big_mult := 2.0
## Low-level enemies give less XP. Gap = your strongest team member's level minus
## the fight's level. Gap 3+ -> x0.5, 10+ -> x0.25, 15+ -> nothing.
@export var xp_falloff_gaps: Array[int] = [3, 10, 15]
@export var xp_falloff_mults: Array[float] = [0.5, 0.25, 0.0]
## Passive 1 unlocks at this level (Passives 2 and 3 need evolution art).
@export var passive_1_level := 10

@export_group("Evolution")
## Evolution 1 (Stage 1 -> 2) needs Lv15, Evolution 2 (Stage 2 -> 3) needs Lv30
## (the level caps in progression.tres). Cost per evolution: Credits + Training Cores.
@export var evo_credits: Array[int] = [1000, 5000]
@export var evo_cores: Array[int] = [5, 20]
## Each evolution: +10% HP / ATK / RCV, active cooldown -1, the next passive.
@export var evo_stat_bonus := 0.10

@export_group("Credits")
@export var win_credits_base := 20
@export var win_credits_per_act := 10
@export var mini_boss_credit_mult := 2
@export var boss_credit_mult := 4
## A loss still pays this share of a win.
@export var lose_credit_share := 0.25
## First time you clear an Act: bonus Credits (x Act number) and Keys.
## Keys come ONLY from first Act clears (later: weekly quests and Event Rifts).
@export var act_clear_bonus_per_act := 300
@export var keys_per_act_clear := 1

@export_group("Digital Essence")
## Each regular enemy has this chance to drop Essence...
@export var essence_regular_chance := 0.3
## ...and a drop gives this many (Stage 3 Part B: 30% x 2, was 15% x 1).
@export var essence_regular_amount := 2
## The 10 playable enemies: share of their drops that is their OWN Essence
## (the rest goes to a human character, as before).
@export var essence_own_share := 0.5
@export var essence_mini_min := 1
@export var essence_mini_max := 2
@export var essence_boss := 3
@export var essence_to_craft := 10
## Rarity of a character made from Essence, by rarity band (Acts 1-2, 3-4, 5-6, 7-10).
@export var crafted_rarity_by_band: Array[int] = [1, 2, 2, 3]

@export_group("Scrap character drops")
## Act 1: the first clear of fights 1..N always gives a Scrap character.
@export var scrap_guaranteed_fights := 2
## Later wins of regular (non-boss) fights: chance of a Scrap character...
@export var scrap_drop_chance := 0.1
## ...in Acts 1..this one only.
@export var scrap_drop_max_act := 2

@export_group("Friend drops (ultra-rare)")
## After ANY won fight (any Act, bosses too): this chance that one of Bailey's
## friends joins (0.0025 = 0.25% = about 1 win in 400). Prefers friends you
## don't own yet. They join even if the roster is full. Never in Recruit or the Lab.
@export var friend_drop_chance := 0.0025

@export_group("Recruit")
@export var recruit_names: Array[String] = ["Basic", "Advanced", "Elite"]
@export var recruit_costs: Array[int] = [150, 1000, 3000]
## Rarity bands: the first Act of each band. Your band = the highest Act you have unlocked.
##   Band 1 = Acts 1-2, Band 2 = Acts 3-4, Band 3 = Acts 5-6, Band 4 = Acts 7-10.
## Prime first appears in Band 2 (Act 3+), Ascendant in Band 3 (Act 5+),
## Singularity in Band 4 (Act 7+) and ONLY from a Key.
@export var band_first_act: Array[int] = [1, 3, 5, 7]
## Odds in percent per rarity (Scrap .. Singularity), each row adds up to 100.
## One block of 4 rows per band: Basic, Advanced, Elite, Key.
@export var recruit_odds: Array[Array] = [
	[65, 30, 5, 0, 0, 0], [50, 38, 12, 0, 0, 0], [35, 50, 15, 0, 0, 0], [0, 40, 60, 0, 0, 0],
	[55, 33, 10, 2, 0, 0], [35, 40, 20, 5, 0, 0], [15, 40, 35, 10, 0, 0], [0, 15, 55, 30, 0, 0],
	[45, 35, 16, 4, 0, 0], [25, 38, 27, 9, 1, 0], [5, 30, 40, 20, 5, 0], [0, 0, 45, 40, 15, 0],
	[35, 38, 21, 5, 1, 0], [15, 35, 32, 14, 4, 0], [0, 20, 40, 28, 12, 0], [0, 0, 30, 45, 22, 3],
]

@export_group("Roster and Training Cores")
@export var roster_cap_start := 30
@export var roster_expand_slots := 5
@export var roster_expand_cost := 1000
@export var core_cost := 50
@export var core_xp := 100


## Which rarity band (0-3) an Act is in.
func band_for_act(act: int) -> int:
	var band := 0
	for i in band_first_act.size():
		if act >= band_first_act[i]:
			band = i
	return band


## Odds for tier 0-2 (Basic / Advanced / Elite) or 3 (Key), at this Act.
func odds_for(tier: int, act := 1) -> Array[int]:
	var out: Array[int] = []
	for v in recruit_odds[band_for_act(act) * 4 + clampi(tier, 0, 3)]:
		out.append(int(v))
	return out


## Highest rarity a tier can give at this Act (-1 if none).
func best_rarity(tier: int, act := 1) -> int:
	var odds := odds_for(tier, act)
	for r in range(odds.size() - 1, -1, -1):
		if odds[r] > 0:
			return r
	return -1


func crafted_rarity(act: int) -> int:
	return crafted_rarity_by_band[band_for_act(act)]


## XP multiplier for a fight `gap` levels below your strongest team member.
func xp_falloff(gap: int) -> float:
	var m := 1.0
	for i in xp_falloff_gaps.size():
		if gap >= xp_falloff_gaps[i]:
			m = xp_falloff_mults[i]
	return m
