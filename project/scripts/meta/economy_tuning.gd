class_name EconomyTuning
extends Resource
## Every number for levels, rewards, drops and recruiting, in one place.
## Open res://data/economy.tres in Godot and change anything in the Inspector.

@export_group("Rarity (Scrap, Alloy, Forged, Prime, Ascendant, Singularity)")
@export var rarity_names: Array[String] = ["Scrap", "Alloy", "Forged", "Prime", "Ascendant", "Singularity"]
## Stat multiplier by rarity (HP / ATK / RCV).
@export var rarity_stat_mult: Array[float] = [0.85, 0.92, 1.0, 1.08, 1.16, 1.25]
## Training Cores you get back when retiring, by rarity (plus a share of cores invested).
@export var retire_base_cores: Array[int] = [2, 5, 15, 30, 60, 150]
@export var retire_invested_share := 0.5
## Rarity of the story characters and of characters made from Essence.
@export var story_rarity := 2
@export var crafted_rarity := 2

@export_group("Levels")
## Catch-up XP: characters 3-5 levels below your highest get x1.5, 6+ below get x2.
@export var catch_up_small_gap := 3
@export var catch_up_small_mult := 1.5
@export var catch_up_big_gap := 6
@export var catch_up_big_mult := 2.0
## Passive 1 unlocks at this level (Passives 2 and 3 need evolution art).
@export var passive_1_level := 10

@export_group("Credits")
@export var win_credits_base := 20
@export var win_credits_per_act := 10
@export var mini_boss_credit_mult := 2
@export var boss_credit_mult := 4
## A loss still pays this share of a win.
@export var lose_credit_share := 0.25
## First time you clear an Act: bonus Credits (x Act number) and Keys.
@export var act_clear_bonus_per_act := 300
@export var keys_per_act_clear := 1

@export_group("Digital Essence")
## Each regular enemy has this chance to drop 1 Essence.
@export var essence_regular_chance := 0.15
@export var essence_mini_min := 1
@export var essence_mini_max := 2
@export var essence_boss := 3
@export var essence_to_craft := 10

@export_group("Recruit (Credits)")
@export var recruit_names: Array[String] = ["Basic", "Advanced", "Elite"]
@export var recruit_costs: Array[int] = [300, 1000, 3000]
## Odds in percent for each rarity, one row per tier (must add up to 100).
@export var recruit_odds_basic: Array[int] = [50, 35, 12, 3, 0, 0]
@export var recruit_odds_advanced: Array[int] = [15, 35, 30, 15, 4, 1]
@export var recruit_odds_elite: Array[int] = [0, 10, 35, 35, 15, 5]
## A Key pull: guaranteed Ascendant or better.
@export var key_odds: Array[int] = [0, 0, 0, 0, 80, 20]

@export_group("Roster and Training Cores")
@export var roster_cap_start := 30
@export var roster_expand_slots := 5
@export var roster_expand_cost := 1000
@export var core_cost := 50
@export var core_xp := 100


func odds_for(tier: int) -> Array[int]:
	match tier:
		0:
			return recruit_odds_basic
		1:
			return recruit_odds_advanced
		2:
			return recruit_odds_elite
	return key_odds
