class_name ArtFigure
extends Node2D
## A fighter drawn from YOUR art (a transparent PNG) instead of code shapes.
##
## Plain English: the PNG sits on a Sprite2D inside this node, scaled so it is
## `figure_height` pixels tall with its feet on the ground (0, 0). The shared
## FighterAnimator moves and scales THIS node, never the sprite, so the art keeps
## its size, and the white hit-flash shader passes down to the sprite.

var data: FighterData
var sprite: Sprite2D


func setup(fighter: FighterData) -> void:
	data = fighter
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.use_parent_material = true   # so the hit flash shows on the art
		add_child(sprite)
	sprite.texture = fighter.art
	var h := float(fighter.art.get_height())
	var s := fighter.figure_height / h
	sprite.scale = Vector2(s, s)
	sprite.position = Vector2(0, -fighter.figure_height * 0.5)
	queue_redraw()


func _draw() -> void:
	if data == null or not data.is_enemy():
		return
	# Small element badge next to an enemy, like the placeholder bodies have.
	var c := Element.color(data.element)
	var center := Vector2(data.figure_width * 0.5, -data.figure_height * 0.85)
	draw_circle(center, 27.0, Color(0.06, 0.05, 0.1))
	draw_circle(center, 23.0, c.darkened(0.15))
	ElementIcons.draw_icon(self, data.element, center + Vector2(0, 1), 14.0, Color.WHITE, c.darkened(0.6))
