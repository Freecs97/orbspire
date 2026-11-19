class_name ComboCounter
extends Label
## The big live combo counter next to the board: "COMBO 3  x1.50".
##
## Plain English: it updates on EVERY combo tick while the board resolves
## (cascades too), with the locked formula x = 1 + 0.25 x (combos - 1).
## It resets to nothing when you pick up an orb, and fades out before the
## enemies attack, so it never carries over to the enemy turn.

var count := 0
var _tween: Tween


func _init() -> void:
	var s := LabelSettings.new()
	s.font_size = 60
	s.font_color = Color.WHITE
	s.outline_size = 12
	s.outline_color = Color(0.04, 0.02, 0.08)
	s.shadow_size = 6
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_offset = Vector2(3, 4)
	label_settings = s
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	size = Vector2(900, 90)
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


static func multiplier_text(combos: int) -> String:
	return "x%.2f" % DamageCalculator.combo_multiplier(combos)


## One more combo cleared: show the new count and multiplier with a pop.
func tick(combos: int) -> void:
	count = combos
	text = "COMBO %d   %s" % [combos, multiplier_text(combos)]
	var c := Color.WHITE
	if combos >= 8:
		c = Color("ff7a3d")
	elif combos >= 5:
		c = Color("ffd23f")
	elif combos >= 3:
		c = Color("8fefff")
	label_settings.font_color = c
	visible = true
	modulate.a = 1.0
	if _tween and _tween.is_valid():
		_tween.kill()
	scale = Vector2.ONE * 1.35
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## New drag: back to zero, hidden.
func reset() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	count = 0
	text = ""
	visible = false
	scale = Vector2.ONE


## Turn's attacks are done: fade away before the enemy turn.
func fade_out() -> void:
	if not visible:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	_tween.tween_callback(reset)
