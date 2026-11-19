class_name StarRow
extends Control
## Rarity stars drawn in code (★1 Scrap ... ★6 Singularity), so they show on
## every platform (the web build has no system fonts to borrow a ★ glyph from).

const STAR := 46.0
const GAP := 10.0

var filled := 1
var total := 6
var color := Color("ffd23f")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(total * (STAR + GAP) - GAP, STAR)
	size = custom_minimum_size


## Show `count` filled stars of 6 in this colour.
func set_stars(count: int, c: Color) -> void:
	filled = clampi(count, 0, total)
	color = c
	queue_redraw()


func _draw() -> void:
	for i in total:
		var center := Vector2(i * (STAR + GAP) + STAR * 0.5, STAR * 0.5)
		var pts := PackedVector2Array()
		for k in 10:
			var r := STAR * 0.5 if k % 2 == 0 else STAR * 0.22
			var a := -PI * 0.5 + k * PI / 5.0
			pts.append(center + Vector2(cos(a), sin(a)) * r)
		var on := i < filled
		draw_colored_polygon(pts, color if on else Color(0.22, 0.22, 0.3))
		pts.append(pts[0])
		draw_polyline(pts, color.lightened(0.4) if on else Color(0.38, 0.38, 0.48), 2.0, true)
