class_name StoryBeat
extends Control
## A short story moment on top of the screen. Always skippable.
##
## Plain English:
##   play(lines, seconds)          -> a panel with 1-2 lines; closes by itself
##                                    after `seconds`, or when you tap / press SKIP.
##   play(lines, 0, "", true)      -> a full-screen page (the Introduction);
##                                    waits for a tap ("Tap to continue").
## Callers do:  await beat.play(...)   (the game waits until it closes).

signal finished

var _content: Control
var _box: StyleBoxFlat
var _dim: ColorRect
var _panel: PanelContainer
var _speaker: Label
var _text: Label
var _hint: Label
var _timer_bar: ColorRect
var _skip: Button
var _time_left := 0.0
var _duration := 0.0
var _open := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_CENTER)
	_content.offset_left = -540
	_content.offset_right = 540
	_content.offset_top = -960
	_content.offset_bottom = 960
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)

	_panel = PanelContainer.new()
	_box = StyleBoxFlat.new()
	_box.bg_color = Color("1a1a22")
	_box.set_corner_radius_all(28)
	_box.set_border_width_all(3)
	_box.border_color = Color("4fd8ff")
	_box.shadow_color = Color(0.3, 0.85, 1.0, 0.25)
	_box.shadow_size = 18
	_box.content_margin_left = 44
	_box.content_margin_right = 44
	_box.content_margin_top = 36
	_box.content_margin_bottom = 44
	_panel.add_theme_stylebox_override("panel", _box)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(col)
	_speaker = _label(34, Color("ffd23f"))
	col.add_child(_speaker)
	_text = _label(44, Color.WHITE)
	col.add_child(_text)

	_timer_bar = ColorRect.new()
	_timer_bar.color = Color("4fd8ff")
	_timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_timer_bar)

	_hint = _label(30, Color("a9a3c9"))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_hint)

	_skip = Button.new()
	_skip.text = "SKIP  ▶"
	_skip.add_theme_font_size_override("font_size", 34)
	for s in ["font_color", "font_hover_color", "font_pressed_color"]:
		_skip.add_theme_color_override(s, Color.WHITE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("1a1a22")
	sb.set_corner_radius_all(22)
	sb.set_border_width_all(2)
	sb.border_color = Color("4fd8ff")
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	for s in ["normal", "hover", "pressed"]:
		_skip.add_theme_stylebox_override(s, sb)
	_skip.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_skip.position = Vector2(820, 70)
	_skip.pressed.connect(close)
	_content.add_child(_skip)


## Show the beat and wait. seconds <= 0 = wait for a tap.
func play(lines: Array, seconds: float, speaker := "", full := false) -> void:
	_speaker.text = speaker
	_speaker.visible = speaker != ""
	_text.text = "\n".join(PackedStringArray(lines))
	_duration = seconds
	_time_left = seconds
	_dim.color = Color(0.01, 0.01, 0.04, 0.96 if full else 0.6)
	# The Introduction keeps every sentence on its own line, so it uses smaller,
	# wider text than the in-battle beats.
	_text.label_settings.font_size = 31 if full else 44
	_text.custom_minimum_size = Vector2(1030 if full else 890, 0)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if full else HORIZONTAL_ALIGNMENT_LEFT
	_panel.custom_minimum_size = Vector2(1060 if full else 980, 0)
	_panel.position = Vector2(10 if full else 50, 330 if full else 640)
	# The full-screen Introduction has no box around the text; beats do.
	_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new() if full else _box)
	_hint.text = "Tap to continue" if seconds <= 0.0 else "Tap to skip"
	_hint.size = Vector2(1080, 50)
	_hint.position = Vector2(0, 1640 if full else 1200)
	_timer_bar.visible = seconds > 0.0
	_timer_bar.position = Vector2(80, 1180)
	_timer_bar.size = Vector2(920, 6)
	visible = true
	_open = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	await finished


## Close now (tap, SKIP, or time up).
func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	finished.emit()


func is_open() -> bool:
	return _open


func shown_text() -> String:
	return _text.text


func _process(delta: float) -> void:
	if not _open:
		return
	_hint.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 300.0)
	if _duration > 0.0:
		_time_left -= delta
		_timer_bar.size.x = 920.0 * maxf(_time_left, 0.0) / _duration
		if _time_left <= 0.0:
			close()


func _gui_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press and press.pressed and press.button_index == MOUSE_BUTTON_LEFT and _open:
		accept_event()
		close()


func _label(font_size: int, color: Color) -> Label:
	var l := Label.new()
	var s := LabelSettings.new()
	s.font_size = font_size
	s.font_color = color
	s.outline_size = 6
	s.outline_color = Color(0.02, 0.01, 0.06)
	s.line_spacing = 10
	l.label_settings = s
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(890, 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
