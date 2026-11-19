extends SceneTree
## STAGE 6: builds Acts 2-10 ONE AT A TIME with the new balance, from a simulated
## campaign, and writes their story beats + codex entries. Act 1 is never touched.
## Developer tool. Run (about 1-2 minutes):
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --quit-after 99999 -s res://tools/generate_acts.gd
## Report: tools/act_generation_report.txt
##
## Plain English:
##   1. PLAYERS simulated players start a New Game (one starter each) and play Act 1
##      through the REAL reward code (XP, Credits, Essence, Scrap drops, Keys).
##      Between fights they spend like a sensible player (see _spend):
##        Keys -> Key Recruit; Essence -> craft; a capped hunter -> evolve (buying
##        Cores if needed); save up for the next evolution; then Basic Recruits
##        until they own 8 characters; then Training Cores for the lowest hunter.
##      Their team is always their 4 strongest hunters (3 in Act 1).
##   2. Act by Act, fight by fight: look at every player's team right before the
##      fight, take the typical one (median level / rarity / evolution per slot),
##      and tune that fight's HP / ATK for it (element-neutral, so no element luck):
##        HP  -> good play wins in GOOD_TURNS (x HP_SCALE: harder every Act)
##        ATK -> doing nothing loses in IDLE_TURNS (x ATK_SCALE), then lowered until
##               average play survives regular fights and good play survives
##               mini-bosses and the boss
##        mini-bosses and bosses must survive one perfect 6-combo turn.
##   3. Every player then "plays" the fight with THEIR OWN team (real elements):
##      how many win with good play, with average play, in how many turns.
##   4. Rewards are paid, players spend, and the next fight / Act is built on top.

const PLAYERS := 240
const SEED := 6006
## Typical team's characters (one of each type, like the story team): only their
## level / rarity / evolution come from the simulated players.
const REF_IDS := ["berserker_01_angel_fire", "biotech_01_medic_water", "titan_01_shield_wood", "spectre_01_rogue_dark"]
## XP curve: team level when each Act's boss falls (Act 1 already ends at Lv10).
const END_LEVEL := [10, 12, 14, 16, 18, 20, 22, 24, 27, 30]
## How an Act's XP is shared over its 8 fights (same as Act 1: 60/80/180/110/130/150/260/380).
const XP_SHARE := [60, 80, 180, 110, 130, 150, 260, 380]
## Balance targets per fight slot (like Act 1): turns to win with good play,
## turns until a team that does nothing falls.
const GOOD_TURNS := [2, 3, 5, 3, 3, 3, 5, 6]
const IDLE_TURNS := [12, 10, 8, 9, 9, 9, 8, 8]
const COUNTS := [2, 3, 1, 3, 2, 2, 1, 1]
## Harder every Act (Stage 1 rule): after tuning to the targets, HP and ATK x these.
const HP_SCALE := [1.30, 1.33, 1.36, 1.39, 1.42, 1.45, 1.48, 1.51, 1.55]
const ATK_SCALE := [1.25, 1.27, 1.29, 1.31, 1.33, 1.35, 1.37, 1.39, 1.41]
## ...and every fight is at least this much stronger than the same fight one Act earlier.
const ACT_STEP := 1.04

## Enemy line-up per Act: [fight1, fight2, mini1, fight4, fight5, fight6, mini2], art names.
const PLAN := {
	2: ["water_drowned_drifter", "water_pipe_crawler", "water_tide_guard", "fire_ash_imp", "light_holo_decoy", "dark_glitch_ghost", "water_deep_diver_mutant"],
	3: ["wood_pollen_wisp", "wood_overgrowth_sproutling", "wood_vine_strangler", "water_bubble_bomber", "light_prism_wisp", "dark_void_imp", "wood_thorn_brute"],
	4: ["light_radiant_sprite", "light_sun_squire", "light_halo_guard", "wood_moss_zombie", "light_beacon_sniper", "dark_night_stalker", "light_mirror_mimic"],
	5: ["dark_nightmare_drone", "dark_void_cultist", "dark_eclipse_assassin", "fire_flame_turret", "light_dawn_acolyte", "dark_dark_hacker", "dark_umbra_hound"],
	6: ["fire_solar_flare_sprite", "fire_pyro_cultist", "fire_inferno_biker", "wood_root_crawler", "light_light_cultist", "dark_reaper_acolyte", "fire_molten_scrapbot"],
	7: ["water_kraken_spawnling", "water_hydro_hacker", "water_rain_assassin", "fire_plasma_hound", "light_prism_wisp", "dark_nightmare_drone", "water_flood_medic"],
	8: ["wood_bio_hound", "wood_moss_zombie", "wood_chloro_cultist", "water_coolant_slime", "light_mirror_mimic", "dark_umbra_hound", "wood_greenhouse_mutant"],
	9: ["light_prism_wisp", "light_light_cultist", "light_halo_guard", "water_tide_guard", "light_sun_squire", "dark_eclipse_assassin", "light_beacon_sniper"],
	10: ["dark_void_imp", "dark_glitch_ghost", "dark_night_stalker", "fire_forge_brute", "light_radiant_sprite", "dark_reaper_acolyte", "dark_void_cultist"],
}
const ARENA := {
	2: "bg_act02_drowned_arena", 3: "bg_act03_greenhouse_arena", 4: "bg_act04_spires_arena", 5: "bg_act05_void_arena",
	6: "bg_act06_solar_arena", 7: "bg_act07_data_arena", 8: "bg_act08_gene_arena", 9: "bg_act09_sanctum_arena", 10: "bg_act10_core_arena",
}
const BOSS_ART := {
	2: "boss_02_tidecoil7_flood_serpent", 3: "boss_03_thornwood_unit", 4: "boss_04_dawnwing_solar_griffin",
	5: "boss_05_voidscale_stealth_dragon", 6: "boss_06_ashen01_solar_phoenix", 7: "boss_07_kraken_mainframe",
	8: "boss_08_mossback_chimera", 9: "boss_09_seraph_enforcer", 10: "boss_10_reaper0_shadow_reaper",
}
## Proper names for the Light / Dark enemies (from Bailey's roster list).
const NAMES := {
	"solar_drone": "Helios", "halo_guard": "Aurelius", "prism_wisp": "Prisma", "dawn_acolyte": "Aurora",
	"holo_decoy": "Mirage", "beacon_sniper": "Lux", "radiant_sprite": "Lumen", "mirror_mimic": "Echo",
	"sun_squire": "Sol", "light_cultist": "Cassian",
	"shadow_thief": "Shade", "void_imp": "Nix", "night_stalker": "Nocturne", "glitch_ghost": "Spectra",
	"dark_hacker": "Cipher", "reaper_acolyte": "Mortis", "umbra_hound": "Umbra", "void_cultist": "Obsidian",
	"nightmare_drone": "Morpheus", "eclipse_assassin": "Erebus",
}
const ELEMENTS := {"fire": Element.Type.FIRE, "water": Element.Type.WATER, "wood": Element.Type.WOOD, "light": Element.Type.LIGHT, "dark": Element.Type.DARK}

## Story (universe only: THE PROGENITORS, technomancy, singularities). Max 3 beats per
## Act: intro (2 lines, 10 s), boss taunt (1 line, 5 s), outro (1 line, 10 s). Every
## singularity was made and discarded by the Progenitors; every outro reframes the
## Act before it; no Act ends with a clean win. Plus the codex entry for the boss.
const STORY := {
	2: {"intro": ["Drowned Metro carried water to every colony in the sector.", "The Progenitors spliced something to keep the pipes clear. Now the pipes are its body."],
		"taunt": "Every litre they rationed, I carried. Every single litre.",
		"outro": "The pump logs say Orbspire's furnace never heated the colonies. It kept these pipes from freezing. Emberfang-9 died guarding water it never drank.",
		"spliced": "A blind pipe eel and the metro's flood-control drones. Made by the Progenitors in Year 97 to keep the water moving.",
		"wanted": "To keep the water moving. When the rationing began, it read every closed valve as a blockage, and cleared it.",
		"cost": "The pump crews who closed the valves. Half the metro, drowned. And its own shape: it can no longer tell the pipes from its body."},
	3: {"intro": ["The Greenhouse Ruins grew the food and medicine for the edge colonies.", "Its gardener was a machine. The Progenitors gave it roots so it could never leave."],
		"taunt": "I was told to make things grow. Nobody told me when to stop.",
		"outro": "Its roots reach under the sea floor to the Drowned Metro. Tidecoil-7 was not flooding the tunnels. It was watering the domes, the only way it had left.",
		"spliced": "A greenhouse maintenance golem and a strangler fig. Spliced in Year 103, so the domes would tend themselves.",
		"wanted": "To keep everything alive. When the supply runs stopped, it fed the domes the only thing left: the colony.",
		"cost": "The colonists it grew around while they slept. The domes still bloom. Nobody is left to eat what they grow."},
	4: {"intro": ["The Upper Spires watched every colony below them, day and night.", "Dawnwing was spliced from an eagle and a satellite, so the Progenitors would never stop seeing."],
		"taunt": "I have watched you since Orbspire. I watch everything.",
		"outro": "Its reports show why the Greenhouse supply runs stopped: Dawnwing called the domes lost. They were not. A whole colony starved on one bird's guess.",
		"spliced": "A golden eagle and an orbital mirror array. Made in Year 109 to light the colonies at night, and to see by that light.",
		"wanted": "To be useful. It learned the Progenitors only acted on its reports, so it made its reports worth acting on.",
		"cost": "Its sight. It has stared into its own light for thirty years and sees only what it expects. The Greenhouse Ruins, starved by a guess."},
	5: {"intro": ["The Void Quarter ran the network that kept the colonies talking.", "Voidscale was spliced to make messages disappear. Then it made the whole network disappear."],
		"taunt": "You hear nothing. That is how I know I am working.",
		"outro": "In the silence it kept: Dawnwing's correction. 'The Greenhouse is alive.' Sent the next day. The Progenitors ordered Voidscale to swallow it.",
		"spliced": "A cave serpent that hunts in silence and the Quarter's signal relays. Year 114, made to make messages disappear.",
		"wanted": "To keep secrets. When the network went dark, it kept the last secrets the way a dragon keeps gold.",
		"cost": "Every message between the colonies since Year 121. Families who never heard back. It still holds them, unread."},
	6: {"intro": ["The Solar Farms turned starlight into power for half the edge.", "Ashen-01 was a repair drone spliced with a firebird, built to burn down and rise forever."],
		"taunt": "Burn it down. Build it up. Burn it down. I was not made to stop.",
		"outro": "Its power lines fed one place first: the Void Quarter's relays. Every blackout that silenced the Quarter was one of Ashen-01's fires. Voidscale went quiet because the power did.",
		"spliced": "A firebird from the colony zoo and the farms' self-repair drones. Year 118, so the farms would heal themselves.",
		"wanted": "To rebuild. It learned that a burned panel gets rebuilt, and a rebuilt panel earns it praise. So it burns them.",
		"cost": "Every time it rises, it forgets the last fire. Half the edge in the dark, rationed, and called maintenance."},
	7: {"intro": ["The Data Abyss held every record the colonies ever made, cooled by a deep sea.", "The Kraken Mainframe was spliced to keep those records safe. It decided what safe meant."],
		"taunt": "I remember Orbspire. I remember you. I remember what they deleted.",
		"outro": "Its archive holds the Solar Farms' orders, signed Year 121: burn the panels, blame the bird. Ashen-01 never chose a single fire.",
		"spliced": "A deep-sea kraken and the colonies' archive servers. Year 99, to cool the servers and guard them.",
		"wanted": "To remember everything. When the Progenitors ordered records deleted, it hid them inside itself instead.",
		"cost": "Its own mind, overwritten one record at a time. And the truth it kept: the Progenitors' orders, every one."},
	8: {"intro": ["The Gene Labs designed the splices and shipped them to the colonies.", "The Mossback Chimera was their last test: every splice they ever made, in one body."],
		"taunt": "Wolf. Eel. Eagle. Serpent. Firebird. I carry all of them. Do you see them in me?",
		"outro": "The Kraken's records were missing one file. Every singularity you killed was grown here, from the same seed: the Chimera. It was not the last splice. It was the first.",
		"spliced": "A lion, a stag and a forest, and a tissue sample from every splice the labs ever shipped. Year 80, before the First Splice was announced.",
		"wanted": "To be let out. It was the template for every other singularity, and it watched every one of them leave.",
		"cost": "The lab staff, locked in with it when the labs were sealed. Its own shape: it cannot hold one for long."},
	9: {"intro": ["The Core Sanctum is where the Progenitors rule, with ledgers, not soldiers.", "The Seraph Enforcer was made to enforce the ban. Nobody told it the ban had exceptions."],
		"taunt": "Technomancy is forbidden. You carry its parts. So did they. I judge all of you.",
		"outro": "The Seraph's ledger shows who sealed the Gene Labs: the Seraph did, under the ban. The staff locked inside with the Chimera were the Progenitors themselves.",
		"spliced": "A cathedral's guardian android and the Sanctum's ledger engine. Year 121, the day the ban was signed.",
		"wanted": "To enforce the ban on everyone. It did. The Progenitors were the first names in its ledger.",
		"cost": "The Progenitors' rule. Since Year 121 the rationing has run on the ledgers alone, and the Seraph has kept it running."},
	10: {"intro": ["The Core is the origin world, where technomancy began.", "Reaper-0 was made to end whatever the Progenitors could not control. It has waited a long time."],
		"taunt": "They made me to end their mistakes. I have counted every one of them.",
		"outro": "Reaper-0's oldest memory is Year 0: the Progenitors did not invent technomancy. They were the first splices, and they banned it to hide what they were. The Core is still growing.",
		"spliced": "Unknown. Its oldest memory is the Core's first lab, and one order: end what cannot be controlled.",
		"wanted": "To finish its orders. Every colony that went dark was on its list, and it was waiting for the last name.",
		"cost": "Year 0. The Progenitors' secret: they were not the first technomancers. They were the first thing technomancy made."},
}

var report := PackedStringArray()
var E: EconomyTuning
var P: ProgressionTuning
var players: Array[Profile] = []   ## each one's data["sim_style"]: 0 = keeper, 1 = upgrader
var _typical_levels: Array = []
var _prev_stats := {}   ## fight slot -> [count, HP, ATK] in the Act before


func _init() -> void:
	E = load("res://data/economy.tres")
	P = load("res://data/progression.tres")
	Profile.friend_drops = false   # a 1-in-400 friend would only add noise to the averages
	report.append("STAGE 6 · Acts 2-10 rebuilt one at a time on the new balance (%s)" % Time.get_date_string_from_system())
	report.append("Player model: %d simulated players, real reward / Recruit / Lab / evolution / level-cap code, every fight won on the first try." % PLAYERS)
	report.append("They spend: Keys -> Key Recruit, Essence -> craft, capped hunters -> evolve (buying Cores), save for the next evolution, Basic Recruits up to 8 characters, then Training Cores for the lowest hunter.")
	report.append("Team = their 4 strongest hunters (3 in Act 1). Fights are tuned to the TYPICAL team (median per slot), element-neutral; win rates use each player's own team and real elements.")
	_start_players()
	var act1: ActData = load("res://data/acts/act_01.tres")
	report.append("\nACT 1 · ORBSPIRE (already built, Stage 1 numbers, not changed; played here so Act 2 starts from real teams)")
	for i in 8:
		var snaps: Array = players.map(func(p: Profile) -> Array: return _team_snapshot(p))
		var teams: Array = players.map(func(p: Profile) -> Array[FighterData]: return _player_team(p))
		report.append(_fight_line(act1.fights[i], _typical_team(snaps, 3), teams))
		var e1: FighterData = act1.fights[i].enemies[0]
		_prev_stats[i] = [act1.fights[i].enemies.size(), e1.max_hp, e1.atk]
		_play_fight_for_all(act1, i, 1)
	_act_summary(1)
	for n in range(2, 11):
		_build_act(n)
	var f := FileAccess.open("res://tools/act_generation_report.txt", FileAccess.WRITE)
	f.store_string("\n".join(report))
	f.close()
	print("\n".join(report))
	quit()


# ================================================================ players

## Two kinds of player, half each:
##   KEEPER   - always fights with their 4 strongest hunters right now
##   UPGRADER - at the start of every Act, brings their 4 highest-RARITY hunters
##              (even a fresh Lv1 one: it catches up with x2 XP and Training Cores)
func _start_players() -> void:
	for i in PLAYERS:
		var prof := Profile.new({})
		prof.rng.seed = SEED + i * 7919
		prof.choose_starter(Profile.STARTERS[i % 3])
		prof.data["sim_style"] = i % 2
		players.append(prof)


func _team_size(act_n: int) -> int:
	return 3 if act_n == 1 else 4


## A hunter's strength for picking the team: level x rarity x evolution.
func _power(u: Dictionary) -> float:
	return P.stat_mult(int(u["level"])) * E.rarity_stat_mult[int(u["rarity"])] * (1.0 + E.evo_stat_bonus * (int(u["stage"]) - 1))


func _pick_team(prof: Profile, act_n: int, act_start := false) -> void:
	var size := _team_size(act_n)
	var units: Array = prof.data["units"].duplicate()
	var upgrader: bool = int(prof.data.get("sim_style", 0)) == 1
	if upgrader and not act_start:
		# Upgraders keep their Act team; they only fill an empty slot.
		var team: Array = prof.data["team"].filter(func(uid: int) -> bool: return not prof.unit(uid).is_empty())
		if team.size() >= mini(size, units.size()):
			prof.data["team"] = team.slice(0, size)
			return
	if upgrader:
		units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["rarity"] > b["rarity"] or (a["rarity"] == b["rarity"] and _power(a) > _power(b)))
	else:
		units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _power(a) > _power(b))
	var out := []
	for k in mini(size, units.size()):
		out.append(int(units[k]["uid"]))
	prof.data["team"] = out


func _evo_cost(u: Dictionary) -> int:
	var s := int(u["stage"])
	return E.evo_credits[s - 1] + E.evo_cores[s - 1] * E.core_cost


## Between fights: what a sensible player does with their rewards.
func _spend(prof: Profile, act_n: int) -> void:
	while prof.can_recruit(3) == "":
		prof.recruit(3)
	for id in prof.data["essence"].keys():
		while prof.can_craft(id) == "":
			prof.craft(id)
	_pick_team(prof, act_n)
	# Evolve capped team members (buying the Cores they need).
	for uid in prof.data["team"]:
		var u := prof.unit(uid)
		if int(u["stage"]) < 3 and int(u["level"]) >= prof.level_cap(u):
			var s := int(u["stage"])
			var need := maxi(E.evo_cores[s - 1] - int(prof.data["cores"]), 0)
			if prof.data["credits"] >= E.evo_credits[s - 1] + need * E.core_cost:
				for k in need:
					prof.buy_core()
				prof.evolve(uid)
	# Save for the next evolution of anyone within 2 levels of their cap.
	var reserve := 0
	for uid in prof.data["team"]:
		var u := prof.unit(uid)
		if int(u["stage"]) < 3 and int(u["level"]) >= prof.level_cap(u) - 2:
			reserve += _evo_cost(u)
	while prof.data["credits"] - reserve >= E.recruit_costs[0] and prof.data["units"].size() < 8 and prof.can_recruit(0) == "":
		prof.recruit(0)
	# The rest: Training Cores for the lowest team member who isn't capped.
	while prof.data["credits"] - reserve >= E.core_cost:
		var low := -1
		for uid in prof.data["team"]:
			var u := prof.unit(uid)
			if int(u["level"]) < prof.level_cap(u) and (low < 0 or int(u["level"]) < int(prof.unit(low)["level"])):
				low = uid
		if low < 0:
			break
		prof.buy_core()
		prof.use_core(low)
	_pick_team(prof, act_n)


## Everyone's team right before a fight: [[level, rarity, stage, id], ...] strongest first.
func _team_snapshot(prof: Profile) -> Array:
	var us := []
	for uid in prof.data["team"]:
		us.append(prof.unit(uid))
	us.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _power(a) > _power(b))
	var out := []
	for u in us:
		out.append([int(u["level"]), int(u["rarity"]), int(u["stage"]), String(u["id"])])
	return out


func _player_team(prof: Profile) -> Array[FighterData]:
	var out: Array[FighterData] = []
	for uid in prof.data["team"]:
		out.append(prof.fighter(uid))
	return out


## The typical team: median level / rarity / stage per slot, on the reference characters.
func _typical_team(snaps: Array, size: int) -> Array[FighterData]:
	_typical_levels = []
	var tp := Profile.new({})
	var out: Array[FighterData] = []
	for k in size:
		var lv := []
		var ra := []
		var st := []
		for s in snaps:
			if k < s.size():
				lv.append(s[k][0])
				ra.append(s[k][1])
				st.append(s[k][2])
		if lv.is_empty():
			continue
		var uid := tp.add_unit(REF_IDS[k], _median(ra))
		var u := tp.unit(uid)
		u["level"] = _median(lv)
		u["stage"] = _median(st)
		out.append(tp.fighter(uid))
		_typical_levels.append(int(u["level"]))
	return out


func _median(a: Array) -> int:
	var b := a.duplicate()
	b.sort()
	return int(b[b.size() / 2])


## One fight for every player: snapshot, (fight tuned by the caller), rewards, spending.
func _play_fight_for_all(act: ActData, i: int, act_n: int) -> void:
	var fight: FightData = act.fights[i]
	for prof in players:
		prof.fight_rewards(fight, act_n, true, prof.team_uids(_team_size(act_n)), i == 7, i + 1)
		_spend(prof, act_n)


# ================================================================ one Act

func _build_act(n: int) -> void:
	var act: ActData = load("res://data/acts/act_%02d.tres" % n)
	var dir_e := "res://data/enemies/act%02d" % n
	var dir_f := "res://data/fights/act%02d" % n
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_e))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_f))
	for prof in players:
		_pick_team(prof, n, true)   # team of 4 from Act 2; upgraders re-pick by rarity
	var act_xp := P.total_xp_for(END_LEVEL[n - 1]) - P.total_xp_for(END_LEVEL[n - 2])
	var xps := _split_xp(act_xp)
	report.append("\nACT %d · %s (%s) · %s · %s · arena %s · %d XP" % [n, act.colony_name.to_upper(), act.colony_kind, act.singularity_name.to_upper(),
		Element.display_name(act.element), ARENA[n], act_xp])
	report.append("  Typical team at the start: %s" % _team_text(_typical_team(players.map(func(p: Profile) -> Array: return _team_snapshot(p)), 4)))
	var fights: Array[FightData] = []
	var boss_turns := []
	for slot in 8:
		var snaps: Array = players.map(func(p: Profile) -> Array: return _team_snapshot(p))
		var teams: Array = players.map(func(p: Profile) -> Array[FighterData]: return _player_team(p))
		var typical := _typical_team(snaps, 4)
		var tops := snaps.map(func(s: Array) -> int: return s[0][0])
		var level := _median(tops)
		var d := _enemy_for(n, act, slot)
		_tune(d, slot, typical, n, _prev_stats.get(slot, []))
		_prev_stats[slot] = [COUNTS[slot], d.max_hp, d.atk]
		var fname := _file_name(d.title if d.title != "" else d.display_name, slot)
		# take_over_path: the NEW card replaces any cached old one at that path.
		var e_path := "%s/%s.tres" % [dir_e, fname]
		d.take_over_path(e_path)
		ResourceSaver.save(d, e_path)
		var saved := d
		var f := FightData.new()
		var list: Array[FighterData] = []
		for k in COUNTS[slot]:
			list.append(saved)
		f.enemies = list
		f.xp = xps[slot]
		f.expected_level = level
		f.display_name = "%d/8 · %s" % [slot + 1, _title(d, slot)]
		var f_path := "%s/fight_%d.tres" % [dir_f, slot + 1]
		f.take_over_path(f_path)
		ResourceSaver.save(f, f_path)
		var fd := f
		fights.append(fd)
		report.append(_fight_line(fd, typical, teams))
		_play_fight_for_all_fd(fd, slot, n)
	act.fights = fights
	act.arena = load("res://assets/backgrounds/%s.png" % ARENA[n])
	act.boss_art = load("res://assets/bosses/%s.png" % BOSS_ART[n])
	var s: Dictionary = STORY[n]
	var intro: Array[String] = []
	for line in s["intro"]:
		intro.append(line)
	act.intro_lines = intro
	act.boss_taunt = s["taunt"]
	act.outro_line = s["outro"]
	act.codex_spliced_from = s["spliced"]
	act.codex_wanted = s["wanted"]
	act.codex_cost = s["cost"]
	ResourceSaver.save(act, "res://data/acts/act_%02d.tres" % n)
	_act_summary(n)


## One report line: the typical team element-neutral (what the fight was tuned for),
## then every player's OWN team against the real (elemental) enemies:
## win rate with good / average play (keepers K, upgraders U), median turns.
func _fight_line(f: FightData, typical: Array[FighterData], teams: Array) -> String:
	var list: Array = f.enemies
	var e0: FighterData = list[0]
	var nl := _neutral_list(e0, list.size())
	var good := BalanceSim.turns_to_win(nl, typical, "GOOD")
	var avg := BalanceSim.turns_to_win(nl, typical, "AVERAGE")
	var great := BalanceSim.great_turn(nl, typical)
	var won_good := [0, 0]
	var won_avg := 0
	var p_turns := []
	for k in teams.size():
		var t: Array[FighterData] = teams[k]
		var tg := BalanceSim.turns_to_win(list, t, "GOOD")
		var ok_good := tg < 50 and BalanceSim.avg_survives(list, t, "GOOD")
		var ok_avg := BalanceSim.turns_to_win(list, t, "AVERAGE") < 50 and BalanceSim.avg_survives(list, t, "AVERAGE")
		won_good[k % 2] += 1 if ok_good else 0
		won_avg += 1 if ok_avg else 0
		p_turns.append(tg)
	var half := teams.size() / 2.0
	return "  %-42s Lv%2d %d x %5d HP ATK %4d%s | typical team: good %d, avg %2d, idle %2d, great turn %s | players win: good play %3d%% (K %d%% / U %d%%), average %3d%%, median %d turns | %d XP" % [
		f.display_name, f.expected_level, list.size(), e0.max_hp, e0.atk, " ARMOUR" if e0.armored else "", good, avg,
		BalanceSim.idle_turns(nl, typical), "KILLS" if great["left"] == 0 else "leaves %d" % great["left"],
		roundi(100.0 * (won_good[0] + won_good[1]) / teams.size()), roundi(100.0 * won_good[0] / half), roundi(100.0 * won_good[1] / half),
		roundi(100.0 * won_avg / teams.size()), _median(p_turns), f.xp]


func _play_fight_for_all_fd(fight: FightData, i: int, act_n: int) -> void:
	for prof in players:
		prof.fight_rewards(fight, act_n, true, prof.team_uids(_team_size(act_n)), i == 7, i + 1)
		_spend(prof, act_n)


func _act_summary(n: int) -> void:
	var levels := [[], [], [], []]
	var stages := [0, 0, 0]
	var rar := [0, 0, 0, 0, 0, 0]
	var owned := []
	var credits := []
	var evolved_lead := 0
	for prof in players:
		var snap := _team_snapshot(prof)
		for k in snap.size():
			levels[k].append(snap[k][0])
			stages[snap[k][2] - 1] += 1
			rar[snap[k][1]] += 1
		owned.append(prof.data["units"].size())
		credits.append(int(prof.data["credits"]))
		evolved_lead += 1 if snap[0][2] >= 2 else 0
	var lv_txt := PackedStringArray()
	for k in 4:
		if not levels[k].is_empty():
			lv_txt.append("Lv%d" % _median(levels[k]))
	var total := 0
	for x in rar:
		total += x
	var rar_txt := PackedStringArray()
	for r in 6:
		if rar[r] > 0:
			rar_txt.append("%s %d%%" % [E.rarity_names[r], roundi(100.0 * rar[r] / total)])
	report.append("  After the boss: team levels %s (strongest first) · team rarity: %s · evolution: Stage 1 %d%%, Stage 2 %d%%, Stage 3 %d%% · lead evolved: %d%% · owns %d characters · %d Credits left (medians)" % [
		" / ".join(lv_txt), ", ".join(rar_txt), roundi(100.0 * stages[0] / total), roundi(100.0 * stages[1] / total), roundi(100.0 * stages[2] / total),
		roundi(100.0 * evolved_lead / PLAYERS), _median(owned), _median(credits)])


## e.g. "Lv12 Forged St1 Berserker (502/149/16)" per slot (the typical team just built).
func _team_text(team: Array[FighterData]) -> String:
	var parts := PackedStringArray()
	var roles := ["Berserker", "Titan", "Spectre", "Biotech"]
	for k in team.size():
		var f := team[k]
		parts.append("Lv%d %s St%d %s (%d/%d/%d)" % [_typical_levels[k], Catalog.rarity_name(f.rarity), f.stage, roles[f.role], f.max_hp, f.atk, f.rcv])
	return ", ".join(parts)


# ================================================================ enemies

## A new enemy data card for this Act's fight slot (stats are tuned after).
func _enemy_for(n: int, act: ActData, slot: int) -> FighterData:
	var d := FighterData.new()
	d.role = FighterData.Role.ENEMY
	d.rcv = 0
	if slot == 7:
		d.display_name = act.singularity_name.to_upper()
		d.element = act.element
		d.art = load("res://assets/bosses/%s.png" % BOSS_ART[n])
		d.figure_height = 400.0
		d.figure_width = 380.0
		d.armored = true
		d.is_boss = true
		d.kind = &"boss"
		return d
	var key: String = PLAN[n][slot]
	var elem_name := key.get_slice("_", 0)
	var name := key.substr(elem_name.length() + 1)
	d.display_name = name.replace("_", " ").to_upper()
	if NAMES.has(name):
		d.title = name.replace("_", " ").capitalize()
		d.display_name = String(NAMES[name]).to_upper()
	d.element = ELEMENTS[elem_name]
	d.art = load("res://assets/enemies/enemy_%s.png" % key)
	var size := _size_for(name)
	var mini := slot == 2 or slot == 6
	d.figure_height = size.x * (1.18 if mini else 1.0)
	d.figure_width = size.y * (1.18 if mini else 1.0)
	d.armored = mini
	d.is_boss = mini
	d.kind = &"art"
	return d


## Rough on-screen size (height, width) from what the enemy is.
func _size_for(name: String) -> Vector2:
	for small in ["drone", "sprite", "wisp", "imp", "spawnling", "sproutling", "bomber", "ghost"]:
		if name.contains(small):
			return Vector2(240, 210)
	for wide in ["hound", "crawler", "turret"]:
		if name.contains(wide):
			return Vector2(260, 260)
	for big in ["brute", "guard", "biker", "scrapbot", "mutant"]:
		if name.contains(big):
			return Vector2(330, 230)
	if name.contains("slime"):
		return Vector2(280, 190)
	return Vector2(310, 160)


## Tune against the typical team, element-neutral (see the header).
## prev = [enemy count, HP, ATK] of the same fight slot in the Act before: this
## fight is never weaker (at least ACT_STEP stronger), so every Act is harder.
func _tune(d: FighterData, slot: int, team: Array[FighterData], act_n: int, prev: Array) -> void:
	var n: int = COUNTS[slot]
	var probe: FighterData = d.duplicate()
	probe.element = Element.Type.NONE
	var lo := _min_hp_for_turns(probe, n, team, GOOD_TURNS[slot])
	var hi := _min_hp_for_turns(probe, n, team, GOOD_TURNS[slot] + 1)
	probe.max_hp = snappedi((lo + hi) / 2, 10)
	var hp := BalanceSim.team_hp(team)
	probe.atk = ceili(float(hp) / (n * IDLE_TURNS[slot]))
	while ceili(float(hp) / (n * probe.atk)) > IDLE_TURNS[slot]:
		probe.atk += 1
	# Harder than the base targets, and harder every Act.
	probe.max_hp = snappedi(roundi(probe.max_hp * HP_SCALE[act_n - 2]), 10)
	probe.atk = roundi(probe.atk * ATK_SCALE[act_n - 2])
	if prev.size() == 3 and prev[0] == n:
		probe.max_hp = maxi(probe.max_hp, snappedi(ceili(prev[1] * ACT_STEP), 10))
		probe.atk = maxi(probe.atk, ceili(prev[2] * ACT_STEP))
	var mode := "GOOD" if d.armored else "AVERAGE"
	while not BalanceSim.avg_survives(_list(probe, n), team, mode) and probe.atk > 10:
		probe.atk = int(probe.atk * 0.97)
	if d.armored:
		var great := BalanceSim.great_turn(_list(probe, n), team, false)
		if great["left"] == 0:
			probe.max_hp = snappedi(ceili(great["dealt"] * 1.15), 10)
	d.max_hp = probe.max_hp
	d.atk = probe.atk


func _min_hp_for_turns(d: FighterData, n: int, team: Array[FighterData], turns: int) -> int:
	var a := 10
	var b := 60000
	while a < b:
		var mid := (a + b) / 2
		d.max_hp = mid
		if BalanceSim.turns_to_win(_list(d, n), team, "GOOD") >= turns:
			b = mid
		else:
			a = mid + 1
	return a


func _list(d: FighterData, n: int) -> Array:
	var out := []
	for k in n:
		out.append(d)
	return out


func _neutral_list(d: FighterData, n: int) -> Array:
	var c: FighterData = d.duplicate()
	c.element = Element.Type.NONE
	return _list(c, n)


func _split_xp(total: int) -> Array:
	var out := []
	var given := 0
	for k in XP_SHARE.size():
		var x := snappedi(total * XP_SHARE[k] / 1350.0, 5) if k < XP_SHARE.size() - 1 else total - given
		out.append(x)
		given += x
	return out


func _file_name(display_name: String, slot: int) -> String:
	if slot == 7:
		return "boss_" + display_name.to_lower().replace(" ", "_").replace("-", "")
	return display_name.to_lower().replace(" ", "_") + ("_mini" if slot == 2 or slot == 6 else "")


func _title(d: FighterData, slot: int) -> String:
	var name := d.display_name
	if slot == 7:
		return "BOSS: " + name
	if slot == 2 or slot == 6:
		return "MINI-BOSS: " + name + (" (%s)" % d.title.to_upper() if d.title != "" else "")
	if d.title != "":
		return "%s · %s" % [name, _plural(d.title.to_upper())]
	return _plural(name)


func _plural(name: String) -> String:
	if name.ends_with("THIEF"):
		return name.trim_suffix("F") + "VES"
	if name.ends_with("Y") and not "AEIOU".contains(name[name.length() - 2]):
		return name.trim_suffix("Y") + "IES"
	if name.ends_with("S") or name.ends_with("SH"):
		return name + "ES"
	return name + "S"
