class_name Orb
extends Node2D
## One orb on the board. It draws itself with code — no image files.
##
## Plain English: a glossy ball (dark rim, coloured body, lighter top, shiny
## highlight) with a white element symbol in the middle. When you pick it up it
## glows. It knows how to slide to a new spot and how to "pop" when matched.

const RADIUS := 74.0
## Your orb art (all 6). If one is ever missing, that orb falls back to code drawing.
const ART := {
	Element.Type.FIRE: preload("res://assets/orbs/orb_fire.png"),
	Element.Type.WATER: preload("res://assets/orbs/orb_water.png"),
	Element.Type.WOOD: preload("res://assets/orbs/orb_wood.png"),
	Element.Type.LIGHT: preload("res://assets/orbs/orb_light.png"),
	Element.Type.DARK: preload("res://assets/orbs/orb_dark.png"),
	Element.Type.HEART: preload("res://assets/orbs/orb_heart.png"),
}

var orb_type: int = Element.Type.FIRE

## True while the player is holding this orb (draws a glow ring).
var held := false:
	set(value):
		held = value
		queue_redraw()

var _move_tween: Tween


func setup(type: int) -> void:
	orb_type = type
	queue_redraw()


## Slide smoothly to a position. Cancels any slide already running.
func move_to(target: Vector2, duration: float, trans: Tween.TransitionType = Tween.TRANS_QUAD, ease_type: Tween.EaseType = Tween.EASE_OUT) -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", target, duration).set_trans(trans).set_ease(ease_type)


## A skill changed this orb's type: quick white flash + bounce, then the new look.
func change_to(type: int) -> void:
	setup(type)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(2.0, 2.0, 2.0), 0.07)
	tw.parallel().tween_property(self, "scale", Vector2.ONE * 1.18, 0.07)
	tw.tween_property(self, "modulate", Color.WHITE, 0.18)
	tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Matched: swell up, shrink to nothing, then delete itself.
func pop() -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.6, 1.6, 1.6), 0.06)
	tw.parallel().tween_property(self, "scale", Vector2.ONE * 1.3, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


func _draw() -> void:
	var base := Element.color(orb_type)
	if held:
		draw_circle(Vector2.ZERO, RADIUS + 20.0, Color(base, 0.18))
		draw_circle(Vector2.ZERO, RADIUS + 10.0, Color(base.lightened(0.5), 0.4))
	# Soft drop shadow under the ball.
	draw_circle(Vector2(0, 7), RADIUS, Color(0, 0, 0, 0.35))
	if ART.has(orb_type):
		var size := RADIUS * 2.16
		draw_texture_rect(ART[orb_type], Rect2(-size * 0.5, -size * 0.5, size, size), false)
		return
	# Rim, body, and a lighter upper half = a simple 3D sphere look.
	draw_circle(Vector2.ZERO, RADIUS, base.darkened(0.5))
	draw_circle(Vector2.ZERO, RADIUS - 5.0, base.darkened(0.12))
	draw_circle(Vector2(0, -RADIUS * 0.12), RADIUS * 0.8, base)
	draw_circle(Vector2(0, -RADIUS * 0.26), RADIUS * 0.58, base.lightened(0.16))
	# Reflected light along the bottom edge (makes it look glassy).
	draw_arc(Vector2.ZERO, RADIUS - 9.0, deg_to_rad(30), deg_to_rad(150), 24, Color(base.lightened(0.55), 0.55), 4.0, true)
	# Shiny highlight: a squashed white oval at the top-left.
	draw_set_transform(Vector2(-RADIUS * 0.32, -RADIUS * 0.5), -0.5, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, RADIUS * 0.34, Color(1, 1, 1, 0.6))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Element symbol (readable without colour).
	ElementIcons.draw_icon(self, orb_type, Vector2(0, 6), RADIUS * 0.5, Color(1, 1, 1, 0.96), base.darkened(0.6))
