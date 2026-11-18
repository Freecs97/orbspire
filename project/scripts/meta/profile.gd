class_name Profile
extends RefCounted
## Everything the player owns, and the rules for changing it.
##
## Plain English: this wraps the save file's dictionary.
##   units     - every character you own: which one, its level, XP, rarity,
##               whether it's locked, and how many Training Cores went into it
##   team      - up to 4 unit ids (slot 1 leads). Act 1 uses the first 3.
##   credits, cores (Training Cores), keys, essence {character id: amount}
##   roster_cap - how many characters you can hold (30, +5 per expansion)
## All numbers come from data/economy.tres and data/progression.tres.

const ECONOMY: EconomyTuning = preload("res://data/economy.tres")
const PROGRESSION: ProgressionTuning = preload("res://data/progression.tres")
const STORY_START := ["berserker_01_angel_fire", "biotech_01_medic_water", "titan_01_shield_wood"]
const SPECTRE_ID := "spectre_01_rogue_dark"
const DEFAULTS := {"units": [], "next_uid": 1, "team": [], "credits": 0, "cores": 0, "keys": 0,
	"essence": {}, "roster_cap": 30, "first_clears": []}

var data: Dictionary
var rng := RandomNumberGenerator.new()


func _init(save: Dictionary) -> void:
	data = save
	for k in DEFAULTS:
		if not data.has(k):
			data[k] = DEFAULTS[k].duplicate(true) if DEFAULTS[k] is Array or DEFAULTS[k] is Dictionary else DEFAULTS[k]
	if data["roster_cap"] < ECONOMY.roster_cap_start:
		data["roster_cap"] = ECONOMY.roster_cap_start
	rng.randomize()
	_fix_types()


## A brand-new save starts with the story trio (Forged, Lv1) as the team.
func ensure_start() -> void:
	if not data["units"].is_empty():
		return
	for id in STORY_START:
		data["team"].append(add_unit(id, ECONOMY.story_rarity))


## The Dark Spectre joins (story, Act 2): added once, placed in slot 4.
func join_spectre() -> bool:
	for u in data["units"]:
		if u["id"] == SPECTRE_ID:
			return false
	var uid := add_unit(SPECTRE_ID, ECONOMY.story_rarity, maxi(highest_level() - 2, 1))
	while data["team"].size() < 4:
		data["team"].append(-1)
	if data["team"][3] == -1:
		data["team"][3] = uid
	return true


# ---------------------------------------------------------------- units

func add_unit(id: String, rarity: int, level := 1) -> int:
	var uid: int = data["next_uid"]
	data["next_uid"] = uid + 1
	data["units"].append({"uid": uid, "id": id, "level": level, "xp": 0, "rarity": rarity, "locked": false, "cores": 0})
	return uid


func unit(uid: int) -> Dictionary:
	for u in data["units"]:
		if u["uid"] == uid:
			return u
	return {}


func roster_full() -> bool:
	return data["units"].size() >= data["roster_cap"]


func highest_level() -> int:
	var best := 1
	for u in data["units"]:
		best = maxi(best, u["level"])
	return best


## The unit as a fighter: its character's data with stats for its level and rarity,
## and Passive 1 unlocked from Lv10 (Passives 2-3 need evolution art).
func fighter(uid: int) -> FighterData:
	var u := unit(uid)
	var base := Catalog.template(u["id"])
	var f: FighterData = base.duplicate()
	var m: float = PROGRESSION.stat_mult(u["level"]) * ECONOMY.rarity_stat_mult[u["rarity"]]
	f.max_hp = roundi(base.max_hp * m)
	f.atk = roundi(base.atk * m)
	f.rcv = roundi(base.rcv * m)
	f.passives_unlocked = 1 if u["level"] >= ECONOMY.passive_1_level else 0
	return f


# ---------------------------------------------------------------- team

## The team's unit ids for a fight (Act 1: 3 slots, later Acts: 4). Empty slots skipped.
func team_uids(size: int) -> Array:
	var out := []
	for i in mini(size, data["team"].size()):
		if data["team"][i] != -1 and not unit(data["team"][i]).is_empty():
			out.append(data["team"][i])
	return out


func team_fighters(size: int) -> Array[FighterData]:
	var out: Array[FighterData] = []
	for uid in team_uids(size):
		out.append(fighter(uid))
	return out


## Put a unit in a team slot. If it's already in another slot, the two swap.
func set_team_slot(slot: int, uid: int) -> void:
	while data["team"].size() <= slot:
		data["team"].append(-1)
	var old: int = data["team"][slot]
	var at: int = data["team"].find(uid)
	if at >= 0 and at != slot:
		data["team"][at] = old
	data["team"][slot] = uid


func in_team(uid: int) -> bool:
	return uid in data["team"]


# ---------------------------------------------------------------- levels

## Give XP to these units (catch-up bonus for ones far below your highest).
## Returns lines like "WATER BIOTECH Lv10! Passive unlocked".
func grant_xp(uids: Array, amount: int) -> Array[String]:
	var lines: Array[String] = []
	var top := highest_level()
	for uid in uids:
		var u := unit(uid)
		var gap := top - int(u["level"])
		var mult := 1.0
		if gap >= ECONOMY.catch_up_big_gap:
			mult = ECONOMY.catch_up_big_mult
		elif gap >= ECONOMY.catch_up_small_gap:
			mult = ECONOMY.catch_up_small_mult
		var before: int = u["level"]
		add_xp(u, roundi(amount * mult))
		if u["level"] > before:
			var line := "%s Lv%d!" % [Catalog.display_name(u["id"]), u["level"]]
			if before < ECONOMY.passive_1_level and u["level"] >= ECONOMY.passive_1_level:
				line += " Passive unlocked"
			lines.append(line)
	return lines


func add_xp(u: Dictionary, amount: int) -> void:
	u["xp"] = int(u["xp"]) + amount
	while u["level"] < PROGRESSION.max_level and u["xp"] >= PROGRESSION.xp_to_next(u["level"]):
		u["xp"] -= PROGRESSION.xp_to_next(u["level"])
		u["level"] = int(u["level"]) + 1
	if u["level"] >= PROGRESSION.max_level:
		u["xp"] = 0


# ---------------------------------------------------------------- fight rewards

## Called after every fight. Returns what was earned, for the result screen.
## WIN: XP to the team, Credits, Essence drops; first Act clear: bonus + Keys.
## LOSE: a share of the Credits only.
func fight_rewards(fight: FightData, act_number: int, won: bool, team: Array, is_act_clear: bool) -> Dictionary:
	var e := ECONOMY
	var credits := e.win_credits_base + e.win_credits_per_act * act_number
	var top := fight.enemies[0]
	if top.is_boss and top.art and top.art.resource_path.contains("/bosses/"):
		credits *= e.boss_credit_mult
	elif top.is_boss:
		credits *= e.mini_boss_credit_mult
	var r := {"credits": 0, "xp": 0, "essence": {}, "keys": 0, "level_ups": []}
	if not won:
		r["credits"] = roundi(credits * e.lose_credit_share)
		data["credits"] += r["credits"]
		return r
	r["credits"] = credits
	r["xp"] = fight.xp
	r["level_ups"] = grant_xp(team, fight.xp)
	# Essence: each enemy drops for its own character.
	for d in fight.enemies:
		var n := 0
		if d.is_boss and d.art and d.art.resource_path.contains("/bosses/"):
			n = e.essence_boss
		elif d.is_boss:
			n = rng.randi_range(e.essence_mini_min, e.essence_mini_max)
		elif rng.randf() < e.essence_regular_chance:
			n = 1
		if n > 0:
			var id := Catalog.essence_for(d, act_number)
			r["essence"][id] = int(r["essence"].get(id, 0)) + n
			data["essence"][id] = int(data["essence"].get(id, 0)) + n
	if is_act_clear and not act_number in data["first_clears"]:
		data["first_clears"].append(act_number)
		r["credits"] += e.act_clear_bonus_per_act * act_number
		r["keys"] = e.keys_per_act_clear
		data["keys"] += r["keys"]
	data["credits"] += r["credits"]
	return r


## One line for the result screen.
static func rewards_text(r: Dictionary) -> String:
	var parts := PackedStringArray()
	if r["credits"] > 0:
		parts.append("+%d Credits" % r["credits"])
	for id in r["essence"]:
		parts.append("+%d %s Essence" % [r["essence"][id], Catalog.display_name(id).capitalize()])
	if r["keys"] > 0:
		parts.append("+%d Key" % r["keys"])
	var text := "  ·  ".join(parts)
	if not r["level_ups"].is_empty():
		text += "\n" + "   ".join(PackedStringArray(r["level_ups"]))
	return text


# ---------------------------------------------------------------- Lab (Essence)

func can_craft(id: String) -> String:
	if int(data["essence"].get(id, 0)) < ECONOMY.essence_to_craft:
		return "Need %d Essence" % ECONOMY.essence_to_craft
	if roster_full():
		return "Roster full: expand or retire first"
	return ""


## 10 Essence of one character -> that character at Lv1. Returns the new uid or -1.
func craft(id: String) -> int:
	if can_craft(id) != "":
		return -1
	data["essence"][id] = int(data["essence"][id]) - ECONOMY.essence_to_craft
	return add_unit(id, ECONOMY.crafted_rarity)


# ---------------------------------------------------------------- Recruit

## tier 0-2 = Basic / Advanced / Elite (Credits), 3 = Key. "" if it can be done.
func can_recruit(tier: int) -> String:
	if roster_full():
		return "Roster full: expand or retire first"
	if tier == 3:
		return "" if data["keys"] > 0 else "No Keys (clear an Act to earn one)"
	return "" if data["credits"] >= ECONOMY.recruit_costs[tier] else "Not enough Credits"


## A random character (any of the 20 = random type and affinity) with a random
## rarity from the tier's odds. Duplicates allowed. Returns {} if it can't.
func recruit(tier: int) -> Dictionary:
	if can_recruit(tier) != "":
		return {}
	if tier == 3:
		data["keys"] -= 1
	else:
		data["credits"] -= ECONOMY.recruit_costs[tier]
	var rarity := roll_rarity(ECONOMY.odds_for(tier))
	var id: String = Catalog.IDS[rng.randi_range(0, Catalog.IDS.size() - 1)]
	var uid := add_unit(id, rarity)
	return {"uid": uid, "id": id, "rarity": rarity}


func roll_rarity(odds: Array[int]) -> int:
	var roll := rng.randi_range(1, 100)
	var acc := 0
	for i in odds.size():
		acc += odds[i]
		if roll <= acc:
			return i
	return 0


# ---------------------------------------------------------------- roster, cores, retire

func expand_roster() -> bool:
	if data["credits"] < ECONOMY.roster_expand_cost:
		return false
	data["credits"] -= ECONOMY.roster_expand_cost
	data["roster_cap"] += ECONOMY.roster_expand_slots
	return true


func buy_core() -> bool:
	if data["credits"] < ECONOMY.core_cost:
		return false
	data["credits"] -= ECONOMY.core_cost
	data["cores"] += 1
	return true


## Spend 1 Training Core on a unit: +core_xp XP.
func use_core(uid: int) -> bool:
	var u := unit(uid)
	if data["cores"] <= 0 or u.is_empty() or u["level"] >= PROGRESSION.max_level:
		return false
	data["cores"] -= 1
	u["cores"] = int(u["cores"]) + 1
	add_xp(u, ECONOMY.core_xp)
	return true


## "" if this unit can be retired, otherwise the reason.
func retire_check(uid: int) -> String:
	var u := unit(uid)
	if u.is_empty():
		return "Unknown character"
	if u["locked"]:
		return "Locked: unlock it first"
	if in_team(uid):
		return "In your team: swap it out first"
	var t := Catalog.template(u["id"])
	var same_element := 0
	var same_type := 0
	for o in data["units"]:
		var ot := Catalog.template(o["id"])
		if ot.element == t.element:
			same_element += 1
		if ot.role == t.role:
			same_type += 1
	if same_element <= 1:
		return "Your only %s character" % Element.display_name(t.element)
	if same_type <= 1:
		return "Your only %s" % ["BERSERKER", "TITAN", "SPECTRE", "BIOTECH"][t.role]
	return ""


func retire_value(uid: int) -> int:
	var u := unit(uid)
	return ECONOMY.retire_base_cores[u["rarity"]] + roundi(int(u["cores"]) * ECONOMY.retire_invested_share)


## Retire (remove) a unit. Returns the Training Cores gained, or -1.
func retire(uid: int) -> int:
	if retire_check(uid) != "":
		return -1
	var gained := retire_value(uid)
	data["cores"] += gained
	data["units"] = data["units"].filter(func(u: Dictionary) -> bool: return u["uid"] != uid)
	return gained


func toggle_lock(uid: int) -> void:
	var u := unit(uid)
	u["locked"] = not u["locked"]


## JSON turns every number into a float; put the ints back.
func _fix_types() -> void:
	for k in ["next_uid", "credits", "cores", "keys", "roster_cap"]:
		data[k] = int(data[k])
	for u in data["units"]:
		for k in ["uid", "level", "xp", "rarity", "cores"]:
			u[k] = int(u[k])
	var team := []
	for t in data["team"]:
		team.append(int(t))
	data["team"] = team
	for id in data["essence"]:
		data["essence"][id] = int(data["essence"][id])
	var fc := []
	for a in data["first_clears"]:
		fc.append(int(a))
	data["first_clears"] = fc
