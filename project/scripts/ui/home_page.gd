class_name HomePage
extends Control
## Shared frame for the home screens (Star map, Team, Roster, Recruit):
## a top bar (Credits, Training Cores, player level, Settings) and a bottom
## nav (Play, Team, Roster, Recruit, Quests). Subclasses build their content,
## then call _build_bars() so the bars sit on top.

signal tab_pressed(tab: String)

const TOP_BAR_H := 130.0
const NAV_H := 170.0
const GOLD := Color("ffd23f")
const TABS := ["PLAY", "TEAM", "ROSTER", "RECRUIT", "QUESTS"]

## Which nav tab this page is.
var tab_name := "PLAY"
var nav_buttons: Array[Button] = []
var settings_button: Button
var toast: Label
var _top_labels: Array[Label] = []
var _toast_tween: Tween


func _setup_page(tab: String) -> void:
	tab_name = tab
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _build_bars() -> void:
	var bar := ColorRect.new()
	bar.color = Color(0.04, 0.04, 0.08, 0.86)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = TOP_BAR_H
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	for text in ["CREDITS  0", "CORES  0", "LV 1"]:
		var l := make_label(32, GOLD if text.begins_with("LV") else Color("8fefff"))
		l.text = text
		l.size = Vector2(300, 50)
		_top_labels.append(l)
	settings_button = Button.new()
	settings_button.text = "⚙"
	settings_button.size = Vector2(80, 80)
	MenuStyle.apply(settings_button, 40)
	settings_button.pressed.connect(func() -> void: show_toast("Settings arrive in the save + settings step (Phase 8)"))
	add_child(settings_button)

	var nav := ColorRect.new()
	nav.color = Color(0.04, 0.04, 0.08, 0.9)
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_top = -NAV_H
	nav.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(nav)
	for name in TABS:
		var b := Button.new()
		b.text = name
		var selected: bool = name == tab_name
		MenuStyle.apply(b, 28, GOLD if selected else MenuStyle.NEON)
		if selected:
			b.add_theme_color_override("font_color", GOLD)
		else:
			b.modulate = Color(1, 1, 1, 0.8)
		b.pressed.connect(func() -> void:
			if name == "QUESTS":
				show_toast("Quests (daily / weekly Credits) are coming soon")
			elif name != tab_name:
				tab_pressed.emit(name))
		add_child(b)
		nav_buttons.append(b)
	toast = make_label(34, Color.WHITE)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.modulate.a = 0.0
	resized.connect(_layout_bars)


func set_bar_values(credits: int, cores: int, level: int) -> void:
	_top_labels[0].text = "CREDITS  %d" % credits
	_top_labels[1].text = "CORES  %d" % cores
	_top_labels[2].text = "LV %d" % level


func _layout_bars() -> void:
	var w := size.x
	for k in _top_labels.size():
		_top_labels[k].position = Vector2(30 + k * (w - 160) / 3.0, 40)
	settings_button.position = Vector2(w - 110, 25)
	for k in nav_buttons.size():
		var bw := w / nav_buttons.size()
		nav_buttons[k].position = Vector2(k * bw + 6, size.y - NAV_H + 18)
		nav_buttons[k].size = Vector2(bw - 12, NAV_H - 36)
	toast.position = Vector2(0, size.y - NAV_H - 120)
	toast.size = Vector2(w, 60)


func show_toast(text: String) -> void:
	toast.text = text
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.6)
	_toast_tween.tween_property(toast, "modulate:a", 0.0, 0.4)


## The usable area between the two bars.
func content_rect() -> Rect2:
	return Rect2(0, TOP_BAR_H, size.x, size.y - TOP_BAR_H - NAV_H)


func make_label(font_size: int, color: Color, parent: Node = null) -> Label:
	var l := Label.new()
	var s := LabelSettings.new()
	s.font_size = font_size
	s.font_color = color
	s.outline_size = 6
	s.outline_color = Color(0.02, 0.01, 0.06)
	l.label_settings = s
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else self).add_child(l)
	return l


func make_button(text: String, pos: Vector2, sz: Vector2, font: int, neon := MenuStyle.NEON, parent: Node = null) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	MenuStyle.apply(b, font, neon)
	(parent if parent else self).add_child(b)
	return b


## A dark rounded panel (for pop-ups and cards).
func make_panel(pos: Vector2, sz: Vector2, border := MenuStyle.NEON, parent: Node = null) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = MenuStyle.PANEL
	sb.set_corner_radius_all(24)
	sb.set_border_width_all(3)
	sb.border_color = border
	p.add_theme_stylebox_override("panel", sb)
	p.position = pos
	p.size = sz
	(parent if parent else self).add_child(p)
	return p
