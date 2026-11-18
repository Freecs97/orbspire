class_name HpBar
extends Node2D
## A rounded HP bar drawn with code.
##
## Plain English: when you take damage, the coloured part drops right away
## and a "damage tick" behind it (in tick_color) shrinks a moment later, so you
## can see how much was lost. Healing grows the bar smoothly.

var bar_size := Vector2(800, 36)
var fill_color := Color("47d16c")
var tick_color := Color("ff3b3b")
var show_text := true
## Draw a heart symbol at the left end (used for the team bar).
var show_heart := false

var max_value := 1
var value := 1
var _shown := 1.0   ## Ratio of the coloured fill (0..1).
var _lag := 1.0     ## Ratio of the damage tick behind it (0..1).
var _tween: Tween


func set_values(current: int, maximum: int, animate := true) -> void:
	max_value = maxi(maximum, 1)
	value = clampi(current, 0, max_value)
	var ratio := float(value) / max_value
	if _tween and _tween.is_valid():
		_tween.kill()
	if not animate:
		_shown = ratio
		_lag = ratio
		queue_redraw()
		return
	_tween = create_tween()
	if ratio < _shown:
		_shown = ratio
		_tween.tween_interval(0.25)
		_tween.tween_method(_set_lag, _lag, ratio, 0.35)
	else:
		_tween.tween_method(_set_both, _shown, ratio, 0.3)
	queue_redraw()


func _set_lag(v: float) -> void:
	_lag = v
	queue_redraw()


func _set_both(v: float) -> void:
	_shown = v
	_lag = v
	queue_redraw()


func _draw() -> void:
	var left := 0.0
	if show_heart:
		ElementIcons.draw_icon(self, Element.Type.HEART, Vector2(bar_size.y * 0.55, bar_size.y * 0.5), bar_size.y * 0.75, Color("ff6fb5"), Color("7a1f4a"))
		left = bar_size.y * 1.3
	var full := Rect2(Vector2(left, 0), Vector2(bar_size.x - left, bar_size.y))
	var radius := int(bar_size.y * 0.5)

	var back := StyleBoxFlat.new()
	back.bg_color = Color("141026")
	back.set_corner_radius_all(radius)
	back.set_border_width_all(3)
	back.border_color = Color("3b4470")
	draw_style_box(back, full.grow(3.0))

	if _lag > _shown:
		_bar(full, _lag, tick_color, radius)
	_bar(full, _shown, fill_color, radius)
	# Glossy stripe across the top half.
	if _shown > 0.0:
		var shine := StyleBoxFlat.new()
		shine.bg_color = Color(1, 1, 1, 0.16)
		shine.set_corner_radius_all(radius)
		draw_style_box(shine, Rect2(full.position + Vector2(4, 3), Vector2(maxf((full.size.x - 8) * _shown, 0.0), full.size.y * 0.35)))

	if show_text:
		var font := ThemeDB.fallback_font
		var fs := int(bar_size.y * 0.72)
		var text := "%d / %d" % [value, max_value]
		var pos := Vector2(full.position.x + 14, bar_size.y * 0.76)
		var width := full.size.x - 28
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_RIGHT, width, fs, 6, Color(0.03, 0.02, 0.06))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_RIGHT, width, fs, Color.WHITE)


func _bar(full: Rect2, ratio: float, color: Color, radius: int) -> void:
	if ratio <= 0.0:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	draw_style_box(sb, Rect2(full.position, Vector2(maxf(full.size.x * ratio, full.size.y), full.size.y)))
