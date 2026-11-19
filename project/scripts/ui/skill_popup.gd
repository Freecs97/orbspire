class_name SkillPopup
extends Control
## The pop-up you get when you tap a hunter's head plate in combat. READ-ONLY.
##
## Plain English: the hunter's name, HP / ATK / RCV, active skill (cooldown, what
## it does, READY), leader skill (only slot 1 leads: ACTIVE), evolution stage, and
## 3 buttons:
##   USE      - the skill (greyed out until READY). Never ends your turn.
##   DETAILS  - the full detail screen (art, every skill and passive in full words)
##   CLOSE
## No REPLACE / SWAP / team changes in combat: that is a Roster / Team job.
##
## Tap-bug fix (a tap used to open it and close it at once):
##   1. the plates open it on RELEASE, not press,
##   2. for 0.2 s after opening it ignores every tap,
##   3. its buttons sit over the board, never over the head plates,
##   4. only CLOSE or a tap on the dark area OUTSIDE the box closes it; a tap inside
##      the box does nothing.

signal use_pressed(member_index: int)
signal details_pressed(member_index: int)
## Emitted whenever the pop-up goes away (any button).
signal closed

const LOCKOUT := 0.2
## Where the box sits (in the 1080 x 1920 layout): over the board, below the plates.
const BOX_TOP := 1080.0

var member_index := -1
var _panel: PanelContainer
var _title: Label
var _body: VBoxContainer
var use_button: Button
var details_button: Button
var close_button: Button
var _opened_at := -10.0


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
	_panel.position = Vector2(40, BOX_TOP)
	_panel.custom_minimum_size = Vector2(1000, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP   # taps inside the box never close it
	var box := StyleBoxFlat.new()
	box.bg_color = Color("161a30")
	box.set_corner_radius_all(32)
	box.set_border_width_all(4)
	box.border_color = Color("6b5fd8")
	box.content_margin_left = 36
	box.content_margin_right = 36
	box.content_margin_top = 30
	box.content_margin_bottom = 30
	_panel.add_theme_stylebox_override("panel", box)
	content.add_child(_panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(col)
	_title = _label(50, Color.WHITE)
	col.add_child(_title)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_body)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 22)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(buttons)
	use_button = _button("USE", Color("2fae6a"))
	use_button.pressed.connect(func() -> void:
		if _locked():
			return
		visible = false
		use_pressed.emit(member_index))
	buttons.add_child(use_button)
	details_button = _button("DETAILS", Color("3d6fb8"))
	# The detail screen opens first, THEN this hides (so the board stays locked under it).
	details_button.pressed.connect(func() -> void:
		if _locked():
			return
		details_pressed.emit(member_index)
		visible = false)
	buttons.add_child(details_button)
	close_button = _button("CLOSE", Color("4a4f72"))
	close_button.pressed.connect(func() -> void:
		if not _locked():
			visible = false)
	buttons.add_child(close_button)


## Show hunter `index`. turns_left = turns until the skill is ready (0 = ready).
func open(index: int, data: FighterData, is_leader: bool, turns_left: int, can_use_now: bool) -> void:
	member_index = index
	var c := Element.color(data.element)
	_title.text = data.display_name + ("  ·  LEADER" if is_leader else "")
	_title.label_settings.font_color = c.lightened(0.35)
	for child in _body.get_children():
		child.queue_free()
	var stage := maxi(data.stage, 1)
	var aff := Element.display_name(data.element)
	if data.sub_element >= 0:
		aff += " + %s (dual)" % Element.display_name(data.sub_element)
	_text("%s   ·   %s   ·   Evolution Stage %d/3" % [data.title if data.title != "" else Element.display_name(data.element), aff, stage], Color("c9c2ff"))
	_text("HP %d     ATK %d     RCV %d" % [data.max_hp, data.atk, data.rcv], Color.WHITE)
	var cd := data.skill_cooldown()
	var ready := turns_left <= 0
	_text("SKILL: %s  ·  cooldown %d  ·  %s" % [Skills.display_name(data.active_skill).to_upper(), cd,
		"READY!" if ready else "ready in %d turn%s" % [turns_left, "" if turns_left == 1 else "s"]],
		Color("6dff8a") if ready else Color("ffd23f"))
	_text(Skills.describe(data.active_skill), Color(0.85, 0.85, 0.95))
	if data.leader_skill != &"":
		_text("LEADER: %s  ·  %s" % [Skills.display_name(data.leader_skill).to_upper(), "ACTIVE (slot 1)" if is_leader else "only works in slot 1"],
			Color("ffd23f") if is_leader else Color(0.65, 0.65, 0.75))
	use_button.disabled = not (ready and can_use_now)
	use_button.modulate = Color.WHITE if not use_button.disabled else Color(1, 1, 1, 0.4)
	_opened_at = Time.get_ticks_msec() / 1000.0
	visible = true


## True for 0.2 s after opening: the tap that opened it can't also press anything.
func _locked() -> bool:
	return Time.get_ticks_msec() / 1000.0 - _opened_at < LOCKOUT


## Taps on the dark area outside the box close it (on release, after the lockout).
func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT or mb.pressed:
		return
	accept_event()
	if _locked():
		return
	if not _panel.get_global_rect().has_point(mb.global_position):
		visible = false


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
	label.custom_minimum_size = Vector2(920, 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(290, 112)
	b.add_theme_font_size_override("font_size", 42)
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
