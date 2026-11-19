class_name FighterAnimator
extends Node
## ONE reusable, Tween-only animator for every character AND the enemy.
##
## Plain English: it moves a "body" node around with code. To stop animations
## fighting each other, it keeps two separate offsets and adds them up:
##   action_offset - the attack lunge
##   shake_offset  - the jitter when hit
## A tiny shader makes the body flash white when it gets hit.
## IDLE = STANDING STILL (no bob, no float, no bounce; removed 2026-11-18 at the
## user's request). Fighters only move on attack, on hit, on skill, or on death.
##
## Why Tween-only (no AnimationPlayer)? Every fighter uses the same moves with
## different numbers. Tweens read those numbers at runtime, so one script covers
## everyone. AnimationPlayer clips are fixed keyframes and would need a copy per fighter.

const FLASH_SHADER_CODE := """
shader_type canvas_item;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash_amount);
}
"""

@export var lunge_distance := 40.0    ## Attack: pixels forward.
@export var lunge_time := 0.25        ## Attack: seconds to lunge out.
@export var return_time := 0.15       ## Attack: seconds to come back.
@export var flash_time := 0.15        ## Hit: seconds of white flash.
@export var shake_strength := 6.0     ## Hit: jitter in pixels.
@export var defeat_time := 0.8        ## Defeat: seconds to fade out.

static var _flash_shader: Shader

var body: Node2D
var action_offset := Vector2.ZERO
var shake_offset := Vector2.ZERO
var flash_amount := 0.0:
	set(value):
		flash_amount = value
		if _material:
			_material.set_shader_parameter("flash_amount", value)

var _material: ShaderMaterial
var _action_tween: Tween
var _flash_tween: Tween
var _shake_tween: Tween
var _defeat_tween: Tween


## Call once, after this node is in the scene, with the node to animate.
func setup(target: Node2D) -> void:
	body = target
	if _flash_shader == null:
		_flash_shader = Shader.new()
		_flash_shader.code = FLASH_SHADER_CODE
	_material = ShaderMaterial.new()
	_material.shader = _flash_shader
	body.material = _material


func _process(_delta: float) -> void:
	if body:
		body.position = action_offset + shake_offset


## Idle: stand still. (No bob, no float, no bounce.)
func play_idle() -> void:
	action_offset = Vector2.ZERO
	shake_offset = Vector2.ZERO


## Attack: lunge toward `direction` (UP for the team, DOWN for the enemy), then return.
func play_attack(direction: Vector2) -> void:
	_kill(_action_tween)
	_action_tween = create_tween()
	_action_tween.tween_property(self, "action_offset", direction.normalized() * lunge_distance, lunge_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(body, "scale", Vector2.ONE * 1.05, lunge_time)
	_action_tween.tween_property(self, "action_offset", Vector2.ZERO, return_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_action_tween.parallel().tween_property(body, "scale", Vector2.ONE, return_time)


## Hit: white flash + small shake.
func play_hit() -> void:
	_kill(_flash_tween)
	_kill(_shake_tween)
	flash_amount = 1.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "flash_amount", 0.0, flash_time)
	_shake_tween = create_tween()
	var step := flash_time / 5.0
	for i in 4:
		var jitter := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength
		_shake_tween.tween_property(self, "shake_offset", jitter, step)
	_shake_tween.tween_property(self, "shake_offset", Vector2.ZERO, step)


## Defeat: shrink slightly and fade out.
func play_defeat() -> void:
	_kill(_defeat_tween)
	_defeat_tween = create_tween()
	_defeat_tween.tween_property(body, "modulate:a", 0.0, defeat_time)
	_defeat_tween.parallel().tween_property(body, "scale", Vector2.ONE * 0.9, defeat_time)


## Back to normal (used when a battle restarts).
func reset() -> void:
	for t in [_action_tween, _flash_tween, _shake_tween, _defeat_tween]:
		_kill(t)
	action_offset = Vector2.ZERO
	shake_offset = Vector2.ZERO
	flash_amount = 0.0
	body.modulate.a = 1.0
	body.scale = Vector2.ONE
	play_idle()


func _kill(t: Tween) -> void:
	if t and t.is_valid():
		t.kill()
