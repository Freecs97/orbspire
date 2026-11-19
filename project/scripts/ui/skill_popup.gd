class_name SkillPopup
extends Control
## The pop-up you get when you tap a hunter's card.
##
## Plain English: a small tooltip with the hunter's name, HP / ATK / RCV and
## active skill name + charge, and 4 buttons:
##   USE      - the skill (only when charged). Never ends your turn.
##   REPLACE  - Stage 5A: swap this hunter for one from your Roster
##   DETAILS  - Stage 5B: the full detail screen (every skill in full words)
##   CLOSE

signal use_pressed(member_index: int)
signal replace_pressed(member_index: int)
signal details_pressed(member_index: int)
## Emitted whenever the pop-up goes away (any button).
signal closed

var member_index := -1
var _panel: PanelContainer
var _title: Label
var _body: VBoxContainer
var use_button: Button
var replace_button: Button
var details_button: Button
var close_button: Button


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	visibility_changed.connect(func() -> void:
		if not visible:
			closed.emit())

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.06, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var content := Control.new()
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.offset_left = -540
	content.offset_right = 540
	content.offset_top = -960
	content.offset_bottom = 960
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

	_panel = PanelContainer.new()
	_panel.position = Vector2(50, 480)
	_panel.custom_minimum_size = Vector2(980, 0)
	var box := StyleBoxFlat.new()
	box.bg_color = Color("161a30")
	box.set_corner_radius_all(32)
	box.set_border_width_all(4)
	box.border_color = Color("6b5fd8")
	box.content_margin_left = 40
	box.content_margin_right = 40
	box.content_margin_top = 34
	box.content_margin_bottom = 34
	_panel.add_theme_stylebox_override("panel", box)
	content.add_child(_panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	_panel.add_child(col)
	_title = _label(54, Color.WHITE)
	col.add_child(_title)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 10)
	col.add_child(_body)

	var buttons := GridContainer.new()
	buttons.columns = 2
	buttons.add_theme_constant_override("h_separation", 30)
	buttons.add_theme_constant_override("v_separation", 22)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(buttons)
	use_button = _button("USE", Color("2fae6a"))
	use_button.pressed.connect(func() -> void:
		visible = false
		use_pressed.emit(member_index))
	buttons.add_child(use_button)
	replace_button = _button("REPLACE", Color("b98a1e"))
	# The next screen opens first, THEN this hides (so the board stays locked under it).
	replace_button.pressed.connect(func() -> void:
		replace_pressed.emit(member_index)
		visible = false)
	buttons.add_child(replace_button)
	details_button = _button("DETAILS", Color("3d6fb8"))
	details_button.pressed.connect(func() -> void:
		details_pressed.emit(member_index)
		visible = false)
	buttons.add_child(details_button)
	close_button = _button("CLOSE", Color("4a4f72"))
	close_button.pressed.connect(func() -> void: visible = false)
	buttons.add_child(close_button)


## Show hunter `index`. turns_left = turns until the skill is ready (0 = ready).
## can_replace = false greys out REPLACE (a test fight with no save behind it).
func open(index: int, data: FighterData, is_leader: bool, turns_left: int, can_use_now: bool, can_replace := true) -> void:
	member_index = index
	var c := Element.color(data.element)
	_title.text = data.display_name + ("  ·  LEADER" if is_leader else "")
	_title.label_settings.font_color = c.lightened(0.35)
	for child in _body.get_children():
		child.queue_free()
	_text("%s   ·   HP %d   ATK %d   RCV %d" % [data.title, data.max_hp, data.atk, data.rcv], Color.WHITE)
	var cd := data.skill_cooldown()
	_section("SKILL: %s  ·  %s" % [Skills.display_name(data.active_skill).to_upper(),
		"READY!" if turns_left <= 0 else "ready in %d turn%s (cooldown %d)" % [turns_left, "" if turns_left == 1 else "s", cd]],
		Color("6dff8a") if turns_left <= 0 else Color("ffd23f"))
	use_button.disabled = not (turns_left <= 0 and can_use_now)
	use_button.modulate = Color.WHITE if not use_button.disabled else Color(1, 1, 1, 0.4)
	replace_button.disabled = not can_replace
	replace_button.modulate = Color.WHITE if can_replace else Color(1, 1, 1, 0.4)
	visible = true


func _section(text: String, color: Color) -> void:
	var l := _label(30, color)
	l.text = text
	_body.add_child(l)


func _text(text: String, color: Color) -> void:
	var l := _label(30, color)
	l.text = text
	_body.add_child(l)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	var s := LabelSettings.new()
	s.font_size = font_size
	s.font_color = color
	s.outline_size = 4
	s.outline_color = Color(0.03, 0.02, 0.06)
	label.label_settings = s
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(900, 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(420, 112)
	b.add_theme_font_size_override("font_size", 44)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(state, Color.WHITE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(30)
	sb.border_width_bottom = 8
	sb.border_color = color.darkened(0.45)
	for state in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b
