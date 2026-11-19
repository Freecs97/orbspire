class_name Journey
extends RefCounted
## Where the player has been in the universe: what is unlocked, cleansed, and the
## lifetime counters. Wraps the save file's "cosmos" entry (story Acts keep using
## cleared_acts / act_fight, as before).
##
## Plain English - travel is OUTWARD by distance, never along a line:
##   - The main story comes first: Galaxy 1, Systems 1, 2, 3 in order (Acts 1-10).
##     Reaper-0 (Act 10) is the gate: after it, free exploration opens.
##   - A galaxy / system / world unlocks when a NEARER neighbour (the ring inside
##     it) is cleared. One is enough, and you choose which one in each ring.
##   - Anything locked can still be previewed; only PLAY waits.
##   - Inside a world the stages go in order; the Stage 5 boss cleanses it.
##   - Danger (team level vs the Recommended Level) is a WARNING, never a block.
## Counters (lifetime, saved, wiped by New Game): Worlds Cleansed, Singularities
## Defeated, Wardens Defeated, Fights Won, Highest Combo, Play Time.

const DEFAULT := {"cleansed": [], "stage_next": {}, "wardens": [], "singularities": [], "fights_won": 0,
	"highest_combo": 0, "play_time": 0.0, "warned": [], "last_world": "", "story_seen": []}

var save: Dictionary
var c: Dictionary


func _init(save_data: Dictionary) -> void:
	save = save_data
	if not save.has("cosmos") or not save["cosmos"] is Dictionary:
		save["cosmos"] = {}
	c = save["cosmos"]
	for k in DEFAULT:
		if not c.has(k):
			c[k] = DEFAULT[k].duplicate(true) if DEFAULT[k] is Array or DEFAULT[k] is Dictionary else DEFAULT[k]
	c["fights_won"] = int(c["fights_won"])
	c["highest_combo"] = int(c["highest_combo"])
	c["play_time"] = float(c["play_time"])
	for k in c["stage_next"]:
		c["stage_next"][k] = int(c["stage_next"][k])


# ---------------------------------------------------------------- story

func act_cleared(n: int) -> bool:
	return n in save.get("cleared_acts", [])


func story_done() -> bool:
	return act_cleared(Cosmos.ACTS.size())


# ---------------------------------------------------------------- galaxies

func galaxy_completed(g: int) -> bool:
	if g == 1:
		return story_done()
	for sys in Cosmos.systems(g):
		if int(sys["ring"]) == 3 and system_cleared(g, int(sys["s"])):
			return true
	return false


func galaxy_unlocked(g: int) -> bool:
	if g == 1:
		return true
	if not story_done():
		return false
	var ring := int(Cosmos.galaxy(g)["ring"])
	for other in Cosmos.galaxies_in_ring(ring - 1):
		if galaxy_completed(int(other["g"])):
			return true
	return false


func galaxy_lock_reason(g: int) -> String:
	if galaxy_unlocked(g):
		return ""
	if not story_done():
		return "Defeat Reaper-0 (Act 10) to open free exploration"
	var ring := int(Cosmos.galaxy(g)["ring"])
	return "Complete a Ring %d galaxy first (clear one of its outer systems)" % (ring - 1)


## "completed", "current", "explorable" or "locked".
func galaxy_state(g: int) -> String:
	if galaxy_completed(g):
		return "completed"
	if not galaxy_unlocked(g):
		return "locked"
	var cur := current_fight()
	if not cur.is_empty() and int(cur["key"].split("-")[0]) == g:
		return "current"
	return "explorable"


# ---------------------------------------------------------------- systems

func system_cleared(g: int, s: int) -> bool:
	if Cosmos.is_story_system(g, s):
		return act_cleared(Cosmos.STORY_LAST_ACT[s])
	var ws := Cosmos.worlds(g, s)
	return world_cleansed(ws[ws.size() - 1]["key"])


func system_unlocked(g: int, s: int) -> bool:
	if not galaxy_unlocked(g):
		return false
	if Cosmos.is_story_system(g, s):
		return s == 1 or act_cleared(Cosmos.STORY_LAST_ACT[s - 1])
	if not story_done():
		return false
	var ring := int(Cosmos.system(g, s)["ring"])
	if ring == 0:
		return true
	for sys in Cosmos.systems(g):
		if int(sys["ring"]) == ring - 1 and system_cleared(g, int(sys["s"])):
			return true
	return false


func system_lock_reason(g: int, s: int) -> String:
	if system_unlocked(g, s):
		return ""
	if not galaxy_unlocked(g):
		return galaxy_lock_reason(g)
	if Cosmos.is_story_system(g, s):
		return "Clear Act %d first (main story, in order)" % Cosmos.STORY_LAST_ACT[s - 1]
	if not story_done():
		return "Defeat Reaper-0 (Act 10) to open free exploration"
	return "Clear a nearer system in this galaxy first"


func system_state(g: int, s: int) -> String:
	if system_cleared(g, s):
		return "completed"
	if not system_unlocked(g, s):
		return "locked"
	var cur := current_fight()
	if not cur.is_empty() and String(cur["key"]).begins_with("%d-%d-" % [g, s]):
		return "current"
	return "explorable"


func worlds_cleansed_in(g: int, s: int) -> int:
	var n := 0
	for w in Cosmos.worlds(g, s):
		if world_cleansed(w["key"]):
			n += 1
	return n


# ---------------------------------------------------------------- worlds

func world_cleansed(key: String) -> bool:
	var w := Cosmos.world_by_key(key)
	if int(w["act"]) > 0:
		return act_cleared(int(w["act"]))
	return key in c["cleansed"]


func world_unlocked(key: String) -> bool:
	var w := Cosmos.world_by_key(key)
	var g: int = w["g"]
	var s: int = w["s"]
	if not system_unlocked(g, s):
		return false
	if int(w["act"]) > 0:
		return int(w["act"]) == 1 or act_cleared(int(w["act"]) - 1)
	if bool(w["side"]):
		return act_cleared(Cosmos.STORY_FIRST_ACT[s])
	if int(w["ring"]) == 0:
		return true
	for other in Cosmos.worlds(g, s):
		if int(other["ring"]) == int(w["ring"]) - 1 and world_cleansed(other["key"]):
			return true
	return false


func world_lock_reason(key: String) -> String:
	if world_unlocked(key):
		return ""
	var w := Cosmos.world_by_key(key)
	if not system_unlocked(int(w["g"]), int(w["s"])):
		return system_lock_reason(int(w["g"]), int(w["s"]))
	if int(w["act"]) > 0:
		return "Clear Act %d first" % (int(w["act"]) - 1)
	if bool(w["side"]):
		return "Clear Act %d first" % Cosmos.STORY_FIRST_ACT[int(w["s"])]
	return "Cleanse a world nearer the star first"


func world_state(key: String) -> String:
	if world_cleansed(key):
		return "completed"
	if not world_unlocked(key):
		return "locked"
	var cur := current_fight()
	if not cur.is_empty() and cur["key"] == key:
		return "current"
	return "explorable"


## Index of the next stage to play in a world (0-based). Story Acts: act_fight.
func stage_next(key: String) -> int:
	var w := Cosmos.world_by_key(key)
	if int(w["act"]) > 0:
		return int(save.get("act_fight", {}).get(str(w["act"]), 0))
	return int(c["stage_next"].get(key, 0))


## Stages go in order; after a world is cleansed every stage can be replayed.
func stage_playable(key: String, index: int) -> bool:
	if not world_unlocked(key):
		return false
	if world_cleansed(key):
		return true
	return index <= stage_next(key)


# ---------------------------------------------------------------- current fight

## The next uncleared fight: the story Act in progress, otherwise the last world
## you played (if not cleansed), otherwise the unlocked world with the lowest
## Recommended Level. {} if there is nothing left.
func current_fight() -> Dictionary:
	if not story_done():
		for n in range(1, Cosmos.ACTS.size() + 1):
			if not act_cleared(n):
				return {"key": Cosmos.act_world_key(n), "index": int(save.get("act_fight", {}).get(str(n), 0))}
	var last: String = c["last_world"]
	if last != "" and world_unlocked(last) and not world_cleansed(last):
		return {"key": last, "index": stage_next(last)}
	var best := {}
	var best_rec := 1 << 30
	for gal in Cosmos.galaxies():
		var g: int = gal["g"]
		if not galaxy_unlocked(g):
			continue
		for sys in Cosmos.systems(g):
			if not system_unlocked(g, int(sys["s"])) or system_cleared(g, int(sys["s"])):
				continue
			for w in Cosmos.worlds(g, int(sys["s"])):
				if int(w["rec"]) < best_rec and world_unlocked(w["key"]) and not world_cleansed(w["key"]):
					best_rec = int(w["rec"])
					best = {"key": w["key"], "index": stage_next(w["key"])}
	return best


# ---------------------------------------------------------------- recording

## A won fight in a story Act (index 0-based).
func story_fight_won(act: ActData, index: int) -> void:
	c["fights_won"] = int(c["fights_won"]) + 1
	if index < act.fights.size() - 1 and act.fights[index].enemies[0].is_boss:
		_add(c["wardens"], "act%d:%d" % [act.act_number, index])


## A won stage in a generated world.
func world_fight_won(act: ActData, index: int) -> void:
	c["fights_won"] = int(c["fights_won"]) + 1
	var key := act.world_key
	if not world_cleansed(key):
		c["stage_next"][key] = maxi(int(c["stage_next"].get(key, 0)), index + 1)
	if index == 3 or (index == 4 and not act.is_gate):
		_add(c["wardens"], "%s:%d" % [key, index])


## Stage 5 boss down: the world is cleansed (and the system's singularity, if gate).
func world_cleansed_now(act: ActData) -> void:
	_add(c["cleansed"], act.world_key)
	c["stage_next"].erase(act.world_key)
	if act.is_gate:
		_add(c["singularities"], act.world_key)


func note_combo(combos: int) -> void:
	c["highest_combo"] = maxi(int(c["highest_combo"]), combos)


func add_play_time(seconds: float) -> void:
	c["play_time"] = float(c["play_time"]) + seconds


func _add(list: Array, item: String) -> void:
	if not item in list:
		list.append(item)


# ---------------------------------------------------------------- counters

func worlds_cleansed() -> int:
	return save.get("cleared_acts", []).size() + c["cleansed"].size()


func singularities_defeated() -> int:
	return save.get("cleared_acts", []).size() + c["singularities"].size()


func wardens_defeated() -> int:
	return c["wardens"].size()


## "Worlds 12/700  •  Singularities 4/107"
func counters_text() -> String:
	return "Worlds %d/%d  •  Singularities %d/%d" % [worlds_cleansed(), Cosmos.total_worlds(), singularities_defeated(), Cosmos.total_singularities()]


static func play_time_text(seconds: float) -> String:
	var s := int(seconds)
	return "%dh %02dm" % [s / 3600, (s / 60) % 60]


# ---------------------------------------------------------------- danger

## Team level vs Recommended Level: "green" (at / above), "yellow" (1-4 below),
## "red" (5-9 below), "skull" (10+ below). Never blocks PLAY.
static func danger(team_level: int, rec: int) -> String:
	var gap := rec - team_level
	if gap <= 0:
		return "green"
	if gap <= 4:
		return "yellow"
	if gap <= 9:
		return "red"
	return "skull"


static func danger_color(d: String) -> Color:
	return {"green": Color("4fd36b"), "yellow": Color("ffd23f"), "red": Color("ff5a4a"), "skull": Color("c03dff")}.get(d, Color.WHITE)


static func danger_name(d: String) -> String:
	return {"green": "SAFE", "yellow": "RISKY", "red": "DANGEROUS", "skull": "LETHAL"}.get(d, "")


## Yellow warns once per world; Red and Skull warn every time.
func needs_warning(key: String, d: String) -> bool:
	if d == "green":
		return false
	if d == "yellow":
		return not key in c["warned"]
	return true


func mark_warned(key: String) -> void:
	_add(c["warned"], key)


# ---------------------------------------------------------------- post-game story (Part B)

## Story beats shown once: "final_arc", "ring1".."ring3", "galaxy2".."galaxy10",
## "cleanse_popup", "final_outro".
func story_seen(key: String) -> bool:
	return key in c["story_seen"]


func mark_story_seen(key: String) -> void:
	_add(c["story_seen"], key)


## Everything cleansed and every singularity down (the final outro).
func universe_cleansed() -> bool:
	return worlds_cleansed() >= Cosmos.total_worlds() and singularities_defeated() >= Cosmos.total_singularities()
