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
## The 3 starters (New Game: pick ONE). Same type (Berserker), same stats and
## skills; only the element differs: Kaela = Fire, Iris = Water, Drek = Wood.
const STARTERS := ["berserker_01_angel_fire", "berserker_03_thin_water", "berserker_02_hulk_wood"]
const TEAM_SLOTS := 4
## The ultra-rare friend roll after every win. Always on in the game; older tests
## switch it off so a 1-in-400 friend can't join their teams at random.
static var friend_drops := true
const DEFAULTS := {"units": [], "next_uid": 1, "team": [], "credits": 0, "cores": 0, "keys": 0,
	"essence": {}, "roster_cap": 30, "first_clears": [], "starter": "", "fight_clears": []}

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


## A brand-new save owns NO characters: the player picks one starter first.
func needs_starter() -> bool:
	return data["units"].is_empty()


## New Game: the ONE starter (Forged, Lv1) becomes the whole team. Everyone else
## is earned (fight drops, Recruit, Lab). Saved; only a New Game changes it.
## Returns the new uid, or -1 if a starter was already chosen / unknown id.
func choose_starter(id: String) -> int:
	if not needs_starter() or not id in STARTERS:
		return -1
	data["starter"] = id
	var uid := add_unit(id, ECONOMY.story_rarity)
	data["team"] = [uid]
	return uid


## A new character fills the first empty team slot (4 slots; Act 1 fights with
## the first 3). Returns true if it went into the team.
func auto_slot(uid: int) -> bool:
	var t: Array = data["team"]
	var i := t.find(-1)
	if i >= 0:
		t[i] = uid
		return true
	if t.size() < TEAM_SLOTS:
		t.append(uid)
		return true
	return false


# ---------------------------------------------------------------- units

func add_unit(id: String, rarity: int, level := 1) -> int:
	var uid: int = data["next_uid"]
	data["next_uid"] = uid + 1
	data["units"].append({"uid": uid, "id": id, "level": mini(level, PROGRESSION.level_cap(1)), "xp": 0, "rarity": rarity, "locked": false, "cores": 0, "stage": 1})
	return uid


## Highest level this unit can reach at its evolution stage (Stage 1 = Lv15).
func level_cap(u: Dictionary) -> int:
	return PROGRESSION.level_cap(int(u.get("stage", 1)))


## The highest Act you have unlocked (1 + Acts cleared). Sets the Recruit odds band.
func progress_act() -> int:
	var best := 0
	for a in data["first_clears"]:
		best = maxi(best, int(a))
	return clampi(best + 1, 1, 10)


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


## The unit as a fighter: its character's data with stats for its level, rarity
## and evolution stage. Passive 1 unlocks at Lv10, Passive 2 with Evolution 1,
## Passive 3 with Evolution 2. Each evolution: +10% stats, cooldown -1, new art.
func fighter(uid: int) -> FighterData:
	var u := unit(uid)
	var base := Catalog.template(u["id"])
	var f: FighterData = base.duplicate()
	var stage := int(u.get("stage", 1))
	var m: float = PROGRESSION.stat_mult(u["level"]) * ECONOMY.rarity_stat_mult[u["rarity"]] * (1.0 + ECONOMY.evo_stat_bonus * (stage - 1))
	f.max_hp = roundi(base.max_hp * m)
	f.atk = roundi(base.atk * m)
	f.rcv = roundi(base.rcv * m)
	f.stage = stage
	f.rarity = int(u["rarity"])
	f.cooldown_cut = stage - 1
	f.passives_unlocked = mini((1 if u["level"] >= ECONOMY.passive_1_level else 0) + stage - 1, base.passives.size())
	f.art = Catalog.art(u["id"], stage)
	return f


# ---------------------------------------------------------------- evolution

## "" if this unit can evolve right now, otherwise why not.
func can_evolve(uid: int) -> String:
	var u := unit(uid)
	if u.is_empty():
		return "Unknown character"
	var stage := int(u.get("stage", 1))
	if stage >= 3:
		return "Fully evolved (Stage 3/3)"
	var need_lv := PROGRESSION.level_cap(stage)
	if u["level"] < need_lv:
		return "Needs Lv%d to evolve" % need_lv
	if data["credits"] < ECONOMY.evo_credits[stage - 1]:
		return "Needs %d Credits" % ECONOMY.evo_credits[stage - 1]
	if data["cores"] < ECONOMY.evo_cores[stage - 1]:
		return "Needs %d Training Cores" % ECONOMY.evo_cores[stage - 1]
	return ""


## Evolve: Stage +1, pays Credits + Cores. Level and XP are kept. Returns success.
func evolve(uid: int) -> bool:
	if can_evolve(uid) != "":
		return false
	var u := unit(uid)
	var stage := int(u["stage"])
	data["credits"] -= ECONOMY.evo_credits[stage - 1]
	data["cores"] -= ECONOMY.evo_cores[stage - 1]
	u["stage"] = stage + 1
	return true


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

## XP multiplier for a fight at `fight_level` for this team: low-level fights
## (compared with the team's strongest member) give less, 15+ below gives none.
func xp_falloff_for(uids: Array, fight_level: int) -> float:
	var team_top := 1
	for uid in uids:
		team_top = maxi(team_top, int(unit(uid).get("level", 1)))
	return ECONOMY.xp_falloff(team_top - fight_level)


## Give XP to these units (catch-up bonus for ones far below your highest;
## less XP from fights far below the team). Returns lines like "MIRA SOLACE Lv10! Passive unlocked".
func grant_xp(uids: Array, amount: int, fight_level := 0) -> Array[String]:
	var lines: Array[String] = []
	var top := highest_level()
	var falloff := xp_falloff_for(uids, fight_level) if fight_level > 0 else 1.0
	for uid in uids:
		var u := unit(uid)
		var gap := top - int(u["level"])
		var mult := falloff
		if gap >= ECONOMY.catch_up_big_gap:
			mult *= ECONOMY.catch_up_big_mult
		elif gap >= ECONOMY.catch_up_small_gap:
			mult *= ECONOMY.catch_up_small_mult
		var before: int = u["level"]
		add_xp(u, roundi(amount * mult))
		if u["level"] > before:
			var line := "%s Lv%d!" % [Catalog.display_name(u["id"]), u["level"]]
			if before < ECONOMY.passive_1_level and u["level"] >= ECONOMY.passive_1_level:
				line += " Passive unlocked"
			if u["level"] >= level_cap(u):
				line += " (Lv%d cap: evolve to go higher)" % level_cap(u)
			lines.append(line)
	return lines


## Add XP and level up, never past the cap for the unit's evolution stage.
func add_xp(u: Dictionary, amount: int) -> void:
	var cap := level_cap(u)
	u["xp"] = int(u["xp"]) + amount
	while u["level"] < cap and u["xp"] >= PROGRESSION.xp_to_next(u["level"]):
		u["xp"] -= PROGRESSION.xp_to_next(u["level"])
		u["level"] = int(u["level"]) + 1
	if u["level"] >= cap:
		u["level"] = cap
		u["xp"] = 0


# ---------------------------------------------------------------- fight rewards

## Called after every fight. Returns what was earned, for the result screen.
## WIN: XP to the team, Credits, Essence drops; first Act clear: bonus + Keys.
## LOSE: a share of the Credits only.
## fight_no (1-8) turns on Scrap character drops; 0 = no drop (tests, sims).
func fight_rewards(fight: FightData, act_number: int, won: bool, team: Array, is_act_clear: bool, fight_no := 0) -> Dictionary:
	var e := ECONOMY
	var credits := e.win_credits_base + e.win_credits_per_act * act_number
	var top := fight.enemies[0]
	if top.is_boss and top.art and top.art.resource_path.contains("/bosses/"):
		credits *= e.boss_credit_mult
	elif top.is_boss:
		credits *= e.mini_boss_credit_mult
	var r := {"credits": 0, "xp": 0, "essence": {}, "keys": 0, "level_ups": [], "new_unit": {}}
	if not won:
		r["credits"] = roundi(credits * e.lose_credit_share)
		data["credits"] += r["credits"]
		return r
	r["credits"] = credits
	r["xp"] = fight.xp
	r["xp"] = roundi(fight.xp * xp_falloff_for(team, fight.expected_level))
	r["level_ups"] = grant_xp(team, fight.xp, fight.expected_level)
	# Essence: each enemy drops for a human character, or (the 10 playable
	# enemies, 50/50) for ITSELF. Regular enemies: 30% chance of 2.
	for d in fight.enemies:
		var n := 0
		if d.is_boss and d.art and d.art.resource_path.contains("/bosses/"):
			n = e.essence_boss
		elif d.is_boss:
			n = rng.randi_range(e.essence_mini_min, e.essence_mini_max)
		elif rng.randf() < e.essence_regular_chance:
			n = e.essence_regular_amount
		if n > 0:
			var id := Catalog.essence_for(d, act_number)
			var own := Catalog.own_essence_id(d)
			if own != "" and rng.randf() < e.essence_own_share:
				id = own
			r["essence"][id] = int(r["essence"].get(id, 0)) + n
			data["essence"][id] = int(data["essence"].get(id, 0)) + n
	if is_act_clear and not act_number in data["first_clears"]:
		data["first_clears"].append(act_number)
		r["credits"] += e.act_clear_bonus_per_act * act_number
		r["keys"] = e.keys_per_act_clear
		data["keys"] += r["keys"]
	data["credits"] += r["credits"]
	if fight_no > 0:
		r["new_unit"] = _scrap_drop(fight, act_number, fight_no)
		r["friend"] = friend_drop() if friend_drops else {}
	return r


## Ultra-rare: after a won fight, one of Bailey's friends may join (Prime, Lv1).
## Prefers a friend you don't own yet; joins even past the roster cap (it would
## be cruel to lose a 1-in-400 drop to a full roster). Returns {} if nothing dropped.
## `roll` < 0 = roll the dice; tests pass a fixed roll.
func friend_drop(roll := -1.0) -> Dictionary:
	if (rng.randf() if roll < 0.0 else roll) >= ECONOMY.friend_drop_chance:
		return {}
	var owned := {}
	for u in data["units"]:
		owned[u["id"]] = true
	var pool: Array = Catalog.FRIEND_IDS.filter(func(id: String) -> bool: return not owned.has(id))
	if pool.is_empty():
		pool = Catalog.FRIEND_IDS.duplicate()
	var id: String = pool[rng.randi_range(0, pool.size() - 1)]
	var uid := add_unit(id, Catalog.template(id).fixed_rarity)
	return {"uid": uid, "id": id, "in_team": auto_slot(uid)}


## Scrap characters found after a WIN (the easy way to fill a team early):
##   - Act 1, first clear of fights 1 and 2: always one. Fight 1's is a character
##     strong against the Act boss's element (Water vs Emberfang-9), so every
##     starter gets the same help; fight 2's is any character. Prefers ones you
##     don't own yet.
##   - Any later win of a regular fight in Acts 1-2: a small chance.
## The new character joins the first empty team slot. Returns {} if nothing dropped.
func _scrap_drop(fight: FightData, act_number: int, fight_no: int) -> Dictionary:
	var e := ECONOMY
	var key := "%d-%d" % [act_number, fight_no]
	var first: bool = not key in data["fight_clears"]
	if first:
		data["fight_clears"].append(key)
	var guaranteed := first and act_number == 1 and fight_no <= e.scrap_guaranteed_fights
	var lucky := not guaranteed and not fight.enemies[0].is_boss and act_number <= e.scrap_drop_max_act and rng.randf() < e.scrap_drop_chance
	if not (guaranteed or lucky):
		return {}
	if roster_full():
		return {"id": "", "roster_full": true}
	var pool: Array = Catalog.pool_for_rarity(0)   # humans + Scrap enemy colour versions
	if guaranteed and fight_no == 1:
		var acts := StarMap.ACTS
		var boss: FighterData = acts[act_number - 1].fights[-1].enemies[0]
		var counter := Element.beaten_by(boss.element)
		pool = pool.filter(func(id: String) -> bool: return Catalog.template(id).element == counter)
	if guaranteed:
		var owned := {}
		for u in data["units"]:
			owned[u["id"]] = true
		var fresh := pool.filter(func(id: String) -> bool: return not owned.has(id))
		if not fresh.is_empty():
			pool = fresh
	var id: String = pool[rng.randi_range(0, pool.size() - 1)]
	var uid := add_unit(id, 0)
	return {"uid": uid, "id": id, "in_team": auto_slot(uid)}


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
	var nu: Dictionary = r.get("new_unit", {})
	if nu.get("roster_full", false):
		text += "\nA Scrap hunter wanted to join, but your roster is full"
	elif nu.has("id"):
		text += "\nNEW HUNTER: %s (Scrap) %s" % [Catalog.display_name(nu["id"]), "joined your team!" if nu["in_team"] else "joined your roster"]
	var fr: Dictionary = r.get("friend", {})
	if fr.has("id"):
		text += "\nULTRA RARE! %s (%s) %s" % [Catalog.display_name(fr["id"]), Catalog.rarity_name(Catalog.template(fr["id"]).fixed_rarity), "joined your team!" if fr["in_team"] else "joined your roster"]
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
	# Enemy characters always come at their own rarity (Scrap / Alloy / Forged).
	var fixed := Catalog.template(id).fixed_rarity
	var uid := add_unit(id, fixed if fixed >= 0 else ECONOMY.crafted_rarity(progress_act()))
	auto_slot(uid)
	return uid


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
	var rarity := roll_rarity(ECONOMY.odds_for(tier, progress_act()))
	# Rarity first, then a character allowed at that rarity (humans + enemy colour
	# versions with exactly that fixed rarity), so the shown odds stay exact.
	var pool := Catalog.pool_for_rarity(rarity)
	var id: String = pool[rng.randi_range(0, pool.size() - 1)]
	var uid := add_unit(id, rarity)
	return {"uid": uid, "id": id, "rarity": rarity, "in_team": auto_slot(uid)}


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
	if data["cores"] <= 0 or u.is_empty() or u["level"] >= level_cap(u):
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
		if not u.has("stage"):
			u["stage"] = 1
		for k in ["uid", "level", "xp", "rarity", "cores", "stage"]:
			u[k] = int(u[k])
		u["level"] = mini(int(u["level"]), level_cap(u))   # old saves: clamp to the new cap
	var team := []
	for t in data["team"]:
		team.append(int(t))
	data["team"] = team
	for id in data["essence"]:
		data["essence"][id] = int(data["essence"][id])
	if data["starter"] == "" and not data["units"].is_empty():
		data["starter"] = data["units"][0]["id"]   # saves from before the starter choice
	var fc := []
	for a in data["first_clears"]:
		fc.append(int(a))
	data["first_clears"] = fc
