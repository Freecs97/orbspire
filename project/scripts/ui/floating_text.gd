class_name FloatingText
extends Label
## Text that pops in, drifts upward, fades out, and then deletes itself.
## Used for damage numbers, healing numbers and "COMBO 3" popups.


## Create one. `rise` = how many pixels it drifts up.
static func spawn(parent: Node, center: Vector2, text: String, color: Color, font_size: int = 64, rise: float = 110.0, hold: float = 0.5) -> void:
	var label := FloatingText.new()
	label.text = text
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = color
	settings.outline_size = maxi(6, int(font_size / 6.0))
	settings.outline_color = Color(0.04, 0.02, 0.08)
	settings.shadow_size = 4
	settings.shadow_color = Color(0, 0, 0, 0.5)
	settings.shadow_offset = Vector2(3, 4)
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(520, font_size * 1.6)
	label.pivot_offset = label.size * 0.5
	label.position = center - label.size * 0.5
	label.z_index = 50
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	label._animate(rise, hold)


func _animate(rise: float, hold: float) -> void:
	scale = Vector2.ONE * 0.4
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE * 1.15, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.08)
	tw.parallel().tween_property(self, "position:y", position.y - rise, 0.3 + hold).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)
