class_name ResultPanel
extends Control
## The WIN / LOSE screen.
##
## WIN  -> "Fight Again" (same fight, full HP) and "Next Fight".
## LOSE -> "Retry" only.

signal retry_pressed
signal next_pressed
signal codex_pressed

var _content: Control
var _title: Label
var _info: Label
var _retry_button: Button
var _next_button: Button
var codex_button: Button


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.06, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	# A 1080 x 1920 box kept in the middle of the screen, whatever its size.
	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_CENTER)
	_content.offset_left = -540
	_content.offset_right = 540
	_content.offset_top = -960
	_content.offset_bottom = 960
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)

	_title = _make_label(160, Vector2(0, 440), 230)
	_info = _make_label(40, Vector2(40, 680), 270)
	_info.size.x = 1000
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_retry_button = _make_button(Vector2(190, 960), Color("3a7be0"))
	_retry_button.pressed.connect(func() -> void: retry_pressed.emit())
	_next_button = _make_button(Vector2(190, 1150), Color("2fae6a"))
	_next_button.pressed.connect(func() -> void: next_pressed.emit())
	codex_button = _make_button(Vector2(190, 1340), Color("6b4fd8"))
	codex_button.add_theme_font_size_override("font_size", 40)
	codex_button.pressed.connect(func() -> void: codex_pressed.emit())


## won / turns / next button text; xp = XP this fight gives (0 = don't show);
## big_title replaces "WIN!" (used for "ACT 1 CLEAR!").
func show_result(won: bool, turns: int, next_text: String, xp := 0, big_title := "", codex_text := "", rewards := "") -> void:
	codex_button.text = codex_text
	codex_button.visible = codex_text != ""
	_info.label_settings.font_size = 32 if rewards != "" else 44
	_title.text = big_title if big_title != "" else ("WIN!" if won else "LOSE")
	_title.label_settings.font_color = Color("ffd23f") if won else Color("ff5a5a")
	_title.label_settings.font_size = 120 if big_title != "" else 160
	if won:
		_info.text = "Fight won in %d turns" % turns
		if xp > 0:
			_info.text += "  ·  +%d XP" % xp
	else:
		_info.text = "Your team fell after %d turns" % turns
	if rewards != "":
		_info.text += "\n" + rewards
	_retry_button.text = "Fight Again" if won else "Retry"
	_next_button.text = next_text
	_next_button.visible = won
	visible = true
	modulate.a = 0.0
	_title.scale = Vector2.ONE * 0.6
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(_title, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _make_label(font_size: int, pos: Vector2, height: float) -> Label:
	var label := Label.new()
	var s := LabelSettings.new()
	s.font_size = font_size
	s.outline_size = maxi(8, int(font_size / 8.0))
	s.outline_color = Color(0.05, 0.02, 0.1)
	label.label_settings = s
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = pos
	label.size = Vector2(1080, height)
	label.pivot_offset = label.size * 0.5
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(label)
	return label


func _make_button(pos: Vector2, color: Color) -> Button:
	var b := Button.new()
	b.position = pos
	b.size = Vector2(700, 150)
	b.add_theme_font_size_override("font_size", 60)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _button_style(color))
	b.add_theme_stylebox_override("hover", _button_style(color.lightened(0.1)))
	b.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.2)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_content.add_child(b)
	return b


func _button_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(36)
	sb.border_width_bottom = 10
	sb.border_color = color.darkened(0.45)
	sb.shadow_color = Color(color, 0.35)
	sb.shadow_size = 16
	return sb
