class_name Backdrop
extends Node2D
## Scenery drawn with code: a stone corridor for the enemy and a dark panel
## behind the team.
##
## Plain English: the corridor is four shapes (ceiling, two walls and a floor)
## that all point toward a glowing doorway in the middle, which fakes depth.
## It sits ABOVE the board in draw order, so new orbs falling in from the top
## stay hidden until they reach the board. It looks as if the board clips them.
##
## On taller phones the battle script calls set_layout() with the extra height,
## and the corridor simply gets taller. Nothing is stretched out of shape.

const BASE_ENEMY_BOTTOM := 665.0
const BASE_TEAM_BOTTOM := 1078.0

var extra_height := 0.0   ## How much taller than 1920 the screen is.
var side_margin := 0.0    ## How much wider than 1080 the screen is, per side.
var enemy_feet_y := 560.0
## Your arena background art for this Act. Empty = the code-drawn corridor.
var arena: Texture2D:
	set(value):
		arena = value
		queue_redraw()


## Exploration worlds: turn the arena's colours by this much (0 = as drawn).
var arena_hue := 0.0:
	set(value):
		arena_hue = value
		if _layer:
			_layer.material = MapArt.material(value) if not is_zero_approx(value) else null
		queue_redraw()
var _layer: Node2D
var _arena_rect: Array = []


func _arena_layer() -> Node2D:
	if _layer == null:
		_layer = Node2D.new()
		_layer.show_behind_parent = true
		_layer.material = MapArt.material(arena_hue)
		_layer.draw.connect(func() -> void:
			if arena and not _arena_rect.is_empty() and not is_zero_approx(arena_hue):
				_layer.draw_texture_rect_region(arena, _arena_rect[0], _arena_rect[1]))
		add_child(_layer)
	return _layer


## Tall screens: the scenery grows taller (extra) and wider (side); nothing stretches.
func set_layout(extra: float, side: float, enemy_y: float) -> void:
	extra_height = extra
	side_margin = side
	enemy_feet_y = enemy_y
	queue_redraw()


func _draw() -> void:
	if arena:
		_draw_arena()
	else:
		_draw_corridor()
	_draw_team_panel()


## Your arena art fills the enemy area, cropped (never stretched) so its
## floor sits where the enemies stand. A dark fade at the top keeps the
## fight title readable.
func _draw_arena() -> void:
	var left := -side_margin - 4.0
	var right := 1080.0 + side_margin + 4.0
	var dest := Rect2(left, 0, right - left, BASE_ENEMY_BOTTOM + extra_height)
	var tex := arena.get_size()
	var s := maxf(dest.size.x / tex.x, dest.size.y / tex.y)
	var src_size := dest.size / s
	var src_y := clampf(tex.y * 0.62 - src_size.y * 0.75, 0.0, tex.y - src_size.y)
	var src := Rect2((tex.x - src_size.x) * 0.5, src_y, src_size.x, src_size.y)
	if is_zero_approx(arena_hue):
		draw_texture_rect_region(arena, dest, src)
	else:
		# Exploration worlds re-use an Act arena, hue-shifted (MapArt shader). It is
		# drawn on a child layer behind this node so only the arena is recoloured.
		_arena_rect = [dest, src]
		_arena_layer().queue_redraw()
	var fade := Color(0.02, 0.01, 0.06, 0.75)
	var clear := Color(0.02, 0.01, 0.06, 0.0)
	_quad([Vector2(left, 0), Vector2(right, 0), Vector2(right, 190), Vector2(left, 190)], [fade, fade, clear, clear])


func _draw_corridor() -> void:
	var left := -side_margin - 4.0
	var right := 1080.0 + side_margin + 4.0
	var bottom := BASE_ENEMY_BOTTOM + extra_height
	var back := Rect2(330, 150 + extra_height * 0.3, 420, 320 + extra_height * 0.3)
	var near_dark := Color("0b0918")
	var wall := Color("2a2150")
	var far_glow := Color("6b4fd8")
	var tl := back.position
	var tr := Vector2(back.end.x, back.position.y)
	var br := back.end
	var bl := Vector2(back.position.x, back.end.y)

	# Ceiling, walls, floor. Near edges are dark and far edges light = depth.
	_quad([Vector2(left, 0), Vector2(right, 0), tr, tl], [near_dark, near_dark, wall, wall])
	_quad([Vector2(left, 0), tl, bl, Vector2(left, bottom)], [near_dark, wall, wall.darkened(0.2), near_dark])
	_quad([tr, Vector2(right, 0), Vector2(right, bottom), br], [wall, near_dark, near_dark, wall.darkened(0.2)])
	_quad([bl, br, Vector2(right, bottom), Vector2(left, bottom)], [Color("3a2d6e"), Color("3a2d6e"), Color("120e26"), Color("120e26")])

	# The glowing doorway at the back.
	_quad([tl, tr, br, bl], [far_glow.darkened(0.3), far_glow.darkened(0.3), far_glow, far_glow])
	draw_circle(back.get_center() + Vector2(0, 60), 150.0, Color(0.6, 0.5, 1.0, 0.1))
	draw_circle(back.get_center() + Vector2(0, 60), 90.0, Color(0.7, 0.6, 1.0, 0.1))

	# Stone seams on the walls and floor tile lines, all pointing at the doorway.
	var seam := Color(1, 1, 1, 0.05)
	for i in range(1, 5):
		var t := i / 5.0
		draw_line(Vector2(0, bottom * t), tl.lerp(bl, t), seam, 2.0)
		draw_line(Vector2(1080, bottom * t), tr.lerp(br, t), seam, 2.0)
	for i in range(0, 7):
		var t := i / 6.0
		draw_line(Vector2(1080 * t, bottom), bl.lerp(br, t), seam, 2.0)
	for i in range(1, 4):
		var t := pow(i / 4.0, 1.6)
		var y := lerpf(bl.y, bottom, t)
		draw_line(Vector2(lerpf(bl.x, 0.0, t), y), Vector2(lerpf(br.x, 1080.0, t), y), seam, 2.0)

	# Two wall torches with warm glows.
	for x in [140.0, 940.0]:
		var p := Vector2(x, 250 + extra_height * 0.3)
		for r in [110.0, 70.0, 40.0]:
			draw_circle(p, r, Color(1.0, 0.6, 0.25, 0.07))
		draw_rect(Rect2(p + Vector2(-7, 6), Vector2(14, 40)), Color("3a2a1e"))
		ElementIcons.draw_icon(self, Element.Type.FIRE, p, 20.0, Color("ffd27a"), Color("ff7a2a"))

	# Soft spotlight on the floor where the enemy stands.
	draw_set_transform(Vector2(540, enemy_feet_y + 40), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 300.0, Color(0.6, 0.5, 1.0, 0.1))
	draw_circle(Vector2.ZERO, 200.0, Color(0.7, 0.6, 1.0, 0.08))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_team_panel() -> void:
	var left := -side_margin - 4.0
	var right := 1080.0 + side_margin + 4.0
	var top := BASE_ENEMY_BOTTOM + extra_height
	var bottom := BASE_TEAM_BOTTOM + extra_height
	_quad([Vector2(left, top), Vector2(right, top), Vector2(right, bottom), Vector2(left, bottom)],
		[Color("161c34"), Color("161c34"), Color("0b0f1e"), Color("0b0f1e")])
	# Glowing divider line between the enemy and the team.
	draw_line(Vector2(left, top), Vector2(right, top), Color(0.55, 0.45, 1.0, 0.5), 3.0)
	draw_rect(Rect2(left, top, right - left, 18), Color(0.55, 0.45, 1.0, 0.06))


## A four-cornered shape with a colour per corner (makes a gradient).
func _quad(points: Array, colors: Array) -> void:
	draw_polygon(PackedVector2Array(points), PackedColorArray(colors))
