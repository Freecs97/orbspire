class_name StarMap
extends HomePage
## The Act select screen. Your star map image is the background; everything you
## can tap or read is made in Godot on top of it.
##
## Plain English:
##   - 10 nodes, one per Act, at positions given as PERCENT of the map area
##     (between the top bar and the bottom nav), so they line up on any phone.
##   - Your image has no planets drawn in it, so each node is drawn in code:
##     a small planet dot with a thin ring in the Act's element colour.
##   - Completed Act: gold check mark, tap to replay.
##     Current Act:   pulsing ring, tap to play.
##     Locked Act:    grey label + padlock, tap says "Finish Act X to unlock".
##   - A dotted route joins the nodes, only up to the current Act.
##   - Tapping an unlocked node opens a small panel: 3 lines of colony intel,
##     a PLAY button, and an empty "Side Rift - coming soon" slot. It never
##     starts a fight on its own.
##   - Top bar: Credits, Training Cores, player level, Settings. Bottom nav:
##     Play (this screen), Team, Roster, Recruit, Quests.

signal play_pressed(act_number: int)

const BG := preload("res://assets/backgrounds/bg_star_map.png")
const ACTS: Array[ActData] = [
	preload("res://data/acts/act_01.tres"), preload("res://data/acts/act_02.tres"),
	preload("res://data/acts/act_03.tres"), preload("res://data/acts/act_04.tres"),
	preload("res://data/acts/act_05.tres"), preload("res://data/acts/act_06.tres"),
	preload("res://data/acts/act_07.tres"), preload("res://data/acts/act_08.tres"),
	preload("res://data/acts/act_09.tres"), preload("res://data/acts/act_10.tres"),
]
## Node positions in PERCENT of the map area (your starting positions).
## Calibrate here: x 0-100 left to right, y 0-100 top to bottom.
const NODE_PCT := [
	Vector2(50, 88), Vector2(30, 78), Vector2(70, 68), Vector2(35, 58), Vector2(65, 48),
	Vector2(30, 38), Vector2(70, 28), Vector2(35, 18), Vector2(65, 10), Vector2(50, 4),
]

## Which Acts are finished (Act numbers). Set by main.gd from the save.
var cleared: Array = []
var credits := 0
var training_cores := 0
var player_level := 1
## Show numbered calibration markers on each node (for lining up with art).
var show_markers := false

var node_buttons: Array[Button] = []
var panel: Control
var panel_title: Label
var panel_sub: Label
var panel_intel: Label
var play_button: Button
var rift_button: Button
var panel_close: Button
var _labels: Array[Label] = []
var _overlay: Control
var _panel_act := 0
var _pulse := 0.0


func _init() -> void:
	_setup_page("PLAY")
	var bg := TextureRect.new()
	bg.texture = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED   # fills the phone, never squashed
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Route line + node art are drawn on this layer.
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_map)
	add_child(_overlay)

	for i in ACTS.size():
		var b := Button.new()   # invisible hit area over the node
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		var empty := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(s, empty)
		b.pressed.connect(_on_node_pressed.bind(i + 1))
		add_child(b)
		node_buttons.append(b)
		var name_label := _label(30, Color.WHITE)
		var boss_label := _label(22, Color("cfc8ee"))
		_labels.append(name_label)
		_labels.append(boss_label)

	_build_panel()
	_build_bars()
	resized.connect(_layout)


func refresh() -> void:
	set_bar_values(credits, training_cores, player_level)
	for i in ACTS.size():
		var a := ACTS[i]
		var st := state(a.act_number)
		var name_label := _labels[i * 2]
		var boss_label := _labels[i * 2 + 1]
		name_label.text = a.colony_name
		boss_label.text = a.singularity_name
		var grey := Color(0.55, 0.55, 0.62)
		name_label.label_settings.font_color = grey if st == "locked" else Color.WHITE
		boss_label.label_settings.font_color = grey.darkened(0.2) if st == "locked" else Color("cfc8ee")
	_layout()


## "completed", "current" or "locked" for an Act number.
func state(act_number: int) -> String:
	if act_number in cleared:
		return "completed"
	if act_number == 1 or (act_number - 1) in cleared:
		return "current"
	return "locked"


## Screen position of Act node i (0-based), from the percent table.
func node_pos(i: int) -> Vector2:
	var area := Rect2(0, TOP_BAR_H, size.x, size.y - TOP_BAR_H - NAV_H)
	var p: Vector2 = NODE_PCT[i]
	return area.position + Vector2(area.size.x * p.x / 100.0, area.size.y * p.y / 100.0)


func node_radius(i: int) -> float:
	return 40.0 if i == ACTS.size() - 1 else 28.0


func _layout() -> void:
	for i in ACTS.size():
		var p := node_pos(i)
		var hit := 120.0
		node_buttons[i].position = p - Vector2(hit, hit) * 0.5
		node_buttons[i].size = Vector2(hit, hit)
		# Labels go beside the node, on the side with more room.
		var right: bool = NODE_PCT[i].x <= 50.0
		for k in 2:
			var l := _labels[i * 2 + k]
			l.size = Vector2(300, 40)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if right else HORIZONTAL_ALIGNMENT_RIGHT
			var x := p.x + node_radius(i) + 18.0 if right else p.x - node_radius(i) - 18.0 - 300.0
			l.position = Vector2(x, p.y - 34.0 + k * 36.0)
	_layout_bars()
	panel.position = Vector2((size.x - 1000) * 0.5, size.y * 0.5 - 420)
	_overlay.queue_redraw()


func _process(delta: float) -> void:
	_pulse = fmod(_pulse + delta * 3.0, TAU)
	_overlay.queue_redraw()


# ---------------------------------------------------------------- drawing

func _draw_map() -> void:
	var o := _overlay
	# Dotted route, only up to the current (furthest unlocked) Act.
	var last := 0
	for i in ACTS.size():
		if state(ACTS[i].act_number) != "locked":
			last = i
	for i in last:
		var a := node_pos(i)
		var b := node_pos(i + 1)
		var steps := int(a.distance_to(b) / 22.0)
		for k in range(1, steps):
			if k % 2 == 0:
				o.draw_circle(a.lerp(b, float(k) / steps), 3.5, Color(0.75, 0.9, 1.0, 0.75))
	for i in ACTS.size():
		var act := ACTS[i]
		var p := node_pos(i)
		var r := node_radius(i)
		var c := Element.color(act.element)
		var st := state(act.act_number)
		if st == "locked":
			c = Color(0.45, 0.45, 0.52)
		# Planet dot + thin affinity ring.
		o.draw_circle(p, r + 10.0, Color(c, 0.12))
		o.draw_circle(p, r, c.darkened(0.55))
		o.draw_circle(p + Vector2(-r * 0.25, -r * 0.25), r * 0.55, Color(c.lightened(0.2), 0.55))
		o.draw_arc(p, r + 6.0, 0.0, TAU, 48, c, 2.5, true)
		if st == "current":
			var grow := 10.0 + 8.0 * (0.5 + 0.5 * sin(_pulse))
			o.draw_arc(p, r + grow, 0.0, TAU, 48, Color(c.lightened(0.3), 0.85), 4.0, true)
		elif st == "completed":
			var cp := p + Vector2(r * 0.8, -r * 0.8)
			o.draw_circle(cp, 16.0, GOLD)
			o.draw_polyline(PackedVector2Array([cp + Vector2(-8, 0), cp + Vector2(-2, 6), cp + Vector2(9, -7)]), Color(0.15, 0.1, 0.0), 4.0, true)
		else:
			_draw_padlock(p)
		if show_markers:
			var font := ThemeDB.fallback_font
			o.draw_circle(p, 18.0, Color(1, 0.1, 0.4))
			o.draw_string(font, p + Vector2(-18, 9), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 36, 24, Color.WHITE)


func _draw_padlock(p: Vector2) -> void:
	var o := _overlay
	o.draw_arc(p + Vector2(0, -6), 9.0, PI, TAU, 16, Color(0.85, 0.85, 0.9), 4.0, true)
	o.draw_rect(Rect2(p + Vector2(-12, -6), Vector2(24, 19)), Color(0.85, 0.85, 0.9))
	o.draw_circle(p + Vector2(0, 2), 3.0, Color(0.2, 0.2, 0.25))


# ---------------------------------------------------------------- interaction

func _on_node_pressed(act_number: int) -> void:
	if panel.visible:
		return
	var st := state(act_number)
	if st == "locked":
		show_toast("Finish Act %d to unlock" % (act_number - 1))
		return
	open_panel(act_number)


func open_panel(act_number: int) -> void:
	var a := ACTS[act_number - 1]
	_panel_act = act_number
	panel_title.text = "ACT %d  ·  %s" % [act_number, a.colony_name.to_upper()]
	panel_title.label_settings.font_color = Element.color(a.element).lightened(0.35)
	panel_sub.text = "%s  ·  %s  ·  %s" % [a.colony_kind, a.singularity_name, Element.display_name(a.element)]
	panel_intel.text = "\n".join(PackedStringArray(a.intel_lines))
	var completed := state(act_number) == "completed"
	play_button.text = "REPLAY" if completed else "PLAY"
	play_button.disabled = not a.is_built()
	if not a.is_built():
		play_button.text = "COMING NEXT"
	panel.visible = true


# ---------------------------------------------------------------- building

func _build_panel() -> void:
	panel = Control.new()
	panel.size = Vector2(1000, 860)
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	var box := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = MenuStyle.PANEL
	sb.set_corner_radius_all(28)
	sb.set_border_width_all(3)
	sb.border_color = MenuStyle.NEON
	sb.shadow_color = Color(MenuStyle.NEON, 0.25)
	sb.shadow_size = 18
	box.add_theme_stylebox_override("panel", sb)
	box.size = panel.size
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	panel_title = _label(46, Color.WHITE, panel)
	panel_title.position = Vector2(40, 34)
	panel_sub = _label(28, GOLD, panel)
	panel_sub.position = Vector2(40, 104)
	panel_intel = _label(32, Color.WHITE, panel)
	panel_intel.position = Vector2(40, 170)
	panel_intel.size = Vector2(920, 330)
	panel_intel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_intel.label_settings.line_spacing = 12
	play_button = _panel_button("PLAY", Vector2(40, 520), Vector2(920, 120), 50, GOLD)
	play_button.pressed.connect(func() -> void:
		panel.visible = false
		play_pressed.emit(_panel_act))
	rift_button = _panel_button("SIDE RIFT  ·  coming soon", Vector2(40, 660), Vector2(440, 100), 28, MenuStyle.NEON)
	rift_button.disabled = true
	panel_close = _panel_button("CLOSE", Vector2(520, 660), Vector2(440, 100), 34, MenuStyle.NEON)
	panel_close.pressed.connect(func() -> void: panel.visible = false)


func _panel_button(text: String, pos: Vector2, sz: Vector2, font: int, neon: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	MenuStyle.apply(b, font, neon)
	panel.add_child(b)
	return b


func _label(font_size: int, color: Color, parent: Node = null) -> Label:
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
