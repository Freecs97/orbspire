class_name MoveTimerBar
extends Node2D
## The 5-second move timer bar.
##
## Plain English: full and dim while you're choosing an orb. Once you pick one
## up it lights up and shrinks: blue, then yellow under half, then red in the
## last quarter.

var bar_size := Vector2(990, 28)

var _ratio := 1.0
var _text := ""
var _active := false


func set_ratio(ratio: float, text: String, active: bool) -> void:
	_ratio = clampf(ratio, 0.0, 1.0)
	_text = text
	_active = active
	queue_redraw()


func _draw() -> void:
	var radius := int(bar_size.y * 0.5)
	var back := StyleBoxFlat.new()
	back.bg_color = Color("141026")
	back.set_corner_radius_all(radius)
	draw_style_box(back, Rect2(Vector2.ZERO, bar_size).grow(3.0))

	var col := Color("4fd8ff")
	if _ratio < 0.25:
		col = Color("ff4a4a")
	elif _ratio < 0.5:
		col = Color("ffc83d")
	if not _active:
		col = Color("4fd8ff").darkened(0.55)
	if _ratio > 0.0:
		var fill := StyleBoxFlat.new()
		fill.bg_color = col
		fill.set_corner_radius_all(radius)
		if _active:
			fill.shadow_color = Color(col, 0.6)
			fill.shadow_size = 10
		draw_style_box(fill, Rect2(Vector2.ZERO, Vector2(maxf(bar_size.x * _ratio, bar_size.y), bar_size.y)))

	if _text != "":
		var font := ThemeDB.fallback_font
		var fs := int(bar_size.y * 0.8)
		var pos := Vector2(0, bar_size.y * 0.8)
		draw_string_outline(font, pos, _text, HORIZONTAL_ALIGNMENT_CENTER, bar_size.x, fs, 6, Color(0.03, 0.02, 0.06))
		draw_string(font, pos, _text, HORIZONTAL_ALIGNMENT_CENTER, bar_size.x, fs, Color.WHITE)
