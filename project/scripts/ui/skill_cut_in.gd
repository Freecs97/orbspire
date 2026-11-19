class_name SkillCutIn
extends Control
## Skill cut-in: when a hunter uses its active skill, its FULL portrait flashes
## over the ORB BOARD (bottom half), never over the arena.
##
## Plain English:
##   - the board darkens, the portrait slides in from the right and fades in,
##     centred over the orbs at 75% of the screen width
##   - the skill name (big, in the hunter's colour) and the hunter's name show
##   - it holds, then fades out; THEN the skill's effects and damage numbers land
##     in the arena, which stayed visible the whole time
##   - normal: 0.15 in + 0.5 hold + 0.2 out = 0.85 s
##   - Stage 3 (fully evolved) or Singularity rarity: 2.0 s (0.3 + 1.4 + 0.3)
##   - tapping anywhere skips it; Settings > Skill Cut-ins turns it off
## Drawn in code with the hunter's own PNG. No video.

signal finished

const NORMAL := [0.15, 0.5, 0.2]   ## in, hold, out (seconds) = 0.85 s
const LONG := [0.3, 1.4, 0.3]      ## Stage 3 / Singularity = 2.0 s
const PORTRAIT_SCREEN_RATIO := 0.75   ## portrait width = 75% of the 1080 screen
const SLIDE := 160.0               ## px the portrait slides in from
const DIM_ALPHA := 0.75
const SKIP_OUT := 0.08             ## a tap fades it out this fast

var playing := false
var skipped := false
## How long the last cut-in was on screen (tests read this).
var last_duration := 0.0
var last_long := false

var _portrait: TextureRect
var _skill_label: Label
var _name_label: Label
var _color := Color.WHITE
var _band := 0.0:   ## 0..1: how far the light band has swept across
	set(v):
		_band = v
		queue_redraw()
var _start_ms := 0
var _skip_ms := 0
var _skip_alpha := 1.0
var _times: Array = NORMAL
var _home := Vector2.ZERO


func _init() -> void:
	clip_contents = true            # nothing ever spills out of the board area
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)
	_skill_label = _make_label(72, 14)
	_name_label = _make_label(38, 8)
	set_process(false)


## Is this hunter's cut-in the long one? (Stage 3 or Singularity rarity.)
static func is_long(member: FighterData) -> bool:
	return member.stage >= 3 or member.rarity >= 5


static func duration_for(member: FighterData) -> float:
	var t: Array = LONG if is_long(member) else NORMAL
	return t[0] + t[1] + t[2]


## Play the cut-in for this hunter's skill. Returns (await it) when it's gone.
func play(member: FighterData, skill_name: String) -> void:
	var times: Array = LONG if is_long(member) else NORMAL
	last_long = is_long(member)
	_color = Element.color(member.element)
	_portrait.texture = member.art
	var w := 1080.0 * PORTRAIT_SCREEN_RATIO
	var side := minf(w, size.y)
	_portrait.size = Vector2(side, side)
	_portrait.pivot_offset = _portrait.size * 0.5
	var home := (size - _portrait.size) * 0.5
	_portrait.position = home + Vector2(SLIDE, 0)
	_portrait.scale = Vector2.ONE
	_skill_label.text = skill_name.to_upper()
	_skill_label.label_settings.font_color = _color.lightened(0.45)
	_name_label.text = member.display_name if member.display_name != "" else Element.display_name(member.element)
	for l in [_skill_label, _name_label]:
		l.size = Vector2(size.x, 90)
	_skill_label.position = Vector2(0, size.y - 200)
	_name_label.position = Vector2(0, size.y - 112)
	_band = 0.0
	modulate.a = 0.0
	_times = times
	_home = home
	visible = true
	playing = true
	skipped = false
	_start_ms = Time.get_ticks_msec()
	set_process(true)
	await finished


## A tap: fade out right away.
func skip() -> void:
	if not playing or skipped:
		return
	skipped = true
	_skip_ms = Time.get_ticks_msec()
	_skip_alpha = modulate.a


## Driven by the REAL clock (not frame time), so it lasts exactly 0.85 s / 2.0 s
## even when a phone drops frames.
func _process(_delta: float) -> void:
	if not playing:
		set_process(false)
		return
	var now := Time.get_ticks_msec()
	if skipped:
		var k := (now - _skip_ms) / 1000.0 / SKIP_OUT
		modulate.a = _skip_alpha * (1.0 - clampf(k, 0.0, 1.0))
		if k >= 1.0:
			_done()
		return
	var t := (now - _start_ms) / 1000.0
	var t_in: float = _times[0]
	var t_hold: float = _times[1]
	var t_out: float = _times[2]
	# In: fade in while the portrait slides into the middle (eases out).
	var k_in := clampf(t / t_in, 0.0, 1.0)
	var ease_in := 1.0 - pow(1.0 - k_in, 3.0)
	_portrait.position = _home + Vector2(SLIDE * (1.0 - ease_in), 0)
	# Hold: the portrait leans in a little; the light band sweeps across.
	var k_hold := clampf((t - t_in) / t_hold, 0.0, 1.0)
	_portrait.scale = Vector2.ONE * (1.0 + (0.06 if last_long else 0.03) * k_hold)
	_band = clampf(t / (t_in + t_hold), 0.0, 1.0)
	# Out: fade.
	var k_out := clampf((t - t_in - t_hold) / t_out, 0.0, 1.0)
	modulate.a = k_in * (1.0 - k_out)
	if t >= t_in + t_hold + t_out:
		_done()


func _done() -> void:
	last_duration = (Time.get_ticks_msec() - _start_ms) / 1000.0
	playing = false
	visible = false
	set_process(false)
	finished.emit()


## Tapping anywhere on the screen skips the cut-in (and the tap goes no further).
func _input(event: InputEvent) -> void:
	if not playing:
		return
	var press: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	if press:
		skip()
		get_viewport().set_input_as_handled()


## Dark board + a light band in the hunter's colour sweeping behind the portrait.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.01, 0.04, DIM_ALPHA))
	var h := size.y
	var cx := lerpf(size.x * 1.1, size.x * 0.35, _band)
	var slant := h * 0.35
	var band_w := size.x * 0.5
	var pts := PackedVector2Array([Vector2(cx - band_w * 0.5 + slant, 0), Vector2(cx + band_w * 0.5 + slant, 0),
		Vector2(cx + band_w * 0.5 - slant, h), Vector2(cx - band_w * 0.5 - slant, h)])
	draw_colored_polygon(pts, Color(_color, 0.28))
	var core := PackedVector2Array([Vector2(cx - band_w * 0.12 + slant, 0), Vector2(cx + band_w * 0.12 + slant, 0),
		Vector2(cx + band_w * 0.12 - slant, h), Vector2(cx - band_w * 0.12 - slant, h)])
	draw_colored_polygon(core, Color(_color.lightened(0.5), 0.3))
	# A strip behind the names so they read over the portrait.
	draw_rect(Rect2(0, h - 215, size.x, 215), Color(0, 0, 0, 0.5))
	draw_line(Vector2(0, h - 215), Vector2(size.x, h - 215), Color(_color, 0.9), 4.0)


func _make_label(font_size: int, outline: int) -> Label:
	var l := Label.new()
	var s := LabelSettings.new()
	s.font_size = font_size
	s.font_color = Color.WHITE
	s.outline_size = outline
	s.outline_color = Color(0.02, 0.01, 0.06)
	s.shadow_size = 5
	s.shadow_color = Color(0, 0, 0, 0.6)
	s.shadow_offset = Vector2(3, 4)
	l.label_settings = s
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l
