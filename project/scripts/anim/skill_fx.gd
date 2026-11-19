class_name SkillFx
extends Node2D
## Skill effects drawn in CODE only: no video, no image files.
##
## Plain English: each effect is a shape (ring, streak, flash, shield dome,
## sparkles) that grows and fades with a Tween, then deletes itself.
## battle.gd combines them per skill (e.g. Ember Lance = a fire streak from the
## hunter to the target + a ring burst on impact). Damage numbers are shown the
## moment the effect lands.

enum Kind { RING, STREAK, FLASH, DOME, SPARKLES }

## Stage 4: Leonardo FX sprite sheets (4 frames in a row, transparent PNG).
## If a sheet is in res://assets/fx/, skill hits play it (AnimatedSprite2D) on
## top of the code effects; if not, only the code effects play.
const FX_DIR := "res://assets/fx/"
const SHEET_FOR_ELEMENT := {
	Element.Type.FIRE: "fx_fire_slash", Element.Type.WATER: "fx_water_blast", Element.Type.WOOD: "fx_wood_thorn",
	Element.Type.LIGHT: "fx_light_burst", Element.Type.DARK: "fx_dark_slash",
}
const HEAL_SHEET := "fx_heal"
const SHEET_FRAMES := 4
static var _frames_cache := {}


## Is this FX sheet in the project? (e.g. "fx_fire_slash")
static func has_sheet(key: String) -> bool:
	return key != "" and ResourceLoader.exists(FX_DIR + key + ".png")


## Play an FX sheet centred on `center`: 4 frames over `time` seconds while it
## scales up and fades out. Returns false (and does nothing) if the sheet isn't there.
static func sheet(parent: Node, center: Vector2, key: String, height := 280.0, time := 0.4) -> bool:
	if not has_sheet(key):
		return false
	if not _frames_cache.has(key):
		var tex: Texture2D = load(FX_DIR + key + ".png")
		var frames := SpriteFrames.new()
		frames.add_animation("hit")
		frames.set_animation_loop("hit", false)
		frames.set_animation_speed("hit", SHEET_FRAMES / time)
		var fw := tex.get_width() / SHEET_FRAMES
		for i in SHEET_FRAMES:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * fw, 0, fw, tex.get_height())
			frames.add_frame("hit", at)
		_frames_cache[key] = frames
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = _frames_cache[key]
	spr.z_index = 31
	spr.position = center
	var s := height / float((spr.sprite_frames.get_frame_texture("hit", 0) as Texture2D).get_height())
	spr.scale = Vector2.ONE * s
	parent.add_child(spr)
	spr.play("hit")
	var tw := spr.create_tween()
	tw.tween_property(spr, "scale", Vector2.ONE * s * 1.3, time)
	tw.parallel().tween_property(spr, "modulate:a", 0.0, time).set_delay(time * 0.5)
	tw.tween_callback(spr.queue_free)
	return true

var kind := Kind.RING
var color := Color.WHITE
var a := Vector2.ZERO        ## centre / start point / top-left
var b := Vector2.ZERO        ## end point / size
var r0 := 0.0                ## ring: start radius
var r1 := 100.0              ## ring: end radius
var width := 10.0
var progress := 0.0:
	set(v):
		progress = v
		queue_redraw()
var _dots: Array[Vector2] = []


## Expanding (or shrinking, if r_to < r_from) ring.
static func ring(parent: Node, center: Vector2, c: Color, r_from: float, r_to: float, time := 0.45, w := 14.0) -> SkillFx:
	var fx := _make(parent, Kind.RING, c)
	fx.a = center
	fx.r0 = r_from
	fx.r1 = r_to
	fx.width = w
	fx._play(time)
	return fx


## A beam that shoots from `from` to `to`, then fades from the back.
static func streak(parent: Node, from: Vector2, to: Vector2, c: Color, w := 18.0, time := 0.35) -> SkillFx:
	var fx := _make(parent, Kind.STREAK, c)
	fx.a = from
	fx.b = to
	fx.width = w
	fx._play(time)
	return fx


## A coloured rectangle that flashes and fades.
static func flash(parent: Node, top_left: Vector2, rect_size: Vector2, c: Color, time := 0.4) -> SkillFx:
	var fx := _make(parent, Kind.FLASH, c)
	fx.a = top_left
	fx.b = rect_size
	fx._play(time)
	return fx


## A shield arc over the team (half ellipse), fades in, holds, fades out.
static func dome(parent: Node, center: Vector2, half_size: Vector2, c: Color, time := 0.9, w := 12.0) -> SkillFx:
	var fx := _make(parent, Kind.DOME, c)
	fx.a = center
	fx.b = half_size
	fx.width = w
	fx._play(time)
	return fx


## Small dots rising and fading (healing, orb changes).
static func sparkles(parent: Node, center: Vector2, spread: Vector2, c: Color, count := 18, time := 0.8) -> SkillFx:
	var fx := _make(parent, Kind.SPARKLES, c)
	fx.a = center
	fx.b = spread
	for i in count:
		fx._dots.append(Vector2(randf_range(-1.0, 1.0) * spread.x, randf_range(-1.0, 1.0) * spread.y))
	fx._play(time)
	return fx


static func _make(parent: Node, k: Kind, c: Color) -> SkillFx:
	var fx := SkillFx.new()
	fx.kind = k
	fx.color = c
	fx.z_index = 30
	parent.add_child(fx)
	return fx


func _play(time: float) -> void:
	progress = 0.0
	var tw := create_tween()
	tw.tween_property(self, "progress", 1.0, time)
	tw.tween_callback(queue_free)


func _draw() -> void:
	var p := progress
	var fade := clampf(1.0 - p, 0.0, 1.0)
	match kind:
		Kind.RING:
			var r := lerpf(r0, r1, 1.0 - pow(1.0 - p, 3.0))
			draw_arc(a, maxf(r, 1.0), 0.0, TAU, 64, Color(color, fade), maxf(width * (1.0 - p * 0.6), 1.0), true)
			draw_arc(a, maxf(r * 0.92, 1.0), 0.0, TAU, 64, Color(Color.WHITE, fade * 0.5), maxf(width * 0.3, 1.0), true)
		Kind.STREAK:
			var head := a.lerp(b, clampf(p * 2.2, 0.0, 1.0))
			var tail := a.lerp(b, clampf(p * 2.2 - 1.2, 0.0, 1.0))
			var alpha := clampf((1.0 - p) * 1.6, 0.0, 1.0)
			draw_line(tail, head, Color(color, alpha * 0.35), width * 2.4, true)
			draw_line(tail, head, Color(color, alpha), width, true)
			draw_line(tail, head, Color(Color.WHITE, alpha * 0.8), width * 0.35, true)
		Kind.FLASH:
			draw_rect(Rect2(a, b), Color(color, color.a * fade))
		Kind.DOME:
			var alpha := clampf(minf(p * 4.0, (1.0 - p) * 2.5), 0.0, 1.0)
			draw_set_transform(a, 0.0, Vector2(1.0, b.y / maxf(b.x, 1.0)))
			draw_arc(Vector2.ZERO, b.x, PI, TAU, 48, Color(color, alpha), width, true)
			draw_arc(Vector2.ZERO, b.x * 0.94, PI, TAU, 48, Color(color, alpha * 0.25), width * 3.0, true)
			draw_set_transform(Vector2.ZERO)
		Kind.SPARKLES:
			for d in _dots:
				var pos := a + d + Vector2(0, -p * 120.0)
				draw_circle(pos, 7.0 * (1.0 - p * 0.5), Color(color, fade))
				draw_circle(pos, 3.0, Color(Color.WHITE, fade))
