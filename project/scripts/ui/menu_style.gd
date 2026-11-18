class_name MenuStyle
extends RefCounted
## The menu button look, in code only: dark panel #1A1A22 with a thin neon border.

const PANEL := Color("1a1a22")
const NEON := Color("4fd8ff")


static func apply(b: Button, font_size := 44, neon := NEON) -> void:
	b.add_theme_font_size_override("font_size", font_size)
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(s, Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	b.add_theme_stylebox_override("normal", _box(neon, 2, 0.18))
	b.add_theme_stylebox_override("hover", _box(neon.lightened(0.2), 3, 0.3))
	b.add_theme_stylebox_override("pressed", _box(neon, 3, 0.45))
	b.add_theme_stylebox_override("disabled", _box(neon.darkened(0.5), 2, 0.0))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


static func _box(border: Color, width: int, glow: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(width)
	sb.border_color = border
	sb.shadow_color = Color(border, glow)
	sb.shadow_size = 14 if glow > 0.0 else 0
	return sb
