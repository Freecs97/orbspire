class_name ElementIcons
extends RefCounted
## Draws the symbol for each element (flame, droplet, leaf, star, moon, heart) with code.
##
## Plain English: the symbols make orbs readable without relying on colour,
## so colour-blind players can still play. Shapes are built from points in a
## "unit" box (about -1..1) and then scaled to the size we want.


## Draw an element symbol. Call this only from inside a _draw() function.
static func draw_icon(canvas: CanvasItem, type: int, center: Vector2, size: float, fill: Color, shadow: Color) -> void:
	var shape: PackedVector2Array
	match type:
		Element.Type.FIRE:
			shape = _flame()
		Element.Type.WATER:
			shape = _droplet()
		Element.Type.WOOD:
			shape = _leaf()
		Element.Type.HEART:
			shape = _heart()
		Element.Type.LIGHT:
			shape = _star()
		Element.Type.DARK:
			shape = _moon()
		_:
			return
	# Dark copy slightly lower = soft drop shadow, then the bright symbol on top.
	canvas.draw_colored_polygon(_place(shape, center + Vector2(0, size * 0.1), size), shadow)
	canvas.draw_colored_polygon(_place(shape, center, size), fill)
	if type == Element.Type.WOOD:
		# Leaf vein down the middle.
		var a := center + Vector2(0, -0.8).rotated(deg_to_rad(35)) * size
		var b := center + Vector2(0, 1.0).rotated(deg_to_rad(35)) * size
		canvas.draw_line(a, b, shadow, maxf(2.0, size * 0.1))


static func _place(shape: PackedVector2Array, center: Vector2, size: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in shape:
		out.append(center + p * size)
	return out


## Flame: a tall tip in the middle and two smaller tongues on the sides.
static func _flame() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -1.0), Vector2(0.28, -0.45), Vector2(0.5, -0.72),
		Vector2(0.64, -0.1), Vector2(0.56, 0.36), Vector2(0.3, 0.68),
		Vector2(0.0, 0.78), Vector2(-0.3, 0.68), Vector2(-0.56, 0.36),
		Vector2(-0.62, -0.05), Vector2(-0.42, -0.52), Vector2(-0.22, -0.2),
	])


## Droplet: a pointed top and a round bottom.
static func _droplet() -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2(0.0, -1.0)])
	var c := Vector2(0.0, 0.28)
	var r := 0.58
	for i in range(17):
		var a := deg_to_rad(-25.0 + i * 230.0 / 16.0)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


## Leaf: two curved edges meeting at the tip and the stem, tilted 35 degrees.
static func _leaf() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 10
	for i in range(n + 1):
		var t := float(i) / n
		pts.append(Vector2(sin(t * PI) * 0.5, -0.95 + t * 1.8))
	for i in range(n - 1, 0, -1):
		var t := float(i) / n
		pts.append(Vector2(-sin(t * PI) * 0.5, -0.95 + t * 1.8))
	for i in pts.size():
		pts[i] = pts[i].rotated(deg_to_rad(35))
	return pts


## Light: an 8-pointed star (long and short rays).
static func _star() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 16:
		var a := -PI * 0.5 + TAU * i / 16.0
		var r := 0.95 if i % 2 == 0 else 0.42
		if i % 4 == 2:
			r = 0.68   # diagonal rays are a bit shorter
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


## Dark: a crescent moon = a big circle with a smaller circle bitten out of it.
static func _moon() -> PackedVector2Array:
	var big_r := 0.85
	var bite_c := Vector2(0.42, -0.2)
	var bite_r := 0.7
	var away := bite_c.angle() + PI   # the side of the big circle that stays
	var pts := PackedVector2Array()
	# Outer edge: the part of the big circle outside the bite.
	for i in range(-179, 180, 4):
		var p := Vector2.from_angle(away + deg_to_rad(i)) * big_r
		if p.distance_to(bite_c) > bite_r:
			pts.append(p)
	# Inner edge: the part of the bite inside the big circle, walked backwards.
	for i in range(179, -180, -4):
		var q := bite_c + Vector2.from_angle(away + deg_to_rad(i)) * bite_r
		if q.length() < big_r:
			pts.append(q)
	return pts


## Heart: the classic heart curve.
static func _heart() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(32):
		var t := TAU * i / 32.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(Vector2(x, y + 2.0) / 17.0)
	return pts
