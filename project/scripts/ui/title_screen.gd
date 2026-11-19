class_name TitleScreen
extends Control
## The start screen. Everything except the background picture is made in code.
##
## Plain English:
##   - Background: your title art, cropped to fill the phone (never stretched).
##   - ORBSPIRE in big glowing cyan + gold text, with a glitch flicker every few seconds.
##   - The 3 story hunters stand still on the terrace floor (no idle bob, same as in battle).
##   - Your orb art drifts slowly up the screen.
##   - Buttons: TAP TO START (first time) or CONTINUE, plus NEW GAME and SETTINGS.
##     Tapping anywhere else does the same as the big button.

signal start_pressed          ## TAP TO START or CONTINUE
signal new_game_confirmed     ## NEW GAME (after "Are you sure?" when there is a save)

const BG := preload("res://assets/backgrounds/bg_title_orbspire.png")
const PARTY := [
	preload("res://data/team/fire_berserker.tres"),
	preload("res://data/team/water_biotech.tres"),
	preload("res://data/team/wood_titan.tres"),
]
const ORB_ART := [
	preload("res://assets/orbs/orb_fire.png"), preload("res://assets/orbs/orb_water.png"),
	preload("res://assets/orbs/orb_wood.png"), preload("res://assets/orbs/orb_light.png"),
	preload("res://assets/orbs/orb_dark.png"),
]
const PARTY_X := [290.0, 540.0, 790.0]
const PARTY_FEET_Y := 1390.0
const PARTY_HEIGHT := 400.0

var has_save := false
var title_label: Label
var subtitle: Label
var main_button: Button
var new_game_button: Button
var settings_button: Button
var confirm_panel: Control
var confirm_yes: Button
var confirm_no: Button
var settings_panel: Control
var settings_close: Button
var party_bodies: Array[Node2D] = []
var glitch_count := 0          ## How many glitch flickers have played (tests read this).

var _content: Control
var _orb_layer: Node2D
var _ghosts: Array[Label] = []
var _next_glitch := 2.0
var _next_orb := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := TextureRect.new()
	bg.texture = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_CENTER)
	_content.offset_left = -540
	_content.offset_right = 540
	_content.offset_top = -960
	_content.offset_bottom = 960
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)

	_orb_layer = Node2D.new()
	_content.add_child(_orb_layer)

	# Party on the floor, standing still (shared idle = no motion).
	for i in PARTY.size():
		var d: FighterData = PARTY[i].duplicate()
		d.figure_height = PARTY_HEIGHT
		var spot := Node2D.new()
		spot.position = Vector2(PARTY_X[i], PARTY_FEET_Y)
		_content.add_child(spot)
		var shadow := ShadowDot.new()
		shadow.width = 120.0
		spot.add_child(shadow)
		var body := ArtFigure.new()
		spot.add_child(body)
		body.setup(d)
		var anim := FighterAnimator.new()
		spot.add_child(anim)
		anim.setup(body)
		anim.play_idle()
		party_bodies.append(body)

	# Title + glitch ghosts (cyan and magenta copies that flash for a moment).
	for ghost_color in [Color(0.2, 1.0, 1.0, 0.0), Color(1.0, 0.2, 0.8, 0.0)]:
		var g := _title_label(ghost_color, ghost_color)
		_ghosts.append(g)
	title_label = _title_label(Color("ffd23f"), Color("4fd8ff"))
	subtitle = _plain_label(46, Color("8fefff"))
	subtitle.text = "TAP TO START"
	subtitle.position = Vector2(0, 470)
	subtitle.size = Vector2(1080, 70)

	main_button = _button("TAP TO START", Vector2(190, 1480), Vector2(700, 140), 56)
	main_button.pressed.connect(func() -> void: start_pressed.emit())
	new_game_button = _button("NEW GAME", Vector2(190, 1650), Vector2(330, 100), 38)
	new_game_button.pressed.connect(_on_new_game)
	settings_button = _button("SETTINGS", Vector2(560, 1650), Vector2(330, 100), 38)
	settings_button.pressed.connect(func() -> void: settings_panel.visible = true)

	confirm_panel = _dialog("Are you sure?\nThis wipes your save.")
	confirm_yes = _button("YES, WIPE", Vector2(150, 1000), Vector2(360, 110), 40, Color("ff5a5a"), confirm_panel)
	confirm_no = _button("NO", Vector2(570, 1000), Vector2(360, 110), 40, MenuStyle.NEON, confirm_panel)
	confirm_yes.pressed.connect(func() -> void:
		confirm_panel.visible = false
		new_game_confirmed.emit())
	confirm_no.pressed.connect(func() -> void: confirm_panel.visible = false)

	settings_panel = _dialog("SETTINGS\n\nSound on / off and more settings\narrive with the save + settings step (Phase 8).")
	settings_close = _button("CLOSE", Vector2(360, 1000), Vector2(360, 110), 40, MenuStyle.NEON, settings_panel)
	settings_close.pressed.connect(func() -> void: settings_panel.visible = false)


## Call after deciding whether a save exists.
func set_has_save(value: bool) -> void:
	has_save = value
	main_button.text = "CONTINUE" if value else "TAP TO START"


func _on_new_game() -> void:
	if has_save:
		confirm_panel.visible = true
	else:
		new_game_confirmed.emit()


## Tapping the background = the big button.
func _gui_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		start_pressed.emit()


func _process(delta: float) -> void:
	subtitle.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 420.0)
	_next_glitch -= delta
	if _next_glitch <= 0.0:
		_next_glitch = randf_range(2.5, 4.5)
		_glitch()
	_next_orb -= delta
	if _next_orb <= 0.0:
		_next_orb = randf_range(0.5, 0.9)
		_spawn_orb()


## A quick glitch: the title jumps sideways and two coloured copies flash.
func _glitch() -> void:
	glitch_count += 1
	var tw := create_tween()
	for k in 3:
		var dx := randf_range(-14.0, 14.0)
		tw.tween_callback(func() -> void:
			title_label.position.x = dx
			_ghosts[0].position.x = dx - 9.0
			_ghosts[1].position.x = dx + 9.0
			_ghosts[0].modulate.a = 0.75
			_ghosts[1].modulate.a = 0.75)
		tw.tween_interval(0.05)
	tw.tween_callback(func() -> void:
		title_label.position.x = 0.0
		for g in _ghosts:
			g.position.x = 0.0
			g.modulate.a = 0.0)


## One orb drifting up from the bottom, swaying, fading in and out.
func _spawn_orb() -> void:
	var s := Sprite2D.new()
	s.texture = ORB_ART.pick_random()
	var size := randf_range(0.1, 0.24)
	s.scale = Vector2(size, size)
	s.position = Vector2(randf_range(40.0, 1040.0), 1980.0)
	s.modulate.a = 0.0
	_orb_layer.add_child(s)
	var t := randf_range(9.0, 15.0)
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "position:y", randf_range(60.0, 400.0), t)
	tw.tween_property(s, "position:x", s.position.x + randf_range(-120.0, 120.0), t).set_trans(Tween.TRANS_SINE)
	tw.tween_property(s, "modulate:a", 0.85, 1.5)
	tw.tween_property(s, "modulate:a", 0.0, 2.0).set_delay(t - 2.0)
	tw.chain().tween_callback(s.queue_free)


func orb_count() -> int:
	return _orb_layer.get_child_count()


func _title_label(color: Color, outline: Color) -> Label:
	var l := Label.new()
	var s := LabelSettings.new()
	s.font_size = 170
	s.font_color = color
	s.outline_size = 14
	s.outline_color = outline
	s.shadow_size = 24
	s.shadow_color = Color(outline, 0.45 if color.a > 0.0 else 0.0)
	s.shadow_offset = Vector2.ZERO
	l.label_settings = s
	l.text = "ORBSPIRE"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(1080, 220)
	l.position = Vector2(0, 250)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if color.a == 0.0:
		l.label_settings.font_color = Color(color, 1.0)
		l.modulate.a = 0.0
	_content.add_child(l)
	return l


func _plain_label(size: int, color: Color) -> Label:
	var l := Label.new()
	var s := LabelSettings.new()
	s.font_size = size
	s.font_color = color
	s.outline_size = 8
	s.outline_color = Color(0.02, 0.02, 0.06)
	l.label_settings = s
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(l)
	return l


func _button(text: String, pos: Vector2, size: Vector2, font: int, neon := MenuStyle.NEON, parent: Node = null) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	MenuStyle.apply(b, font, neon)
	(parent if parent else _content).add_child(b)
	return b


## A small centred panel over a dark screen (for "Are you sure?" and Settings).
func _dialog(text: String) -> Control:
	var d := Control.new()
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	d.offset_left = 0
	d.offset_top = 0
	d.size = Vector2(1080, 1920)
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	d.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.01, 0.04, 0.8)
	dim.position = Vector2(-2000, -2000)
	dim.size = Vector2(5080, 5920)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.add_child(dim)
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = MenuStyle.PANEL
	sb.set_corner_radius_all(26)
	sb.set_border_width_all(3)
	sb.border_color = MenuStyle.NEON
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(100, 700)
	panel.size = Vector2(880, 460)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.add_child(panel)
	var l := Label.new()
	var s := LabelSettings.new()
	s.font_size = 42
	s.font_color = Color.WHITE
	l.label_settings = s
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(100, 740)
	l.size = Vector2(880, 220)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.add_child(l)
	_content.add_child(d)
	return d


## A soft oval shadow under each hunter's feet.
class ShadowDot:
	extends Node2D
	var width := 100.0

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, width, Color(0, 0, 0, 0.45))
