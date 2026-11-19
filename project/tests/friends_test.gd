extends Node
## Friends + attack animations + skill cut-ins test.
##   FX   - Bailey's 6 attack-animation sheets: cut into 4 equal frames, played on
##          every orb attack (its element) and every heal; screenshots s5_fx_*.png
##   FD   - the 4 friends (Jake, Johnny, Khoel, Logan): data, ultra-rare drop (0.25%),
##          never in Recruit / Lab / Essence
##   FS   - their own skills: 4 actives, 4 leaders, 4 passives do what the text says
##   FB   - balance: friend teams of 3 clear Act 1 in 15-17 turns (not overpowered)
##   CI   - skill cut-in over the BOARD only: 0.85 s, 2.0 s for Stage 3 / Singularity,
##          tap skips, Settings toggle (home ⚙ and the battle MENU)
## Run:  Godot_v4.7.2-stable_win64_console.exe --path . res://tests/friends_test.tscn
## Results: tests/report_friends.txt, screenshots tests/screenshots/s5_*.png

const BattleScene := preload("res://scenes/battle.tscn")
const T := Element.Type
const BASE := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "FWGLDH"]
const ROWS_OF := {
	Element.Type.FIRE: ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "FFFLDH"],
	Element.Type.WATER: ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "WWWLDH"],
	Element.Type.WOOD: ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "GGGLDH"],
	Element.Type.LIGHT: ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "LLLFWH"],
	Element.Type.DARK: ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "DDDLWH"],
}
const HEARTS := ["FWGLDH", "LDHFWG", "FWGLDH", "LDHFWG", "HHHFWL"]
const THREE_ELEMENTS := ["FWGLDH", "LDHFWG", "GGGLDH", "LDHFWG", "FFFWWW"]
const SETTINGS_PATH := "user://friends_test_settings.json"

var battle: Node2D
var lines := PackedStringArray()
var fails := 0
var screenshots := true
var tu: SkillTuning = Skills.TUNING
var texts: Array = []
var sheets_seen: Array = []          ## sprite_frames of every AnimatedSprite2D added to the world
var fx_shot := ""                    ## next attack sheet -> this screenshot
var last_combos := 0
var last_cleared := {}
var last_groups: Array = []
var numbers_during_cut_in := 0


func _ready() -> void:
	GameSettings.path = SETTINGS_PATH   # never touch the player's settings
	GameSettings.skill_cut_ins = false
	screenshots = DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/screenshots"))
	battle = BattleScene.instantiate()
	add_child(battle)
	await _frames(3)
	if not "cut_in" in battle:
		_check(false, "battle script failed to load")
		_finish()
		return
	battle.world.child_entered_tree.connect(_on_world_child)
	battle.board.turn_finished.connect(func(c: int, cl: Dictionary, g: Array) -> void:
		last_combos = c
		last_cleared = cl
		last_groups = g)
	_log("Godot %s · Friends + attack animations + skill cut-ins" % Engine.get_version_info().string)
	if screenshots:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	_test_sheets()
	await _test_attack_fx()
	_test_friend_data()
	_test_drops()
	await _test_friend_actives()
	_test_friend_leaders()
	await _test_friend_passives()
	_test_balance()
	await _test_cut_in()
	await _test_settings()
	await _test_friend_plates()
	_finish()


func _on_world_child(n: Node) -> void:
	if n is FloatingText:
		texts.append(n.text)
		if battle.cut_in.playing and (n.text as String).trim_suffix("!").is_valid_int():
			numbers_during_cut_in += 1
	elif n is AnimatedSprite2D:
		sheets_seen.append((n as AnimatedSprite2D).sprite_frames)
		if fx_shot != "":
			var shot := fx_shot
			fx_shot = ""
			_snap_later(shot, 0.12)


func _snap_later(shot_name: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	await _shot(shot_name)


func _sheet_frames(key: String) -> SpriteFrames:
	return SkillFx._frames_cache.get(key, null)


# ================================================================ FX: attack animations

func _test_sheets() -> void:
	_log("\n== FX: Bailey's attack animations -> game sheets ==")
	var ok := true
	var info := PackedStringArray()
	for key in SkillFx.SHEET_FOR_ELEMENT.values() + [SkillFx.HEAL_SHEET]:
		if not SkillFx.has_sheet(key):
			ok = false
			info.append("%s MISSING" % key)
			continue
		var tex: Texture2D = load(SkillFx.FX_DIR + key + ".png")
		var img := tex.get_image()
		if img.is_compressed():
			img = img.duplicate()
			img.decompress()
		var corner_clear := img.get_pixel(0, 0).a < 0.05 and img.get_pixel(img.get_width() - 1, img.get_height() - 1).a < 0.05
		ok = ok and tex.get_width() % 4 == 0 and corner_clear
		info.append("%s %dx%d" % [key, tex.get_width() / 4, tex.get_height()])
	_check(ok, "all 6 sheets are in assets/fx/: 4 equal frames each, transparent background (%s)" % ", ".join(info))


func _test_attack_fx() -> void:
	_log("\n== FX: every orb attack plays its element's animation; heals play the heal animation ==")
	var hero_of := {T.FIRE: "berserker_01_angel_fire", T.WATER: "berserker_03_thin_water", T.WOOD: "berserker_02_hulk_wood",
		T.LIGHT: "berserker_05_solar_light", T.DARK: "berserker_04_void_dark"}
	var names := {T.FIRE: "fire", T.WATER: "water", T.WOOD: "wood", T.LIGHT: "light", T.DARK: "dark"}
	var all_ok := true
	for el in hero_of:
		await _setup([_hero(hero_of[el])], _dummy(99999, 10))
		_set_board(ROWS_OF[el])
		sheets_seen.clear()
		fx_shot = "s5_fx_%s" % names[el]
		var t0 := Time.get_ticks_msec()
		await _tap(Vector2i(5, 0))
		await _await_turn_end()
		var played := sheets_seen.has(_sheet_frames(SkillFx.SHEET_FOR_ELEMENT[el]))
		all_ok = all_ok and played
		_log("INFO  %s attack: animation %s, turn took %.2f s" % [names[el], "played" if played else "NOT played", (Time.get_ticks_msec() - t0) / 1000.0])
	_check(all_ok, "a Fire / Water / Wood / Light / Dark orb attack plays that element's animation on the enemy")
	await _setup([_hero("biotech_01_medic_water")], _dummy(99999, 10))
	battle.team.hp = 100
	_set_board(HEARTS)
	sheets_seen.clear()
	fx_shot = "s5_fx_heal"
	await _tap(Vector2i(5, 0))
	await _await_turn_end()
	_check(sheets_seen.has(_sheet_frames(SkillFx.HEAL_SHEET)), "matching Hearts plays the heal animation over the team")
	_check(battle.ATTACK_FX_TIME < 0.6, "the attack animation plays alongside the hit (%.2f s, doesn't wait): attack + hit is still 0.48 s per hunter" % battle.ATTACK_FX_TIME)
	await get_tree().create_timer(0.5).timeout


# ================================================================ FD: the friends

func _test_friend_data() -> void:
	_log("\n== FD: Bailey's 4 friends ==")
	var want := {
		"friend_jake": ["JAKE", T.LIGHT, FighterData.Role.BERSERKER, [320, 95, 10]],
		"friend_johnny": ["JOHNNY", T.DARK, FighterData.Role.TITAN, [470, 78, 26]],
		"friend_khoel": ["KHOEL", T.FIRE, FighterData.Role.BIOTECH, [350, 72, 46]],
		"friend_logan": ["LOGAN", T.FIRE, FighterData.Role.SPECTRE, [230, 110, 8]],
	}
	var ok := true
	for id in Catalog.FRIEND_IDS:
		var c := Catalog.template(id)
		var w: Array = want[id]
		var art_ok := c.art != null and c.art.get_width() == 512
		ok = ok and c.display_name == w[0] and c.element == w[1] and c.role == w[2] and [c.max_hp, c.atk, c.rcv] == w[3] and c.fixed_rarity == 3 and art_ok and c.passives.size() == 3
		_log("INFO  %-7s %-16s %s | %-15s CD%d | %-12s | %s / %s / %s" % [c.display_name, c.title, Catalog.rarity_name(c.fixed_rarity), Skills.display_name(c.active_skill), Skills.cooldown(c.active_skill),
			Skills.display_name(c.leader_skill), Skills.display_name(c.passives[0]), Skills.display_name(c.passives[1]), Skills.display_name(c.passives[2])])
	_check(ok, "Jake (Light Berserker), Johnny (Dark Titan), Khoel (Fire Biotech), Logan (Fire Spectre): their own art, normal stats for their type, always Prime")
	var own_skills := true
	var seen := {}
	for id in Catalog.FRIEND_IDS:
		var c := Catalog.template(id)
		for s in [c.active_skill, c.leader_skill, c.passives[0]]:
			own_skills = own_skills and Skills.describe(s, c.element) != "" and not seen.has(s)
			seen[s] = true
		own_skills = own_skills and Skills.cooldown(c.active_skill) >= 5 and Skills.cooldown(c.active_skill) <= 9
	for id in Catalog.IDS + Catalog.ENEMY_IDS + Catalog.RECOLOR_IDS:
		var c := Catalog.template(id)
		for s in [c.active_skill, c.leader_skill] + Array(c.passives):
			own_skills = own_skills and not seen.has(s)
	_check(own_skills, "each friend has its OWN active, leader and passive (12 new skills, no one else has them), cooldowns 5-9")


func _test_drops() -> void:
	_log("\n== FD: ultra-rare drop ==")
	var never := true
	for r in 6:
		for id in Catalog.pool_for_rarity(r):
			never = never and not Catalog.is_friend(id)
	for id in Catalog.lab_ids():
		never = never and not Catalog.is_friend(id)
	_check(never, "friends are never in Recruit (any rarity), the Lab or Essence: only the rare drop")
	var p := Profile.new({})
	p.rng.seed = 2026
	var drops := 0
	var n := 40000
	for i in n:
		if not p.friend_drop().is_empty():
			drops += 1
	var rate := float(drops) / n
	_check(rate > 0.0015 and rate < 0.0035, "drop chance after a won fight: %.2f%% measured over %d wins (set: %.2f%% = about 1 win in %d)" % [rate * 100, n, Profile.ECONOMY.friend_drop_chance * 100, roundi(1.0 / Profile.ECONOMY.friend_drop_chance)])
	var q := Profile.new({})
	for id in ["friend_jake", "friend_johnny", "friend_khoel"]:
		q.add_unit(id, 3)
	var got := q.friend_drop(0.0)
	_check(got.get("id", "") == "friend_logan", "it prefers a friend you don't own yet (owning 3, the drop was %s)" % got.get("id", "none"))
	var full := Profile.new({})
	full.add_unit("berserker_01_angel_fire", 2)
	full.data["roster_cap"] = 1
	var before: int = full.data["units"].size()
	var fr := full.friend_drop(0.0)
	_check(fr.has("id") and full.data["units"].size() == before + 1 and full.unit(fr["uid"])["rarity"] == 3, "a friend joins even with a full roster, at Prime rarity")
	_check(q.friend_drop(Profile.ECONOMY.friend_drop_chance + 0.0001).is_empty(), "a roll above the chance gives nothing")
	var text := Profile.rewards_text({"credits": 40, "essence": {}, "keys": 0, "level_ups": [], "new_unit": {}, "friend": {"id": "friend_jake", "uid": 1, "in_team": true}})
	_check(text.contains("ULTRA RARE! JAKE (Prime) joined your team!"), "the result screen says so: \"%s\"" % text.get_slice("\n", 1))
	var w := Profile.new({})
	w.choose_starter(Profile.STARTERS[0])
	var r := w.fight_rewards(Cosmos.ACTS[0].fights[1], 1, true, w.team_uids(3), false, 2)
	_check(r.has("friend"), "every won fight rolls for it (fight_rewards has a \"friend\" entry)")


# ================================================================ FS: their skills

func _test_friend_actives() -> void:
	_log("\n== FS: friend active skills ==")
	# Twin Comet (Jake): every enemy twice for ATK x1, + 3 random Light orbs.
	await _setup([_hero("friend_jake")], _dummy(4000, 10, 2))
	_set_board(BASE)
	var light_before := _count(T.LIGHT)
	await _use(0, "twin_comet")
	var hit := roundi(95 * tu.twin_comet_atk_mult)
	_check(_hps() == [4000 - hit * 2, 4000 - hit * 2] and _count(T.LIGHT) == light_before + tu.twin_comet_orbs,
		"Jake Twin Comet: both enemies hit twice for %d (ATK 95 x1), and %d orbs turned Light (%d -> %d)" % [hit, tu.twin_comet_orbs, light_before, _count(T.LIGHT)])
	# Thunder Hammer (Johnny): ATK x2 and a stun (skips its next attack).
	await _setup([_hero("friend_johnny")], _dummy(4000, 100))
	await _use(0, "thunder_hammer")
	var stunned: bool = battle.enemies[0].stunned_attacks == 1
	var hp0: int = battle.team.hp
	await _no_match_turn()
	var skipped: bool = battle.team.hp == hp0
	await _no_match_turn()
	_check(battle.enemies[0].hp == 4000 - 156 and stunned and skipped and battle.team.hp < hp0 and texts.has("STUNNED"),
		"Johnny Thunder Hammer: 156 (ATK 78 x2), the enemy skips its next attack, then attacks again")
	var boss := _dummy(4000, 100)
	boss.enemies[0].is_boss = true
	await _setup([_hero("friend_johnny")], boss)
	await _use(0, "")
	var hp_b: int = battle.team.hp
	await _no_match_turn()
	var want_b := roundi(100 * tu.thunder_hammer_boss_weaken * tu.leader_bedrock_damage_taken)
	_check(battle.enemies[0].stunned_attacks == 0 and hp_b - battle.team.hp == want_b, "  bosses can't be stunned: their next hit is 50%% weaker instead (100 -> %d with Bedrock's -10%%)" % (hp_b - battle.team.hp))
	# Overclock (Khoel): every OTHER skill charges 2 turns, heals 10%.
	await _setup([_hero("friend_khoel"), _hero("berserker_01_angel_fire"), _hero("biotech_01_medic_water")], _dummy(4000, 10))
	battle.team.skill_turns[1] = 5
	battle.team.skill_turns[2] = 4
	battle.team.hp = battle.team.max_hp / 2
	var hp_k: int = battle.team.hp
	await _use(0, "overclock")
	_check(battle.team.skill_turns[1] == 3 and battle.team.skill_turns[2] == 2 and battle.team.hp == hp_k + roundi(battle.team.max_hp * tu.overclock_heal_ratio) and battle.team.skill_turns[0] == battle.team.members[0].skill_cooldown(),
		"Khoel Overclock: the other skills charge 2 turns (5 -> 3, 4 -> 2), heals 10%, its own goes on cooldown")
	# Inferno Cleaver (Logan): ATK x3, then burns ATK x0.5 at the start of the next 3 turns.
	await _setup([_hero("friend_logan")], _dummy(4000, 10))
	await _use(0, "inferno_cleaver")
	var after_hit: int = battle.enemies[0].hp
	var burns := []
	for k in 4:
		var before: int = battle.enemies[0].hp
		await _no_match_turn()
		burns.append(before - battle.enemies[0].hp)
	var burn := roundi(110 * tu.inferno_burn_mult)
	_check(after_hit == 4000 - 330 and burns == [burn, burn, burn, 0], "Logan Inferno Cleaver: 330 (ATK 110 x3), then BURN %d at the start of each of the next 3 turns (%s), then it stops" % [burn, burns])
	# A burn can win the fight.
	await _setup([_hero("friend_logan")], _dummy(400, 10))
	await _use(0, "")
	await _no_match_turn()
	await _no_match_turn()
	await get_tree().create_timer(0.3).timeout
	_check(battle.result_panel.visible and battle.enemies[0].is_defeated(), "  a burn that finishes the last enemy wins the fight (400 HP: 330, burn 55, burn the last 15)")


func _test_friend_leaders() -> void:
	_log("\n== FS: friend leader skills ==")
	var CR := CombatRules
	var jake := _hero("friend_jake")
	var light := _hero("berserker_05_solar_light")
	var fire := _hero("berserker_01_angel_fire")
	var g2 := [_g(T.LIGHT, 3), _g(T.LIGHT, 3)]
	var g3 := [_g(T.LIGHT, 3), _g(T.LIGHT, 3), _g(T.LIGHT, 3)]
	_check(is_equal_approx(CR.leader_multiplier(jake, light, [_g(T.LIGHT, 3)], 1), 1.15) and is_equal_approx(CR.leader_multiplier(jake, light, g2, 2), 1.15)
		and is_equal_approx(CR.leader_multiplier(jake, light, g3, 3), 2.0) and CR.leader_multiplier(jake, fire, g3, 3) == 1.0,
		"Jake Hammerfall: Light x1.15; x2 with 3 separate Light groups; other elements x1")
	var johnny := _hero("friend_johnny")
	var dark := _hero("berserker_04_void_dark")
	var jt := Team.new(_typed([johnny]))
	_check(jt.max_hp == roundi(470 * 1.2) and is_equal_approx(CR.leader_damage_taken(jt), 0.9) and is_equal_approx(CR.leader_multiplier(johnny, dark, [], 1), 1.15) and CR.leader_multiplier(johnny, fire, [], 1) == 1.0,
		"Johnny Bedrock: team HP x1.2 (%d), the team takes 10%% less, Dark x1.15" % jt.max_hp)
	var khoel := _hero("friend_khoel")
	var three := [_g(T.FIRE, 3), _g(T.WATER, 3), _g(T.WOOD, 3)]
	var two := [_g(T.FIRE, 3), _g(T.WATER, 3), _g(T.HEART, 3)]
	_check(is_equal_approx(CR.leader_multiplier(khoel, fire, three, 3), 1.35) and CR.leader_multiplier(khoel, fire, two, 3) == 1.0
		and CR.leader_skill_charge(khoel, three) == 1 and CR.leader_skill_charge(khoel, two) == 0,
		"Khoel Neural Link: 3 different elements -> team x1.35 and every skill +1 charge (2 elements + Hearts: nothing)")
	var logan := _hero("friend_logan")
	var low := Enemy.new(_dummy(1000, 10).enemies[0])
	low.hp = 140
	var mid := Enemy.new(_dummy(1000, 10).enemies[0])
	mid.hp = 400
	_check(is_equal_approx(CR.leader_multiplier(logan, fire, [], 1, low), 2.0) and CR.leader_multiplier(logan, fire, [], 1, mid) == 1.0 and CR.leader_multiplier(logan, light, [], 1, low) == 1.0
		and CR.leader_kill_charge(logan) == 1 and CR.leader_kill_charge(jake) == 0,
		"Logan Executioner: Fire x2 on enemies below 15% HP (x1 at 40%), and every enemy defeated charges every skill 1 turn")


func _test_friend_passives() -> void:
	_log("\n== FS: friend passives (and the leaders' charging in a real battle) ==")
	var CR := CombatRules
	var jake := _hero("friend_jake", 1)
	_check(is_equal_approx(CR.passive_multiplier(jake, [_g(T.LIGHT, 3), _g(T.LIGHT, 3)], 2, null, false), 1.3) and CR.passive_multiplier(jake, [_g(T.LIGHT, 3)], 1, null, false) == 1.0,
		"Jake Double Swing (Lv10): 2 separate Light groups -> its ATK x1.3")
	var khoel := Team.new(_typed([_hero("friend_khoel", 1)]))
	var both := Team.new(_typed([_hero("friend_khoel", 1), _hero("enemy_spore_sprout", 1), _hero("friend_khoel", 1)]))
	_check(is_equal_approx(CR.move_time(khoel), 5.5) and is_equal_approx(CR.move_time(both), 6.5), "Khoel Thruster Boost (Lv10, TEAM): +0.5 s to move orbs (5.5 s); with Time Extend 6.5 s; two Khoels don't stack")
	# Molten Edge (Logan): his orb attacks ignore armour (full damage, armour stays up).
	# (Retry until the cascade makes no 4+ Fire group, which would break the armour anyway.)
	for attempt in 12:
		await _setup([_hero("friend_logan", 1)], _dummy(99999, 10, 1, true))
		_set_board(ROWS_OF[T.FIRE])
		seed(9100 + attempt)
		await _tap(Vector2i(5, 0))
		await _await_turn_end()
		if not CombatRules.breaks_armor(battle.team.members[0], last_groups):
			break
	var dealt: int = 99999 - battle.enemies[0].hp
	var orbs: int = last_cleared.get(T.FIRE, 0)
	var full := DamageCalculator.attack_damage(110, orbs, last_combos, T.FIRE, T.NONE, 1.0)
	_check(dealt == full and battle.enemies[0].armor_up, "Logan Molten Edge (Lv10): %d damage through armour (full, not %d), and the armour stays up" % [dealt, roundi(full * 0.5)])
	# Storm Battery (Johnny): the team is hit -> his skill charges 1.
	await _setup([_hero("friend_johnny", 1)], _dummy(99999, 50))
	battle.team.skill_turns[0] = 5
	await _no_match_turn()
	_check(battle.team.skill_turns[0] == 4 and texts.has("CHARGE +1"), "Johnny Storm Battery (Lv10): a turn where the team is hit charges his skill 1 (5 -> %d)" % battle.team.skill_turns[0])
	# Neural Link in battle: 3 elements matched -> every skill charges 1 extra.
	await _setup([_hero("friend_khoel"), _hero("berserker_01_angel_fire"), _hero("biotech_01_medic_water")], _dummy(99999, 10))
	for k in 3:
		battle.team.skill_turns[k] = 6
	_set_board(THREE_ELEMENTS)
	await _tap(Vector2i(5, 0))
	await _await_turn_end()
	var elements := CombatRules.distinct_attack_types(last_groups)
	_check(elements >= 3 and str(battle.team.skill_turns) == "[4, 4, 4]", "Khoel leading, %d elements matched: every skill charged 2 (1 + Neural Link 1): %s" % [elements, battle.team.skill_turns])
	# Executioner in battle: a defeated enemy charges every skill 1.
	var fight := _dummy(99999, 10, 2)
	fight.enemies[0].max_hp = 30
	await _setup([_hero("friend_logan"), _hero("berserker_01_angel_fire")], fight)
	battle.team.skill_turns[0] = 6
	battle.team.skill_turns[1] = 6
	_set_board(ROWS_OF[T.FIRE])
	await _tap(Vector2i(5, 0))
	await _await_turn_end()
	_check(battle.enemies[0].is_defeated() and str(battle.team.skill_turns) == "[4, 4]", "Logan leading: defeating an enemy charged every skill 1 more (6 -> 4 = turn + kill): %s" % [battle.team.skill_turns])


func _test_balance() -> void:
	_log("\n== FB: not overpowered (the same Act 1 balance test every character passes) ==")
	var act: ActData = Cosmos.ACTS[0]
	var humans := {T.FIRE: ["berserker_01_angel_fire", "spectre_02_mage_fire"], T.LIGHT: ["berserker_05_solar_light", "spectre_05_infiltrator_light"], T.DARK: ["berserker_04_void_dark", "spectre_01_rogue_dark"]}
	var trio_ok := true
	var lead_ok := true
	for id in Catalog.FRIEND_IDS:
		var c := Catalog.template(id)
		var trio := _act_turns(act, [c, c, c])
		var hs: Array = humans[c.element]
		var h0 := Catalog.template(hs[0])
		var h1 := Catalog.template(hs[1])
		var led := _act_turns(act, [c, h0, h1])
		var ref := _act_turns(act, [h0, h0, h1])
		trio_ok = trio_ok and trio[0] >= 15 and trio[0] <= 17 and trio[1]
		lead_ok = lead_ok and led[0] >= 14 and led[0] >= ref[0] - 1
		_log("INFO  %-7s 3x itself: %2d turns%s | leads %s + %s: %2d (under a human leader: %2d)" % [c.display_name, trio[0], "" if trio[1] else " LOSES A FIGHT", h0.display_name, h1.display_name, led[0], ref[0]])
	_check(trio_ok, "every friend's team of 3 clears Act 1 in 15-17 turns (good play), like every other character")
	_check(lead_ok, "a friend leading a team is at most 1 turn faster than a human leader (never under 14)")
	var mb: FighterData = act.fights[2].enemies[0]
	var cleave := CombatRules.skill_hit(Catalog.template("friend_logan"), Enemy.new(mb), tu.inferno_cleaver_atk_mult)
	var burn := CombatRules.skill_hit(Catalog.template("friend_logan"), Enemy.new(mb), tu.inferno_burn_mult) * tu.inferno_burn_turns
	_check((cleave + burn) * 2 < mb.max_hp, "the biggest Lv1 friend skill (Inferno Cleaver %d + burns %d, x2 element = %d) is far from a %d HP mini-boss" % [cleave, burn, (cleave + burn) * 2, mb.max_hp])
	var c30: FighterData = CombatRules.at_level(Catalog.template("friend_logan"), 30).duplicate()
	c30.atk = roundi(c30.atk * Profile.ECONOMY.rarity_stat_mult[5] * 1.2)
	var boss := Enemy.new(act.fights[7].enemies[0])
	var dealt := boss.take_hit(CombatRules.skill_hit(c30, boss, tu.inferno_cleaver_atk_mult), true) + boss.take_hit(CombatRules.skill_hit(c30, boss, tu.inferno_cleaver_atk_mult), true)
	_check(dealt <= ceili(boss.data.max_hp * 0.5), "Resolve: a Lv30 evolved Logan's Inferno Cleaver (x2 tried) takes Emberfang-9 down by only %d of %d in a turn" % [dealt, boss.data.max_hp])


# ================================================================ CI: skill cut-in

func _test_cut_in() -> void:
	_log("\n== CI: skill cut-in over the board ==")
	GameSettings.skill_cut_ins = true
	var ci: SkillCutIn = battle.cut_in
	# Normal: Joren (a damage skill) at Stage 1.
	await _setup([_hero("spectre_02_mage_fire")], _dummy(99999, 10))
	numbers_during_cut_in = 0
	texts.clear()
	battle.use_skill(0)
	await _frames(3)
	var on: bool = ci.playing and ci.visible
	var board_rect := Rect2(battle.board.position, Vector2(Board.COLS * Board.CELL, Board.ROWS * Board.CELL))
	var ci_rect := Rect2(ci.position, ci.size)
	var arena_bottom: float = battle.enemy_views[0].position.y + 60
	_check(on and ci_rect == board_rect and ci.clip_contents and ci_rect.position.y > arena_bottom,
		"using a skill flashes the cut-in over the orb board only (x %d-%d, y %d-%d); the arena above (enemies end ~y %d) stays visible" % [ci_rect.position.x, ci_rect.end.x, ci_rect.position.y, ci_rect.end.y, arena_bottom])
	_check(is_equal_approx(ci._portrait.size.x, 810.0) and ci._skill_label.text == "EMBER LANCE" and ci._name_label.text == "JOREN ASH",
		"the full portrait is 810 px wide (75%% of the screen), with the skill name \"%s\" and the hunter's name \"%s\"" % [ci._skill_label.text, ci._name_label.text])
	await get_tree().create_timer(0.3).timeout
	await _shot("s5_cutin_normal")
	await _wait_skill()
	_check(numbers_during_cut_in == 0 and texts.any(func(s: String) -> bool: return s.is_valid_int()), "the damage number lands on the enemy only AFTER the cut-in clears (none while it showed)")
	# Timing runs without a screenshot (saving one stalls a frame and adds to the time).
	await _setup([_hero("spectre_02_mage_fire")], _dummy(99999, 10))
	battle.use_skill(0)
	await _wait_skill()
	_check(ci.last_duration >= 0.8 and ci.last_duration <= 1.0 and not ci.last_long, "normal cut-in: %.2f s on screen (0.15 in + 0.5 hold + 0.2 fade out; target 0.8-1.0 s)" % ci.last_duration)
	# Long: Stage 3 (fully evolved), and Singularity rarity.
	var s3 := _hero("berserker_01_angel_fire")
	s3.stage = 3
	s3.art = Catalog.art("berserker_01_angel_fire", 3)
	await _setup([s3], _dummy(99999, 10))
	battle.use_skill(0)
	await get_tree().create_timer(1.0).timeout
	await _shot("s5_cutin_stage3")
	await _wait_skill()
	await _setup([s3], _dummy(99999, 10))
	battle.use_skill(0)
	await _wait_skill()
	_check(ci.last_long and ci.last_duration >= 1.9 and ci.last_duration <= 2.1, "Stage 3 hunter: the long cut-in, %.2f s (target 2.0 s)" % ci.last_duration)
	var sing := _hero("friend_jake")
	sing.rarity = 5
	await _setup([sing], _dummy(99999, 10, 2))
	battle.use_skill(0)
	await get_tree().create_timer(0.8).timeout
	await _shot("s5_cutin_singularity_jake")
	await _wait_skill()
	await _setup([sing], _dummy(99999, 10, 2))
	battle.use_skill(0)
	await _wait_skill()
	_check(ci.last_long and ci.last_duration >= 1.9 and ci.last_duration <= 2.1 and SkillCutIn.is_long(sing) and not SkillCutIn.is_long(_hero("friend_jake")),
		"Singularity rarity: the long cut-in too, %.2f s (a Prime Jake gets the normal one)" % ci.last_duration)
	# Tap to skip.
	await _setup([_hero("friend_logan")], _dummy(99999, 10))
	battle.use_skill(0)
	await get_tree().create_timer(0.15).timeout
	var tap := Vector2(540, 300)   # a tap in the arena: skips, and doesn't target anything
	_press(tap)
	await _frames(1)
	_release(tap)
	await _wait_skill()
	_check(ci.skipped and ci.last_duration < 0.35 and battle.target_index == -1 and battle.enemies[0].hp < 99999,
		"tapping the screen skips it (gone after %.2f s, the tap didn't target an enemy) and the skill still lands" % ci.last_duration)
	# Off in Settings: no cut-in at all.
	GameSettings.skill_cut_ins = false
	await _setup([_hero("friend_khoel")], _dummy(99999, 10))
	battle.use_skill(0)
	var seen := false
	while battle._busy:
		seen = seen or ci.visible
		await get_tree().process_frame
	_check(not seen and not battle._busy, "Skill Cut-ins OFF: the skill plays straight away, no cut-in")


func _test_settings() -> void:
	_log("\n== CI: the Settings toggle ==")
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	GameSettings.skill_cut_ins = true
	# Home screens: the ⚙ button.
	var layer := CanvasLayer.new()
	layer.layer = 70
	add_child(layer)
	var home := HomePage.new()
	home._setup_page("PLAY")
	home._build_bars()
	layer.add_child(home)
	await _frames(2)
	home.open_settings()
	await _frames(2)
	var b: Button = home.cut_in_button
	var on_text := b.text
	await _shot("s5_settings_home")
	await _click(b)
	var saved := FileAccess.get_file_as_string(SETTINGS_PATH)
	_check(on_text == "SKILL CUT-INS: ON" and b.text == "SKILL CUT-INS: OFF" and not GameSettings.skill_cut_ins and saved.contains("false"),
		"home ⚙ Settings: SKILL CUT-INS ON -> tap -> OFF, saved to the settings file (%s)" % saved)
	GameSettings.skill_cut_ins = true
	GameSettings.load_settings()
	_check(not GameSettings.skill_cut_ins, "the setting is loaded back from the file next time (a New Game keeps it: it isn't in the save)")
	layer.queue_free()
	await _frames(2)
	# Battle MENU: the same toggle mid-fight.
	await _setup([_hero("friend_jake")], _dummy(99999, 10))
	battle.has_home = true
	battle.menu_button.visible = true
	var opened: bool = battle.open_leave_dialog()
	await _frames(2)
	var mb: Button = battle.cut_in_toggle
	var was := mb.text
	await _shot("s5_settings_battle_menu")
	await _click(mb)
	_check(opened and was == "SKILL CUT-INS: OFF" and mb.text == "SKILL CUT-INS: ON" and GameSettings.skill_cut_ins, "battle MENU: the same SKILL CUT-INS toggle (OFF -> ON) next to Leave this fight")
	battle.close_leave_dialog()
	battle.has_home = false
	battle.menu_button.visible = false
	GameSettings.skill_cut_ins = false
	await _frames(2)


func _test_friend_plates() -> void:
	_log("\n== FD: the friends in a fight ==")
	await _setup([_hero("friend_jake"), _hero("friend_johnny"), _hero("friend_khoel"), _hero("friend_logan")], _dummy(99999, 10))
	await _frames(3)
	var heads := true
	for v in battle.team_views:
		var f = v.figure
		heads = heads and f is ArtFigure and f.head_size > 0.0 and f.sprite.texture is AtlasTexture
	_check(heads, "all 4 friends get head-only party plates cropped from their art")
	await _shot("s5_friend_plates")


# ================================================================ helpers

func _act_turns(act: ActData, members: Array) -> Array:
	var total := 0
	var ok := true
	for f in act.fights:
		var team := BalanceSim.leveled_team(members, f.expected_level)
		var foes := _neutral(f.enemies)
		total += BalanceSim.turns_to_win(foes, team, "GOOD")
		ok = ok and BalanceSim.avg_survives(foes, team, "GOOD" if f.enemies[0].armored else "AVERAGE")
	return [total, ok]


func _neutral(enemies: Array) -> Array:
	var o := []
	for d in enemies:
		var c: FighterData = d.duplicate()
		c.element = T.NONE
		o.append(c)
	return o


func _hero(id: String, unlocked := 0) -> FighterData:
	var c: FighterData = Catalog.template(id).duplicate()
	c.passives_unlocked = unlocked
	return c


func _g(type: int, n: int) -> Dictionary:
	return BalanceSim.group(type, n)


func _typed(list: Array) -> Array[FighterData]:
	var out: Array[FighterData] = []
	for d in list:
		out.append(d)
	return out


func _dummy(hp: int, atk: int, count := 1, armored := false) -> FightData:
	var f := FightData.new()
	f.display_name = "FRIENDS TEST"
	for k in count:
		var d := FighterData.new()
		d.display_name = "TEST DUMMY"
		d.element = T.NONE
		d.role = FighterData.Role.ENEMY
		d.max_hp = hp
		d.atk = atk
		d.armored = armored
		d.body_color = Color(0.4, 0.4, 0.45)
		d.figure_height = 280.0
		d.figure_width = 240.0
		f.enemies.append(d)
	return f


func _setup(members: Array, fight: FightData) -> void:
	battle.set_team(members)
	battle.test_fight_override = fight
	battle._start_battle(0, battle.StartMode.NEW_ACT)
	await _frames(3)
	texts.clear()
	battle.team.skill_turns[0] = 0
	battle._refresh_team_ui()


## Use hunter i's skill (straight call, like the USE button) and wait until it's done.
func _use(i: int, shot_name: String) -> void:
	battle.team.skill_turns[i] = 0
	battle.use_skill(i)
	if shot_name != "":
		await get_tree().create_timer(0.42).timeout
		await _shot("s5_skill_" + shot_name)
	await _wait_skill()


func _wait_skill() -> void:
	var t := 0.0
	await _frames(1)
	while battle._busy and t < 8.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	await _frames(2)


func _no_match_turn() -> void:
	_set_board(BASE)
	await _tap(Vector2i(5, 0))
	await _await_turn_end()


func _count(type: int) -> int:
	var n := 0
	for x in Board.COLS:
		for y in Board.ROWS:
			if (battle.board.grid[x][y] as Orb).orb_type == type:
				n += 1
	return n


func _hps() -> Array:
	var out := []
	for e in battle.enemies:
		out.append(e.hp)
	return out


func _set_board(rows: Array) -> void:
	var map := {"F": T.FIRE, "W": T.WATER, "G": T.WOOD, "L": T.LIGHT, "D": T.DARK, "H": T.HEART}
	for y in Board.ROWS:
		for x in Board.COLS:
			(battle.board.grid[x][y] as Orb).setup(map[rows[y][x]])


func _tap(c: Vector2i) -> void:
	var p: Vector2 = battle.board.get_global_transform_with_canvas() * battle.board.cell_center(c)
	_press(p)
	await _frames(1)
	_release(p)
	await _frames(1)


func _click(b: Button) -> void:
	var p := b.get_global_rect().get_center()
	_press(p)
	await _frames(1)
	_release(p)
	await _frames(2)


func _await_turn_end() -> void:
	var t := 0.0
	await _frames(1)
	while t < 30.0:
		if (battle.board.state == Board.State.READY and battle._player_turn) or battle.result_panel.visible:
			return
		await get_tree().process_frame
		t += get_process_delta_time()
	_check(false, "turn did not finish within 30 s")


func _press(p: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	e.position = p
	e.global_position = p
	get_viewport().push_input(e, true)


func _release(p: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = false
	e.position = p
	e.global_position = p
	get_viewport().push_input(e, true)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	if not screenshots:
		return
	await _frames(1)
	if not DisplayServer.window_can_draw():
		RenderingServer.force_draw(false)
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		return
	img.save_png(ProjectSettings.globalize_path("res://tests/screenshots/%s.png" % shot_name))


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	_log(("PASS  " if ok else "FAIL  ") + what)


func _log(text: String) -> void:
	print(text)
	lines.append(text)


func _finish() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	_log("\n%s — %d failure(s)" % ["ALL PASSED" if fails == 0 else "SOME FAILED", fails])
	var f := FileAccess.open(ProjectSettings.globalize_path("res://tests/report_friends.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	get_tree().quit(fails)
