class_name PlaceholderFigure
extends Node2D
## Draws a placeholder body out of simple shapes. No image files needed.
## (Your real character PNGs replace these later.)
##
## Plain English: humans are built from a head, hair, torso, arms, legs and
## feet, plus one prop that hints at their type:
##   Berserker = greatsword, Titan = tower shield, Spectre = hood + twin
##   daggers, Biotech = staff with a glowing tip.
## The enemy is a horned, round, grey creature with glowing eyes, so it never
## reads as human. Everything is drawn twice: first fat and dark (the outline),
## then normal size in colour on top. The origin (0, 0) is at the FEET, so
## scaling keeps the feet planted on the ground.

const OUTLINE := Color(0.06, 0.05, 0.1)
const OUTLINE_WIDTH := 7.0
const SKIN := Color("f1c9a5")
const HAIR := Color("3b2a22")

var data: FighterData


func setup(fighter: FighterData) -> void:
	data = fighter
	queue_redraw()


func _draw() -> void:
	if data == null:
		return
	if data.is_enemy():
		# Each enemy kind has its own simple shape so fights read differently.
		for outline in [true, false]:
			match data.kind:
				&"drone":
					_draw_drone(outline)
				&"slime":
					_draw_slime(outline)
				&"foreman", &"thief":
					_draw_enemy_human(outline)
				&"sprout":
					_draw_sprout(outline)
				&"golem":
					_draw_golem(outline)
				&"wolf":
					_draw_wolf(outline)
				_:
					_draw_enemy(outline)
	else:
		_draw_human(true)
		_draw_human(false)


# ---------------------------------------------------------------- human

func _draw_human(outline: bool) -> void:
	var h := data.figure_height
	var w := data.figure_width
	var col := data.body_color
	var head_r := h * 0.105
	var head_c := Vector2(0, -h + head_r)
	var shoulder_y := -h + head_r * 2.0 + h * 0.04
	var hip_y := -h * 0.42
	var leg_w := w * 0.34
	var arm_w := w * 0.26
	var hand_l := Vector2(-w * 0.62, hip_y + h * 0.02)
	var hand_r := Vector2(w * 0.62, hip_y + h * 0.02)

	# Legs + feet.
	for side in [-1.0, 1.0]:
		_capsule(Vector2(side * w * 0.2, hip_y), Vector2(side * w * 0.24, -leg_w * 0.5), leg_w, col.darkened(0.5), outline)
		_capsule(Vector2(side * w * 0.24, -7), Vector2(side * (w * 0.24 + 12.0), -7), 14.0, Color("2a2230"), outline)
	# Torso.
	_capsule(Vector2(0, shoulder_y + w * 0.5), Vector2(0, hip_y - w * 0.15), w, col, outline)
	# Arms + hands.
	for hand in [hand_l, hand_r]:
		var shoulder := Vector2(signf(hand.x) * w * 0.42, shoulder_y + arm_w * 0.6)
		_capsule(shoulder, hand, arm_w, col.lightened(0.08), outline)
		_ball(hand, arm_w * 0.55, SKIN, outline)
	# Role prop.
	_draw_prop(outline, hand_l, hand_r, h, w, col)
	# Hair (or a hood for the Spectre), then face on top of it.
	if data.role == FighterData.Role.SPECTRE:
		_ball(head_c + Vector2(0, -head_r * 0.1), head_r * 1.32, col.darkened(0.35), outline)
		_tri([head_c + Vector2(-head_r * 0.6, -head_r * 0.9), head_c + Vector2(0, -head_r * 1.9), head_c + Vector2(head_r * 0.6, -head_r * 0.9)], col.darkened(0.35), outline)
	else:
		_ball(head_c + Vector2(0, -head_r * 0.18), head_r * 1.06, HAIR, outline)
	_ball(head_c + Vector2(0, head_r * 0.08), head_r * 0.92, SKIN, outline)

	if outline:
		return
	# Details drawn only in the colour pass.
	draw_line(Vector2(-w * 0.48, hip_y - w * 0.12), Vector2(w * 0.48, hip_y - w * 0.12), col.darkened(0.55), 7.0)
	draw_circle(head_c + Vector2(-head_r * 0.35, head_r * 0.15), head_r * 0.12, OUTLINE)
	draw_circle(head_c + Vector2(head_r * 0.35, head_r * 0.15), head_r * 0.12, OUTLINE)
	# Soft light on the torso for a little depth.
	draw_circle(Vector2(-w * 0.15, shoulder_y + w * 0.35), w * 0.18, Color(1, 1, 1, 0.12))
	_draw_badge(Vector2(0, -h - 34))


func _draw_prop(outline: bool, hand_l: Vector2, hand_r: Vector2, h: float, w: float, col: Color) -> void:
	match data.role:
		FighterData.Role.BERSERKER:
			# Big greatsword raised in the right hand.
			var tip := hand_r + Vector2(w * 0.3, -h * 0.62)
			_capsule(hand_r, tip, 20.0, Color("e3e9f0"), outline)
			_capsule(hand_r + Vector2(-24, 10), hand_r + Vector2(24, -10), 12.0, Color("c8963a"), outline)
		FighterData.Role.BIOTECH:
			# Staff in the left hand with a glowing tip.
			var top := hand_l + Vector2(-6, -h * 0.62)
			_capsule(hand_l + Vector2(2, 40), top, 10.0, Color("8a5a32"), outline)
			_ball(top, 18.0, Element.color(data.element).lightened(0.35), outline)
		FighterData.Role.TITAN:
			# Tall tower shield on the left arm.
			var rect_c := hand_l + Vector2(-10, -h * 0.12)
			_capsule(rect_c + Vector2(0, -h * 0.2), rect_c + Vector2(0, h * 0.14), w * 0.62, col.darkened(0.3), outline)
			if not outline:
				_capsule(rect_c + Vector2(0, -h * 0.16), rect_c + Vector2(0, h * 0.1), w * 0.36, col.lightened(0.15), false)
				draw_circle(rect_c, w * 0.09, Color("e3e9f0"))
		FighterData.Role.SPECTRE:
			# Twin daggers, one in each hand, pointing out.
			for hand in [hand_l, hand_r]:
				var out := Vector2(signf(hand.x) * w * 0.55, -h * 0.16)
				_capsule(hand, hand + out, 9.0, Color("cfd6e6"), outline)


# ---------------------------------------------------------------- enemy

func _draw_enemy(outline: bool) -> void:
	var h := data.figure_height
	var w := data.figure_width
	var col := data.body_color
	var accent := Element.color(data.element) if data.element != Element.Type.NONE else Color("ff3b3b")

	# Stubby feet.
	for side in [-1.0, 1.0]:
		_capsule(Vector2(side * w * 0.2, -18), Vector2(side * w * 0.3, -14), 44.0, col.darkened(0.3), outline)
	# Claws / arms.
	for side in [-1.0, 1.0]:
		_ball(Vector2(side * w * 0.47, -h * 0.32), w * 0.2, col.darkened(0.15), outline)
	# Horns.
	for side in [-1.0, 1.0]:
		_tri([Vector2(side * w * 0.16, -h * 0.78), Vector2(side * w * 0.4, -h * 1.02), Vector2(side * w * 0.32, -h * 0.72)], Color("d9d2c3"), outline)
	# Big round body.
	_ball(Vector2(0, -h * 0.45), w * 0.48, col, outline)

	if outline:
		return
	# Belly.
	draw_circle(Vector2(0, -h * 0.33), w * 0.28, col.lightened(0.12))
	# Glowing eyes in the enemy's element colour + angry brows.
	for side in [-1.0, 1.0]:
		var eye := Vector2(side * w * 0.16, -h * 0.58)
		draw_circle(eye, w * 0.11, Color(accent, 0.25))
		draw_circle(eye, w * 0.075, accent.darkened(0.2))
		draw_circle(eye, w * 0.05, accent.lightened(0.4))
		draw_line(Vector2(side * w * 0.28, -h * 0.67), Vector2(side * w * 0.05, -h * 0.62), OUTLINE, 10.0)
	# Mouth with teeth.
	var mouth := Rect2(-w * 0.2, -h * 0.45, w * 0.4, h * 0.08)
	draw_rect(mouth, Color(0.12, 0.02, 0.06))
	var teeth := 5
	for i in teeth:
		var x0 := mouth.position.x + mouth.size.x * i / teeth
		var x1 := mouth.position.x + mouth.size.x * (i + 1) / teeth
		draw_colored_polygon(PackedVector2Array([
			Vector2(x0, mouth.position.y),
			Vector2(x1, mouth.position.y),
			Vector2((x0 + x1) * 0.5, mouth.position.y + mouth.size.y * 0.55),
		]), Color("f2eee4"))
	# Sheen on the body.
	draw_circle(Vector2(-w * 0.2, -h * 0.66), w * 0.1, Color(1, 1, 1, 0.1))
	_draw_badge(Vector2(w * 0.52, -h * 0.92))


# ---------------------------------------------------------------- Act 1 enemy kinds

func _accent() -> Color:
	return Element.color(data.element) if data.element != Element.Type.NONE else Color("ff3b3b")


## Glowing eye in the element colour.
func _eye(center: Vector2, r: float) -> void:
	var a := _accent()
	draw_circle(center, r * 1.5, Color(a, 0.25))
	draw_circle(center, r, a.darkened(0.2))
	draw_circle(center, r * 0.6, a.lightened(0.45))


## Hovering drone: round body, one big lens, two rotor arms, an antenna.
func _draw_drone(outline: bool) -> void:
	var h := data.figure_height
	var w := data.figure_width
	var col := data.body_color
	var body := Vector2(0, -h * 0.6)
	for side in [-1.0, 1.0]:
		var rotor := body + Vector2(side * w * 0.46, -h * 0.12)
		_capsule(body, rotor, 14.0, col.darkened(0.35), outline)
		_capsule(rotor + Vector2(-w * 0.14, 0), rotor + Vector2(w * 0.14, 0), 10.0, Color("c9c4b8"), outline)
	_capsule(body + Vector2(0, -w * 0.3), body + Vector2(0, -w * 0.48), 6.0, col.darkened(0.3), outline)
	_ball(body + Vector2(0, -w * 0.5), 9.0, _accent(), outline)
	_ball(body, w * 0.32, col, outline)
	if outline:
		return
	draw_circle(body + Vector2(0, w * 0.04), w * 0.17, Color(0.05, 0.04, 0.08))
	_eye(body + Vector2(0, w * 0.04), w * 0.1)
	draw_circle(body + Vector2(-w * 0.12, -w * 0.14), w * 0.06, Color(1, 1, 1, 0.18))
	_draw_badge(body + Vector2(w * 0.34, -w * 0.3))


## Slime: a wobbly dome with two eyes and a drip.
func _draw_slime(outline: bool) -> void:
	var h := data.figure_height
	var w := data.figure_width
	var col := data.body_color
	_capsule(Vector2(-w * 0.32, -h * 0.18), Vector2(w * 0.32, -h * 0.18), h * 0.36, col.darkened(0.1), outline)
	_ball(Vector2(0, -h * 0.45), w * 0.36, col, outline)
	_ball(Vector2(w * 0.3, -h * 0.05), 14.0, col.darkened(0.1), outline)
	if outline:
		return
	draw_circle(Vector2(-w * 0.14, -h * 0.66), w * 0.08, Color(1, 1, 1, 0.25))
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * w * 0.13, -h * 0.45), w * 0.07, Color(0.05, 0.04, 0.08))
		_eye(Vector2(side * w * 0.13, -h * 0.45), w * 0.04)
	draw_arc(Vector2(0, -h * 0.34), w * 0.1, 0.3, PI - 0.3, 12, Color(0.05, 0.04, 0.08), 5.0)
	_draw_badge(Vector2(w * 0.4, -h * 0.82))


## Human enemy. Foreman = hard hat + plasma whip. Thief = hood + dagger.
func _draw_enemy_human(outline: bool) -> void:
	var h := data.figure_height
	var w := data.figure_width
	var col := data.body_color
	var thief := data.kind == &"thief"
	var head_r := h * 0.085
	var head_c := Vector2(0, -h + head_r * 1.4)
	var shoulder_y := head_c.y + head_r * 1.6
	var hip_y := -h * 0.42
	for side in [-1.0, 1.0]:
		_capsule(Vector2(side * w * 0.17, hip_y), Vector2(side * w * 0.2, -14), w * 0.24, col.darkened(0.45), outline)
	_capsule(Vector2(0, shoulder_y + w * 0.3), Vector2(0, hip_y - w * 0.1), w * 0.62, col, outline)
	var hand_l := Vector2(-w * 0.5, hip_y + h * 0.02)
	var hand_r := Vector2(w * 0.5, hip_y - h * 0.04)
	for hand in [hand_l, hand_r]:
		_capsule(Vector2(signf(hand.x) * w * 0.3, shoulder_y + 10), hand, w * 0.18, col.lightened(0.08), outline)
	if thief:
		_capsule(hand_r, hand_r + Vector2(w * 0.35, -h * 0.12), 8.0, Color("cfd6e6"), outline)
		_ball(head_c + Vector2(0, -head_r * 0.15), head_r * 1.35, col.darkened(0.3), outline)
		_tri([head_c + Vector2(-head_r * 0.7, -head_r * 0.9), head_c + Vector2(0, -head_r * 2.0), head_c + Vector2(head_r * 0.7, -head_r * 0.9)], col.darkened(0.3), outline)
		_ball(head_c + Vector2(0, head_r * 0.15), head_r * 0.85, Color(0.08, 0.06, 0.12), outline)
	else:
		# Plasma whip: a curved line from the right hand ending in a glowing tip.
		var pts := [hand_r, hand_r + Vector2(w * 0.5, -h * 0.05), hand_r + Vector2(w * 0.7, h * 0.12), hand_r + Vector2(w * 0.55, h * 0.3)]
		for i in pts.size() - 1:
			_capsule(pts[i], pts[i + 1], 7.0, _accent().lightened(0.2), outline)
		_ball(head_c + Vector2(0, head_r * 0.08), head_r, Color("d9a67a"), outline)
		_capsule(head_c + Vector2(-head_r * 1.2, -head_r * 0.45), head_c + Vector2(head_r * 1.2, -head_r * 0.45), head_r * 0.55, Color("e8b72e"), outline)
	if outline:
		return
	if thief:
		for side in [-1.0, 1.0]:
			_eye(head_c + Vector2(side * head_r * 0.35, head_r * 0.15), head_r * 0.13)
	else:
		for side in [-1.0, 1.0]:
			draw_circle(head_c + Vector2(side * head_r * 0.35, head_r * 0.2), head_r * 0.12, OUTLINE)
		draw_circle(hand_r + Vector2(w * 0.55, h * 0.3), 16.0, Color(_accent(), 0.4))
	_draw_badge(Vector2(w * 0.55, -h * 0.95))


## Sprout: a bulb with two leaves on top and a toothy grin.
func _draw_sprout(outline: bool) -> void:
	var h := data.figure_height
	var w := data.figure_width
	var col := data.body_color
	for side in [-1.0, 1.0]:
		_tri([Vector2(0, -h * 0.62), Vector2(side * w * 0.5, -h * 0.98), Vector2(side * w * 0.12, -h * 0.66)], col.lightened(0.15), outline)
	_capsule(Vector2(-w * 0.18, -16), Vector2(w * 0.18, -16), 22.0, col.darkened(0.4), outline)
	_ball(Vector2(0, -h * 0.36), w * 0.4, col, outline)
	if outline:
		return
	draw_circle(Vector2(-w * 0.15, -h * 0.5), w * 0.08, Color(1, 1, 1, 0.15))
	for side in [-1.0, 1.0]:
		_eye(Vector2(side * w * 0.14, -h * 0.42), w * 0.05)
	draw_rect(Rect2(-w * 0.16, -h * 0.3, w * 0.32, h * 0.06), Color(0.12, 0.04, 0.06))
	_draw_badge(Vector2(w * 0.45, -h * 0.78))


## Scrap golem: stacked boxy scrap with a glowing core.
func _draw_golem(outline: bool) -> void:
	var h := data.figure_height
	var w := data.figure_width
	var col := data.body_color
	for side in [-1.0, 1.0]:
		_box(Rect2(side * w * 0.22 - w * 0.1, -h * 0.3, w * 0.2, h * 0.3), col.darkened(0.3), outline)
		_capsule(Vector2(side * w * 0.38, -h * 0.72), Vector2(side * w * 0.46, -h * 0.36), w * 0.17, col.darkened(0.15), outline)
		_box(Rect2(side * w * 0.46 - w * 0.1, -h * 0.4, w * 0.2, h * 0.12), col.darkened(0.4), outline)
	_box(Rect2(-w * 0.32, -h * 0.78, w * 0.64, h * 0.5), col, outline)
	_box(Rect2(-w * 0.15, -h * 0.98, w * 0.3, h * 0.2), col.lightened(0.08), outline)
	if outline:
		return
	for i in 4:
		draw_line(Vector2(-w * 0.3, -h * 0.72 + i * h * 0.11), Vector2(w * 0.3, -h * 0.7 + i * h * 0.11), col.darkened(0.35), 4.0)
	draw_circle(Vector2(0, -h * 0.55), w * 0.11, Color(0.05, 0.04, 0.08))
	_eye(Vector2(0, -h * 0.55), w * 0.07)
	draw_rect(Rect2(-w * 0.1, -h * 0.9, w * 0.2, h * 0.04), _accent())
	_draw_badge(Vector2(w * 0.42, -h * 0.95))


## Plasma wolf: four legs, long body, head facing left, glowing mane and tail.
func _draw_wolf(outline: bool) -> void:
	var h := data.figure_height
	var w := data.figure_width
	var col := data.body_color
	var a := _accent()
	var back_y := -h * 0.52
	_capsule(Vector2(w * 0.28, back_y), Vector2(w * 0.48, -h * 0.85), 22.0, a, outline)          # tail
	for x in [-0.26, -0.14, 0.16, 0.28]:
		_capsule(Vector2(w * x, back_y + 20), Vector2(w * x - 6, -10), 30.0, col.darkened(0.25), outline)
	_capsule(Vector2(-w * 0.22, back_y), Vector2(w * 0.26, back_y), h * 0.3, col, outline)          # body
	var head := Vector2(-w * 0.36, -h * 0.7)
	_capsule(head, head + Vector2(-w * 0.12, h * 0.08), h * 0.13, col.lightened(0.05), outline)     # snout
	for side in [-1.0, 1.0]:
		_tri([head + Vector2(side * 22 - 4, -h * 0.08), head + Vector2(side * 30, -h * 0.28), head + Vector2(side * 4 + 6, -h * 0.12)], col.darkened(0.2), outline)
	_ball(head, h * 0.15, col, outline)
	if outline:
		return
	for i in 6:   # glowing plasma mane along the back
		draw_circle(Vector2(lerpf(-w * 0.26, w * 0.2, i / 5.0), back_y - h * 0.15), 14.0 - i, Color(a.lightened(0.3), 0.85))
	_eye(head + Vector2(-h * 0.05, -h * 0.02), h * 0.03)
	draw_circle(head + Vector2(-w * 0.17, h * 0.08), 6.0, OUTLINE)
	_draw_badge(Vector2(w * 0.4, -h * 1.0))


func _box(r: Rect2, color: Color, outline: bool) -> void:
	if outline:
		draw_rect(r.grow(OUTLINE_WIDTH), OUTLINE)
	else:
		draw_rect(r, color)


# ---------------------------------------------------------------- helpers

## Small circle with the element symbol, so the element is readable without colour.
func _draw_badge(center: Vector2) -> void:
	if data.element == Element.Type.NONE:
		return
	var c := Element.color(data.element)
	draw_circle(center, 27.0, OUTLINE)
	draw_circle(center, 23.0, c.darkened(0.15))
	ElementIcons.draw_icon(self, data.element, center + Vector2(0, 1), 14.0, Color.WHITE, c.darkened(0.6))


## A thick line with round ends.
func _capsule(a: Vector2, b: Vector2, width: float, color: Color, outline: bool) -> void:
	var wd := width + (OUTLINE_WIDTH * 2.0 if outline else 0.0)
	var c := OUTLINE if outline else color
	draw_line(a, b, c, wd)
	draw_circle(a, wd * 0.5, c)
	draw_circle(b, wd * 0.5, c)


func _ball(center: Vector2, radius: float, color: Color, outline: bool) -> void:
	if outline:
		draw_circle(center, radius + OUTLINE_WIDTH, OUTLINE)
	else:
		draw_circle(center, radius, color)


func _tri(points: Array, color: Color, outline: bool) -> void:
	var pts := PackedVector2Array(points)
	if outline:
		var centre := (pts[0] + pts[1] + pts[2]) / 3.0
		for i in pts.size():
			pts[i] = centre + (pts[i] - centre) * 1.3
	draw_colored_polygon(pts, OUTLINE if outline else color)
