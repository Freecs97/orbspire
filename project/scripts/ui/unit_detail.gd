class_name UnitDetail
extends Control
## Stage 5B: the full character detail screen. Opened from the Roster, from
## DETAILS on the Team screen, and from DETAILS in battle.
##
## Plain English, top to bottom (it scrolls):
##   - name, what it is, the FULL art (not cropped), rarity stars ★1 Scrap ... ★6 Singularity
##   - stats: HP / ATK / RCV, level, XP to the next level, rarity, affinity, archetype
##   - evolution 1/3, 2/3, 3/3 with the current stage highlighted, what the next
##     evolution needs (level + Credits + Cores) and what it gives
##   - the active skill, leader skill and 3 passives in full words
##   - Essence progress (or how this character is found)
##   - buttons: USE CORE, EVOLVE, LOCK, RETIRE (asks twice), CLOSE.
##     Mid-fight (from battle) training and evolving are hidden: do those from the Roster.

signal changed            ## the unit changed (core, evolve, lock, retire): save
signal closed
signal message(text: String)   ## a short note for the page's toast

const GOLD := Color("ffd23f")
const SOFT := Color("c9c2ff")
const DIM_TEXT := Color("8a85a8")
const ROLE_WORDS := ["Berserker", "Titan", "Spectre", "Biotech"]
const ART_SIZE := 620.0

var profile: Profile
var uid := -1
var in_battle := false
var fighter: FighterData          ## what is shown (with the unit's level, rarity, stage)

var content: Control
var scroll: ScrollContainer
var column: VBoxContainer
var name_label: Label
var title_label: Label
var art_frame: Panel
var art_rect: TextureRect
var stars: StarRow
var rarity_label: Label
var stats_label: Label
var level_label: Label
var xp_bar: ColorRect
var xp_fill: ColorRect
var xp_label: Label
var evo_label: Label              ## "EVOLUTION: Stage 1/3"
var evo_boxes: Array[Panel] = []
var evo_next_label: Label
var active_label: Label
var leader_label: Label
var passive_labels: Array[Label] = []
var essence_label: Label
var note_label: Label
var use_core_button: Button
var evolve_button: Button
var lock_button: Button
var retire_button: Button
var close_button: Button
var _retire_armed := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 1.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	content = Control.new()
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.offset_left = -540
	content.offset_right = 540
	content.offset_top = -960
	content.offset_bottom = 960
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	scroll = ScrollContainer.new()
	scroll.position = Vector2(0, 16)
	scroll.size = Vector2(1080, 1540)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	column = VBoxContainer.new()
	column.custom_minimum_size = Vector2(1080, 0)
	column.add_theme_constant_override("separation", 16)
	scroll.add_child(column)
	_build_column()
	# Buttons stay at the bottom (they don't scroll away).
	var bar := ColorRect.new()
	bar.color = Color(0.03, 0.03, 0.07, 0.96)
	bar.position = Vector2(0, 1566)
	bar.size = Vector2(1080, 354)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(bar)
	note_label = _label(24, DIM_TEXT, content)
	note_label.position = Vector2(30, 1572)
	note_label.size = Vector2(1020, 34)
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	use_core_button = _button("USE CORE", Vector2(30, 1612), Vector2(320, 120), 24, MenuStyle.NEON)
	use_core_button.pressed.connect(_on_use_core)
	evolve_button = _button("EVOLVE", Vector2(380, 1612), Vector2(320, 120), 24, GOLD)
	evolve_button.pressed.connect(_on_evolve)
	lock_button = _button("LOCK", Vector2(730, 1612), Vector2(320, 120), 28, MenuStyle.NEON)
	lock_button.pressed.connect(_on_lock)
	retire_button = _button("RETIRE", Vector2(30, 1756), Vector2(500, 120), 26, Color("ff5a5a"))
	retire_button.pressed.connect(_on_retire)
	close_button = _button("CLOSE", Vector2(550, 1756), Vector2(500, 120), 34, MenuStyle.NEON)
	close_button.pressed.connect(close)


func _build_column() -> void:
	name_label = _label(64, Color.WHITE, column)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label = _label(30, SOFT, column)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Full art, large and centred, in a frame of its rarity colour.
	var art_holder := Control.new()
	art_holder.custom_minimum_size = Vector2(1080, ART_SIZE + 40)
	art_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(art_holder)
	art_frame = Panel.new()
	art_frame.position = Vector2((1080 - ART_SIZE - 40) * 0.5, 0)
	art_frame.size = Vector2(ART_SIZE + 40, ART_SIZE + 40)
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_holder.add_child(art_frame)
	art_rect = TextureRect.new()
	art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_rect.position = art_frame.position + Vector2(20, 20)
	art_rect.size = Vector2(ART_SIZE, ART_SIZE)
	art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_holder.add_child(art_rect)
	# Rarity stars.
	var star_holder := Control.new()
	star_holder.custom_minimum_size = Vector2(1080, 50)
	star_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(star_holder)
	stars = StarRow.new()
	stars.position = Vector2((1080 - stars.size.x) * 0.5, 0)
	star_holder.add_child(stars)
	rarity_label = _label(32, GOLD, column)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Stats.
	_heading("STATS")
	stats_label = _label(46, Color.WHITE, column)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label = _label(30, Color.WHITE, column)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bar_holder := Control.new()
	bar_holder.custom_minimum_size = Vector2(1080, 44)
	bar_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(bar_holder)
	xp_bar = ColorRect.new()
	xp_bar.color = Color("24243a")
	xp_bar.position = Vector2(140, 4)
	xp_bar.size = Vector2(800, 34)
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_holder.add_child(xp_bar)
	xp_fill = ColorRect.new()
	xp_fill.color = Color("4fd8ff")
	xp_fill.position = xp_bar.position
	xp_fill.size = Vector2(0, 34)
	xp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_holder.add_child(xp_fill)
	xp_label = _label(24, Color.WHITE, bar_holder)
	xp_label.position = xp_bar.position
	xp_label.size = xp_bar.size
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Evolution 1/3 - 2/3 - 3/3.
	evo_label = _heading("EVOLUTION")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	for s in 3:
		var box := Panel.new()
		box.custom_minimum_size = Vector2(300, 330)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(box)
		var pic := TextureRect.new()
		pic.name = "Pic"
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.position = Vector2(20, 12)
		pic.size = Vector2(260, 230)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(pic)
		var l := _label(28, Color.WHITE, box)
		l.name = "Text"
		l.position = Vector2(0, 246)
		l.size = Vector2(300, 80)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		evo_boxes.append(box)
	evo_next_label = _para(28, Color.WHITE)
	# Skills in full words.
	_heading("ACTIVE SKILL")
	active_label = _para(30, Color.WHITE)
	_heading("LEADER SKILL")
	leader_label = _para(30, Color.WHITE)
	_heading("PASSIVES")
	for k in 3:
		passive_labels.append(_para(28, Color.WHITE))
	_heading("ESSENCE")
	essence_label = _para(28, Color.WHITE)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1080, 30)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)


# ---------------------------------------------------------------- open

## An owned unit (Roster / Team / battle with a save). battle_mode hides
## USE CORE and EVOLVE (you train and evolve from the Roster, not mid-fight).
func open_unit(p: Profile, unit_uid: int, battle_mode := false) -> void:
	profile = p
	uid = unit_uid
	in_battle = battle_mode
	_retire_armed = false
	fighter = p.fighter(unit_uid)
	_fill(p.unit(unit_uid))
	scroll.scroll_vertical = 0
	visible = true


## A fighter with no save behind it (test fights): its card only, no buttons but CLOSE.
func open_fighter(f: FighterData, level := 1) -> void:
	profile = null
	uid = -1
	in_battle = true
	fighter = f
	_fill({"id": f.design_id, "level": level, "xp": 0, "rarity": f.rarity if f.rarity >= 0 else maxi(f.fixed_rarity, Profile.ECONOMY.story_rarity),
		"stage": f.stage, "locked": false, "cores": 0})
	scroll.scroll_vertical = 0
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func _fill(u: Dictionary) -> void:
	var f := fighter
	var e := Profile.ECONOMY
	var p := Profile.PROGRESSION
	var c := Element.color(f.element)
	var rarity := int(u.get("rarity", 0))
	var stage := int(u.get("stage", f.stage))
	var level := int(u.get("level", 1))
	var rc := Catalog.rarity_color(rarity)
	name_label.text = f.display_name
	name_label.label_settings.font_color = c.lightened(0.35)
	title_label.text = "%s  ·  Stage %d/3%s" % [f.title if f.title != "" else ROLE_WORDS[f.role], stage, "  ·  LOCKED" if u.get("locked", false) else ""]
	# Full art in a rarity-coloured frame.
	art_rect.texture = f.art
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("101019")
	sb.set_corner_radius_all(28)
	sb.set_border_width_all(5)
	sb.border_color = rc
	sb.shadow_color = Color(rc, 0.45)
	sb.shadow_size = 22 if rarity >= 3 else 8
	art_frame.add_theme_stylebox_override("panel", sb)
	stars.set_stars(rarity + 1, rc.lightened(0.15))
	rarity_label.text = "RARITY %d / 6  ·  %s" % [rarity + 1, Catalog.rarity_name(rarity).to_upper()]
	rarity_label.label_settings.font_color = rc.lightened(0.2)
	# Stats.
	stats_label.text = "HP %d     ATK %d     RCV %d" % [f.max_hp, f.atk, f.rcv]
	var cap := p.level_cap(stage)
	var aff := Element.display_name(f.element).capitalize()
	var dual := Catalog.dual_of(String(u.get("id", "")))
	if f.sub_element >= 0:
		aff += " + %s (dual)" % Element.display_name(f.sub_element).capitalize()
	elif dual >= 0:
		aff += " (+ %s at Stage 3)" % Element.display_name(dual).capitalize()
	level_label.text = "LEVEL %d  (Stage %d cap: Lv%d)\nAFFINITY  %s   ·   ARCHETYPE  %s   ·   RARITY  %s" % [level, stage, cap,
		aff, ROLE_WORDS[f.role] if f.role < 4 else "Enemy", Catalog.rarity_name(rarity)]
	if profile:
		cap = profile.level_cap(u)   # the galaxy cap too (Galaxy 1 = Lv30)
	var ratio := 1.0
	if profile == null:
		xp_label.text = "Test fight: no save"
		ratio = 0.0
	elif level >= cap:
		if cap >= p.max_level:
			xp_label.text = "MAX LEVEL"
		elif profile.at_galaxy_cap(u):
			xp_label.text = "Lv%d: galaxy cap (a farther galaxy lets you level on)" % cap
		elif stage >= p.built_stages:
			xp_label.text = "Lv%d: top level for now (Stage 4 evolution comes later)" % cap
		else:
			xp_label.text = "Lv%d CAP: evolve to level further" % cap
	else:
		var need := p.xp_to_next(level)
		ratio = clampf(float(u["xp"]) / maxi(need, 1), 0.0, 1.0)
		xp_label.text = "XP %d / %d  ·  %d to Lv%d" % [u["xp"], need, need - int(u["xp"]), level + 1]
	xp_fill.size.x = xp_bar.size.x * ratio
	# Evolution.
	var id: String = u.get("id", "")
	evo_label.text = "EVOLUTION: Stage %d/3" % stage
	for s in 3:
		var box := evo_boxes[s]
		var now := s + 1 == stage
		var reached := s + 1 <= stage
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color("191926") if now else Color("111119")
		bs.set_corner_radius_all(20)
		bs.set_border_width_all(5 if now else 2)
		bs.border_color = GOLD if now else (c.darkened(0.2) if reached else Color("33334a"))
		bs.shadow_color = Color(GOLD, 0.45 if now else 0.0)
		bs.shadow_size = 16 if now else 0
		box.add_theme_stylebox_override("panel", bs)
		var pic: TextureRect = box.get_node("Pic")
		pic.texture = Catalog.art(id, s + 1) if id != "" and Catalog.all_ids().has(id) else f.art
		pic.modulate = Color.WHITE if reached else Color(0.35, 0.35, 0.42)
		var t: Label = box.get_node("Text")
		t.text = "STAGE %d\n%d/3%s" % [s + 1, s + 1, "  ·  NOW" if now else ""]
		t.label_settings.font_color = GOLD if now else (Color.WHITE if reached else DIM_TEXT)
	var cd := f.skill_cooldown()
	if stage >= 3:
		evo_next_label.text = "Fully evolved (3/3): every passive is unlocked and the skill cooldown is %d turns." % cd
	else:
		var have_cr: int = profile.data["credits"] if profile else 0
		var have_co: int = profile.data["cores"] if profile else 0
		var next_passive := f.passives[stage] if stage < f.passives.size() else &""
		evo_next_label.text = "NEXT: Stage %d needs Lv%d (now Lv%d), %d Credits (you have %d) and %d Training Cores (you have %d).\nIT GIVES: +%d%% HP / ATK / RCV, skill cooldown -1 (%d -> %d turns), and unlocks Passive %d: %s." % [
			stage + 1, cap, level, e.evo_credits[stage - 1], have_cr, e.evo_cores[stage - 1], have_co,
			roundi(e.evo_stat_bonus * 100), cd, maxi(cd - 1, 1), stage + 1, Skills.display_name(next_passive)]
	# Skills in full words.
	var base_cd := Skills.cooldown(f.active_skill)
	active_label.text = "%s  ·  cooldown %d turns%s\n%s\nCharges 1 turn on every turn you make a match. Using it never ends your turn." % [
		Skills.display_name(f.active_skill).to_upper(), cd, "  (%d, -%d from evolving)" % [base_cd, base_cd - cd] if cd < base_cd else "",
		Skills.describe(f.active_skill, f.element)]
	var leads: bool = profile != null and not profile.data["team"].is_empty() and profile.data["team"][0] == uid
	leader_label.text = "%s\n%s\nOnly the hunter in team slot 1 is the leader, and leader skills never stack.%s" % [
		Skills.display_name(f.leader_skill).to_upper(), Skills.describe(f.leader_skill, f.element),
		"\nThis hunter leads your team right now." if leads else ""]
	for k in passive_labels.size():
		var l := passive_labels[k]
		if k >= f.passives.size():
			l.text = ""
			continue
		var pid: StringName = f.passives[k]
		var unlocked := k < f.passives_unlocked
		l.text = "%d. %s  ·  unlocks at %s  ·  %s\n%s" % [k + 1, Skills.display_name(pid).to_upper(), Skills.UNLOCK_TEXT[k],
			"UNLOCKED" if unlocked else "LOCKED", Skills.describe(pid, f.element)]
		l.label_settings.font_color = Color.WHITE if unlocked else DIM_TEXT
	# Essence (or how this one is found).
	if Catalog.is_friend(id):
		essence_label.text = "Ultra-rare: friends only join after a won fight (0.25%% chance). No Essence."
	elif Catalog.lab_ids().has(id):
		var have := int(profile.data["essence"].get(id, 0)) if profile else 0
		essence_label.text = "%s Essence: %d / %d. At %d you can craft another one in the Lab." % [f.display_name, have, e.essence_to_craft, e.essence_to_craft]
	elif Catalog.is_colour_version(id):
		essence_label.text = "A colour version: found through Recruit and fight drops. No Essence."
	else:
		essence_label.text = "No Essence for this one."
	essence_label.text += "\nTraining Cores used on it: %d." % int(u.get("cores", 0))
	_refresh_buttons(u)


func _refresh_buttons(u: Dictionary) -> void:
	var e := Profile.ECONOMY
	var has_save := profile != null
	use_core_button.visible = has_save and not in_battle
	evolve_button.visible = has_save and not in_battle
	# In combat this screen is READ-ONLY: no training, evolving, locking or retiring.
	lock_button.visible = has_save and not in_battle
	retire_button.visible = has_save and not in_battle
	note_label.text = "Read-only in combat. Train, evolve and change the team from the Roster." if has_save and in_battle else ("" if has_save else "Test fight: no save to change.")
	if not has_save:
		return
	var stage := int(u["stage"])
	var cap := profile.level_cap(u)
	use_core_button.text = "USE CORE\n+%d XP (have %d)" % [e.core_xp, profile.data["cores"]]
	use_core_button.disabled = profile.data["cores"] <= 0 or u["level"] >= cap
	var why_not := profile.can_evolve(uid)
	evolve_button.disabled = why_not != ""
	evolve_button.text = ("EVOLVE to Stage %d\n%d Cr + %d Cores" % [stage + 1, e.evo_credits[stage - 1], e.evo_cores[stage - 1]]) if why_not == "" else ("EVOLVE\n" + why_not if stage < 3 else "STAGE 3/3\nfully evolved")
	lock_button.text = "UNLOCK" if u["locked"] else "LOCK"
	var why := profile.retire_check(uid)
	retire_button.disabled = why != ""
	retire_button.text = "RETIRE  (+%d Cores)" % profile.retire_value(uid) if why == "" else "RETIRE\n" + why


# ---------------------------------------------------------------- buttons

func _reopen() -> void:
	var y := scroll.scroll_vertical
	open_unit(profile, uid, in_battle)
	scroll.scroll_vertical = y


func _on_use_core() -> void:
	if profile and profile.use_core(uid):
		changed.emit()
		_reopen()


func _on_evolve() -> void:
	if profile == null:
		return
	var before := profile.fighter(uid)
	if not profile.evolve(uid):
		return
	var after := profile.fighter(uid)
	message.emit("%s evolved to Stage %d!  HP %d -> %d, ATK %d -> %d" % [after.display_name, after.stage, before.max_hp, after.max_hp, before.atk, after.atk])
	changed.emit()
	_reopen()
	art_rect.modulate = Color(2.2, 2.2, 2.2)
	create_tween().tween_property(art_rect, "modulate", Color.WHITE, 0.6)


func _on_lock() -> void:
	if profile == null:
		return
	profile.toggle_lock(uid)
	changed.emit()
	_reopen()


## Retire asks twice: the first tap arms it, the second tap retires.
func _on_retire() -> void:
	if profile == null:
		return
	if not _retire_armed:
		_retire_armed = true
		retire_button.text = "SURE? TAP AGAIN TO RETIRE"
		return
	var gained := profile.retire(uid)
	if gained >= 0:
		message.emit("Retired: +%d Training Cores" % gained)
		changed.emit()
		close()


# ---------------------------------------------------------------- helpers

func _heading(text: String) -> Label:
	var l := _label(34, GOLD, column)
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _para(font_size: int, color: Color) -> Label:
	var l := _label(font_size, color, column)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(960, 0)
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return l


func _label(font_size: int, color: Color, parent: Node) -> Label:
	var l := Label.new()
	var s := LabelSettings.new()
	s.font_size = font_size
	s.font_color = color
	s.outline_size = 6
	s.outline_color = Color(0.02, 0.01, 0.06)
	l.label_settings = s
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _button(text: String, pos: Vector2, sz: Vector2, font: int, neon: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	b.focus_mode = Control.FOCUS_NONE
	MenuStyle.apply(b, font, neon)
	content.add_child(b)
	return b
