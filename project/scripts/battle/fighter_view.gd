class_name FighterView
extends Node2D
## One fighter on screen.
##
## Plain English: hunters are HEAD-ONLY plates (Stage 4): a rounded plate with a
## glowing border in their element colour, their face cropped from their own art,
## a slim HP bar, the skill-charge badge and a LEADER tag. Full-body art is for
## the Roster / detail screens. Enemies have no plate, just a ground shadow, and
## show a yellow target ring when you tap them. The shared FighterAnimator moves
## the art (lunge on attack, flash on hit); idle = still.

const DEFAULT_CARD := Vector2(200, 236)
const TARGET_COLOR := Color("ffd23f")
## Head plate layout (relative to the plate's feet point, like the old card).
const FACE_SIZE := 172.0
const FACE_CENTER := Vector2(0, -120)

var data: FighterData
var figure: Node2D          ## ArtFigure (your PNG) or PlaceholderFigure (code shapes)
var animator: FighterAnimator
var card_size := DEFAULT_CARD

## 0 = normal card, 1 = fully lit. Animated by light_up().
var highlight := 0.0:
	set(value):
		highlight = value
		queue_redraw()

## Enemy only: draw the target ring.
var targeted := false:
	set(value):
		targeted = value
		queue_redraw()

## Hunter only: active-skill charge. -1 = no skill. 0 = ready.
var skill_turns := -1
var skill_max := 1
## Hunter only: slot 1 shows a LEADER tag.
var is_leader := false
## Hunter only: the plate's HP bar (the team shares one HP pool, so every
## plate shows the team's HP). -1 = no bar.
var hp_ratio := -1.0:
	set(value):
		if not is_equal_approx(value, hp_ratio):
			hp_ratio = value
			queue_redraw()
## Enemy only: armour is up (draws a shield badge on the enemy).
var armor_up := false:
	set(value):
		armor_up = value
		queue_redraw()

var _glow_tween: Tween
var _ring_spin := 0.0
var _pulse := 0.0
var _overlay: Node2D


## Update the skill charge badge on the card.
func set_skill(turns_left: int, max_turns: int) -> void:
	skill_turns = turns_left
	skill_max = maxi(max_turns, 1)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW and _overlay:
		_overlay.queue_redraw()


func skill_is_ready() -> bool:
	return skill_turns == 0


## Call after this node has been added to the scene.
func setup(fighter: FighterData) -> void:
	if fighter.art:
		var art := ArtFigure.new()
		if not fighter.is_enemy():
			art.head_size = FACE_SIZE      # head-only plate
			art.head_center = FACE_CENTER
		figure = art
	else:
		figure = PlaceholderFigure.new()
	add_child(figure)
	# The skill badge and LEADER tag live on a layer ABOVE the body, so a big
	# weapon or your final art never covers them.
	_overlay = Node2D.new()
	add_child(_overlay)
	_overlay.draw.connect(_draw_overlay)
	animator = FighterAnimator.new()
	add_child(animator)
	animator.setup(figure)
	set_fighter(fighter)
	animator.play_idle()


## Swap in a different data card (e.g. the next enemy).
func set_fighter(fighter: FighterData) -> void:
	data = fighter
	figure.call("setup", fighter)
	queue_redraw()


## Make the card glow brightly, then fade back.
func light_up() -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	highlight = 1.0
	_glow_tween = create_tween()
	_glow_tween.tween_interval(0.25)
	_glow_tween.tween_property(self, "highlight", 0.0, 0.5)


## The area you can tap to select this fighter (in this node's local space).
func hit_rect() -> Rect2:
	if data == null:
		return Rect2()
	if data.is_enemy():
		var w := data.figure_width * 1.1
		return Rect2(-w * 0.5, -data.figure_height * 1.05, w, data.figure_height * 1.05 + 40.0)
	return Rect2(Vector2(-card_size.x * 0.5, -card_size.y + 22), card_size)


func _process(delta: float) -> void:
	if targeted:
		_ring_spin = fmod(_ring_spin + delta * 1.6, TAU)
		queue_redraw()
	if skill_is_ready():
		_pulse = fmod(_pulse + delta * 4.0, TAU)
		queue_redraw()


func _draw() -> void:
	if data == null:
		return
	if not data.is_enemy():
		_draw_card()
		return   # head plates have no ground shadow
	# Ground shadow (a squashed circle).
	var w := data.figure_width * (0.8 if data.is_enemy() else 0.75)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.24))
	draw_circle(Vector2.ZERO, w, Color(0, 0, 0, 0.4))
	if targeted:
		# Spinning dashed ring on the floor = "this is your target".
		for i in 8:
			var a := _ring_spin + TAU * i / 8.0
			draw_arc(Vector2.ZERO, w * 1.25, a, a + TAU / 16.0, 6, TARGET_COLOR, 14.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if targeted:
		# Little arrow above the head.
		var top := Vector2(0, -data.figure_height - 70)
		draw_colored_polygon(PackedVector2Array([top + Vector2(-22, -26), top + Vector2(22, -26), top]), TARGET_COLOR)


func _draw_card() -> void:
	var c := Element.color(data.element)
	var rect := Rect2(Vector2(-card_size.x * 0.5, -card_size.y + 22), card_size)
	# A ready skill makes the card border pulse.
	var glow := highlight
	if skill_is_ready():
		glow = maxf(glow, 0.45 + 0.35 * sin(_pulse))
	var card := StyleBoxFlat.new()
	card.bg_color = c.darkened(0.78)
	card.set_corner_radius_all(26)
	card.set_border_width_all(4 + (3 if skill_is_ready() else 0))
	card.border_color = c.lerp(Color.WHITE, glow * 0.5)
	card.shadow_color = Color(c, 0.25 + glow * 0.55)
	card.shadow_size = int(10 + glow * 26)
	draw_style_box(card, rect)
	# Dual affinity (Stage 3): a second, inner border in the SUB affinity's colour.
	if data.sub_element >= 0:
		var inner := StyleBoxFlat.new()
		inner.bg_color = Color(0, 0, 0, 0)
		inner.set_corner_radius_all(20)
		inner.set_border_width_all(4)
		inner.border_color = Element.color(data.sub_element)
		draw_style_box(inner, rect.grow(-8))
	# Face window: a slightly lighter square behind the cropped head.
	var face := StyleBoxFlat.new()
	face.bg_color = Color(c, 0.16 + highlight * 0.2)
	face.set_corner_radius_all(18)
	draw_style_box(face, Rect2(FACE_CENTER - Vector2.ONE * FACE_SIZE * 0.5, Vector2.ONE * FACE_SIZE))


## Drawn on the overlay layer (above the body): skill badge + LEADER tag.
func _draw_overlay() -> void:
	if data == null:
		return
	if data.is_enemy():
		if armor_up:
			_draw_armor_badge(Vector2(-data.figure_width * 0.5 - 6, -data.figure_height * 0.55))
		return
	var rect := Rect2(Vector2(-card_size.x * 0.5, -card_size.y + 22), card_size)
	_draw_skill_badge(rect, Element.color(data.element))
	if is_leader:
		_draw_tag(rect.position + Vector2(10, -16), "LEADER", Color("ffd23f"))
	if hp_ratio >= 0.0:
		# Slim HP bar under the face (the team's shared HP).
		var bar := Rect2(Vector2(-FACE_SIZE * 0.5, FACE_CENTER.y + FACE_SIZE * 0.5 + 4), Vector2(FACE_SIZE, 10))
		_overlay.draw_rect(bar.grow(2), Color(0.03, 0.02, 0.06))
		_overlay.draw_rect(bar, Color(0.2, 0.08, 0.1))
		var fill := Color("4dff7a") if hp_ratio > 0.5 else (Color("ffd23f") if hp_ratio > 0.25 else Color("ff5a5a"))
		_overlay.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(hp_ratio, 0.0, 1.0), bar.size.y)), fill)


## Round badge in the card's top-right corner: how charged the active skill is.
## The ring fills up as the skill charges; the number is turns left.
## When ready it shows "GO" and the whole card pulses.
func _draw_skill_badge(rect: Rect2, c: Color) -> void:
	if skill_turns < 0:
		return
	var o := _overlay
	var center := Vector2(rect.end.x - 30, rect.position.y + 30)
	var r := 24.0
	var ready := skill_is_ready()
	o.draw_circle(center, r + 4, Color(0.03, 0.02, 0.06))
	o.draw_circle(center, r, c.lightened(0.3) if ready else Color(0.08, 0.07, 0.14))
	var ratio := 1.0 - float(skill_turns) / skill_max
	if not ready and ratio > 0.0:
		o.draw_arc(center, r - 3, -PI * 0.5, -PI * 0.5 + TAU * ratio, 32, c.lightened(0.2), 6.0, true)
	var text := "GO" if ready else str(skill_turns)
	var font := ThemeDB.fallback_font
	var fs := 22 if ready else 26
	var pos := center + Vector2(-r, fs * 0.36)
	o.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, r * 2, fs, Color(0.08, 0.04, 0.02) if ready else Color.WHITE)


## A steel-blue shield with "ARMOUR" under it: this enemy takes half damage.
func _draw_armor_badge(center: Vector2) -> void:
	var o := _overlay
	var s := 30.0
	var shield := PackedVector2Array([
		center + Vector2(-s, -s), center + Vector2(s, -s), center + Vector2(s, s * 0.2),
		center + Vector2(0, s * 1.15), center + Vector2(-s, s * 0.2)])
	var rim := PackedVector2Array()
	for p in shield:
		rim.append(center + (p - center) * 1.2)
	o.draw_colored_polygon(rim, Color(0.03, 0.02, 0.06))
	o.draw_colored_polygon(shield, Color("8fd8ff"))
	o.draw_line(center + Vector2(0, -s * 0.8), center + Vector2(0, s * 0.9), Color("3a6a8a"), 6.0)
	var font := ThemeDB.fallback_font
	o.draw_string_outline(font, center + Vector2(-60, s + 34), "ARMOUR", HORIZONTAL_ALIGNMENT_CENTER, 120, 20, 5, Color(0.03, 0.02, 0.06))
	o.draw_string(font, center + Vector2(-60, s + 34), "ARMOUR", HORIZONTAL_ALIGNMENT_CENTER, 120, 20, Color("8fd8ff"))


func _draw_tag(pos: Vector2, text: String, color: Color) -> void:
	var o := _overlay
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 20
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(10)
	o.draw_style_box(box, Rect2(pos, Vector2(w, 28)))
	o.draw_string(font, pos + Vector2(10, 21), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.1, 0.06, 0.02))
