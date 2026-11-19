class_name RosterScreen
extends HomePage
## ROSTER: every character you own, plus the LAB (Digital Essence).
##
## Plain English:
##   - Tap a character for its details: level + XP, stats, skills, and buttons to
##     use a Training Core (+XP), lock it, or retire it (asks twice).
##   - EXPAND buys +5 roster slots with Credits. BUY CORE buys a Training Core.
##   - LAB shows your Essence for all 20 characters (e.g. 7/10). At 10 you can
##     CRAFT that character (Lv1).

signal changed

var profile: Profile
var header: Label
var expand_button: Button
var core_button: Button
var lab_button: Button
var grid: GridContainer
var lab_list: VBoxContainer
var scroll: ScrollContainer
var detail: Control
var detail_card: UnitCard
var detail_text: Label
var use_core_button: Button
var evolve_button: Button
var lock_button: Button
var retire_button: Button
var detail_close: Button
var craft_buttons := {}   ## character id -> CRAFT button
var showing_lab := false
var _detail_uid := -1
var _retire_armed := false


func _init() -> void:
	_setup_page("ROSTER")
	var bg := ColorRect.new()
	bg.color = Color("0b0b14")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	header = make_label(44, Color.WHITE)
	header.position = Vector2(40, 155)
	expand_button = make_button("EXPAND +5", Vector2(40, 230), Vector2(320, 90), 28)
	expand_button.pressed.connect(_on_expand)
	core_button = make_button("BUY CORE", Vector2(380, 230), Vector2(320, 90), 28)
	core_button.pressed.connect(_on_buy_core)
	lab_button = make_button("LAB", Vector2(720, 230), Vector2(320, 90), 30, GOLD)
	lab_button.pressed.connect(func() -> void:
		showing_lab = not showing_lab
		refresh())
	scroll = ScrollContainer.new()
	scroll.position = Vector2(30, 340)
	scroll.size = Vector2(1020, 1380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var holder := VBoxContainer.new()
	scroll.add_child(holder)
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	holder.add_child(grid)
	lab_list = VBoxContainer.new()
	lab_list.add_theme_constant_override("separation", 12)
	holder.add_child(lab_list)
	_build_detail()
	_build_bars()


func refresh() -> void:
	var d := profile.data
	set_bar_values(d["credits"], d["cores"], profile.highest_level())
	var e := Profile.ECONOMY
	header.text = ("LAB  ·  Digital Essence" if showing_lab else "ROSTER  %d / %d" % [d["units"].size(), d["roster_cap"]])
	expand_button.text = "EXPAND +%d  (%d Cr)" % [e.roster_expand_slots, e.roster_expand_cost]
	core_button.text = "BUY CORE  (%d Cr)" % e.core_cost
	lab_button.text = "ROSTER" if showing_lab else "LAB"
	grid.visible = not showing_lab
	lab_list.visible = showing_lab
	for c in grid.get_children():
		c.queue_free()
	for c in lab_list.get_children():
		c.queue_free()
	craft_buttons.clear()
	if showing_lab:
		_fill_lab()
		return
	var units: Array = d["units"].duplicate()
	units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["level"] > b["level"] or (a["level"] == b["level"] and a["rarity"] > b["rarity"]))
	for u in units:
		var c := UnitCard.new()
		c.show_unit(u, false, Vector2(240, 320))
		c.pressed.connect(open_detail.bind(int(u["uid"])))
		grid.add_child(c)


func cards() -> Array:
	return grid.get_children().filter(func(c: Node) -> bool: return not c.is_queued_for_deletion())


func _fill_lab() -> void:
	var e := Profile.ECONOMY
	# Closest to crafting first.
	var ids: Array = Catalog.IDS.duplicate()
	ids.sort_custom(func(a: String, b: String) -> bool: return int(profile.data["essence"].get(a, 0)) > int(profile.data["essence"].get(b, 0)))
	for id in ids:
		var have := int(profile.data["essence"].get(id, 0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		var pic := TextureRect.new()
		pic.texture = Catalog.template(id).art
		pic.custom_minimum_size = Vector2(110, 110)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(pic)
		var l := make_label(30, Color.WHITE, row)
		l.text = "%s  ·  %s\nEssence %d / %d" % [Catalog.display_name(id), Catalog.template(id).title, have, e.essence_to_craft]
		l.custom_minimum_size = Vector2(560, 110)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var b := Button.new()
		b.text = "CRAFT"
		b.custom_minimum_size = Vector2(240, 90)
		MenuStyle.apply(b, 30, GOLD)
		b.disabled = profile.can_craft(id) != ""
		b.pressed.connect(_on_craft.bind(id))
		row.add_child(b)
		craft_buttons[id] = b
		lab_list.add_child(row)


# ---------------------------------------------------------------- detail panel

func _build_detail() -> void:
	detail = Control.new()
	detail.visible = false
	detail.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(detail)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.96)
	dim.size = Vector2(1080, 2600)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_child(dim)
	detail_card = UnitCard.new()
	detail_card.position = Vector2(290, 160)
	detail.add_child(detail_card)
	detail_text = make_label(30, Color.WHITE, detail)
	detail_text.position = Vector2(60, 830)
	detail_text.size = Vector2(960, 520)
	detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	use_core_button = make_button("USE CORE", Vector2(60, 1370), Vector2(300, 100), 24, MenuStyle.NEON, detail)
	use_core_button.pressed.connect(_on_use_core)
	evolve_button = make_button("EVOLVE", Vector2(380, 1370), Vector2(320, 100), 24, GOLD, detail)
	evolve_button.pressed.connect(_on_evolve)
	lock_button = make_button("LOCK", Vector2(720, 1370), Vector2(300, 100), 24, MenuStyle.NEON, detail)
	lock_button.pressed.connect(func() -> void:
		profile.toggle_lock(_detail_uid)
		changed.emit()
		open_detail(_detail_uid))
	retire_button = make_button("RETIRE", Vector2(60, 1490), Vector2(470, 100), 30, Color("ff5a5a"), detail)
	retire_button.pressed.connect(_on_retire)
	detail_close = make_button("CLOSE", Vector2(550, 1490), Vector2(470, 100), 30, MenuStyle.NEON, detail)
	detail_close.pressed.connect(func() -> void:
		detail.visible = false
		refresh())


func open_detail(uid: int) -> void:
	_detail_uid = uid
	_retire_armed = false
	var u := profile.unit(uid)
	var f := profile.fighter(uid)
	var p := Profile.PROGRESSION
	detail_card.show_unit(u, false, Vector2(500, 640))
	var cap := profile.level_cap(u)
	var xp_line := ("Lv%d CAP (Stage %d): evolve to go higher" % [cap, u["stage"]] if cap < p.max_level else "MAX LEVEL") if u["level"] >= cap else "XP %d / %d" % [u["xp"], p.xp_to_next(u["level"])]
	var roles := ["BERSERKER", "TITAN", "SPECTRE", "BIOTECH"]
	var e := Profile.ECONOMY
	var stage := int(u["stage"])
	var passive_lines := PackedStringArray()
	for k in f.passives.size():
		passive_lines.append("Passive %d (%s): %s%s" % [k + 1, Skills.UNLOCK_TEXT[k], Skills.display_name(f.passives[k]), "" if k < f.passives_unlocked else "  (locked)"])
	var evo_line := "EVOLUTION: Stage %d/3" % stage
	if stage < 3:
		evo_line += "  ·  next: Lv%d + %d Credits + %d Cores -> +%d%% stats, cooldown -1, Passive %d" % [
			p.level_cap(stage), e.evo_credits[stage - 1], e.evo_cores[stage - 1], roundi(e.evo_stat_bonus * 100), stage + 1]
	detail_text.text = "%s  ·  %s  ·  %s  ·  Lv%d  ·  %s\nHP %d   ATK %d   RCV %d\n%s\nActive: %s (cooldown %d)\nLeader (slot 1): %s: %s\n%s\nTraining Cores used: %d" % [
		Element.display_name(f.element), roles[f.role], Catalog.rarity_name(u["rarity"]), u["level"], xp_line,
		f.max_hp, f.atk, f.rcv, evo_line, Skills.display_name(f.active_skill), f.skill_cooldown(),
		Skills.display_name(f.leader_skill), Skills.describe(f.leader_skill, f.element), "\n".join(passive_lines), u["cores"]]
	use_core_button.text = "USE CORE\n+%d XP (have %d)" % [e.core_xp, profile.data["cores"]]
	use_core_button.disabled = profile.data["cores"] <= 0 or u["level"] >= cap
	var why_not := profile.can_evolve(_detail_uid)
	evolve_button.disabled = why_not != ""
	evolve_button.text = ("EVOLVE to Stage %d\n%d Cr + %d Cores" % [stage + 1, e.evo_credits[stage - 1], e.evo_cores[stage - 1]]) if why_not == "" else ("EVOLVE\n" + why_not if stage < 3 else "STAGE 3/3\nfully evolved")
	lock_button.text = "UNLOCK" if u["locked"] else "LOCK"
	var why := profile.retire_check(uid)
	retire_button.disabled = why != ""
	retire_button.text = "RETIRE  (+%d Cores)" % profile.retire_value(uid) if why == "" else why
	detail.visible = true


func _on_evolve() -> void:
	var before := profile.fighter(_detail_uid)
	if not profile.evolve(_detail_uid):
		return
	var after := profile.fighter(_detail_uid)
	show_toast("%s evolved to Stage %d!  HP %d -> %d, ATK %d -> %d" % [after.display_name, after.stage, before.max_hp, after.max_hp, before.atk, after.atk])
	changed.emit()
	open_detail(_detail_uid)
	# A little flash on the new art.
	detail_card.modulate = Color(2.2, 2.2, 2.2)
	create_tween().tween_property(detail_card, "modulate", Color.WHITE, 0.6)


func _on_use_core() -> void:
	if profile.use_core(_detail_uid):
		changed.emit()
		open_detail(_detail_uid)


## Retire asks twice: the first tap arms it, the second tap retires.
func _on_retire() -> void:
	if not _retire_armed:
		_retire_armed = true
		retire_button.text = "SURE? TAP AGAIN TO RETIRE"
		return
	var gained := profile.retire(_detail_uid)
	if gained >= 0:
		detail.visible = false
		show_toast("Retired: +%d Training Cores" % gained)
		changed.emit()
		refresh()


func _on_expand() -> void:
	if profile.expand_roster():
		show_toast("Roster expanded")
		changed.emit()
	else:
		show_toast("Not enough Credits")
	refresh()


func _on_buy_core() -> void:
	if profile.buy_core():
		show_toast("+1 Training Core")
		changed.emit()
	else:
		show_toast("Not enough Credits")
	refresh()


func _on_craft(id: String) -> void:
	var uid := profile.craft(id)
	if uid >= 0:
		show_toast("Crafted: %s" % Catalog.display_name(id))
		changed.emit()
	refresh()
