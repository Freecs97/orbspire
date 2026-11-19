class_name UnitCard
extends Button
## One character as a tappable card: your art, name, level, and a border in
## its rarity colour (Scrap grey ... Singularity gold). Shows a padlock if locked
## and a LEADER tag if asked.

var uid := -1
var _art: TextureRect
var _name: Label
var _kind: Label   ## what they are, e.g. "Fire Berserker"
var _info: Label
var _tag: Label


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	clip_contents = true
	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_name = _lbl(22, Color.WHITE)
	_kind = _lbl(18, Color("cfc8ee"))
	_info = _lbl(22, Color("ffd23f"))
	_tag = _lbl(20, Color("1a1206"))


## Fill the card. unit = a Profile unit dictionary (or {} for an empty slot).
func show_unit(unit: Dictionary, leader := false, card_size := Vector2(220, 300)) -> void:
	size = card_size
	custom_minimum_size = card_size
	uid = int(unit.get("uid", -1))
	var rarity := int(unit.get("rarity", 0))
	var border := Catalog.rarity_color(rarity) if not unit.is_empty() else Color(0.35, 0.35, 0.42)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("12121a")
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(4 if rarity >= 4 else 3)
	sb.border_color = border
	sb.shadow_color = Color(border, 0.35 if rarity >= 3 else 0.0)
	sb.shadow_size = 12 if rarity >= 3 else 0
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(s, sb)
	if unit.is_empty():
		_art.texture = null
		_name.text = "EMPTY"
		_kind.text = ""
		_info.text = "tap to fill"
		_tag.visible = false
	else:
		var t := Catalog.template(unit["id"])
		var stage := int(unit.get("stage", 1))
		_art.texture = Catalog.art(unit["id"], stage)
		_name.text = t.display_name
		_kind.text = t.title + ("  ·  Stage %d" % stage if stage > 1 else "")
		_name.label_settings.font_color = Element.color(t.element).lightened(0.35)
		_info.text = "Lv%d  ·  %s%s" % [unit["level"], Catalog.rarity_name(rarity), "  · LOCK" if unit.get("locked", false) else ""]
		_info.label_settings.font_color = border.lightened(0.2)
		_tag.visible = leader
		_tag.text = " LEADER "
	_art.position = Vector2(8, 8)
	_art.size = Vector2(card_size.x - 16, card_size.y - 100)
	_name.position = Vector2(0, card_size.y - 90)
	_name.size = Vector2(card_size.x, 30)
	_kind.position = Vector2(0, card_size.y - 62)
	_kind.size = Vector2(card_size.x, 26)
	_info.position = Vector2(0, card_size.y - 38)
	_info.size = Vector2(card_size.x, 30)
	_tag.position = Vector2(8, 8)
	var tag_box := StyleBoxFlat.new()
	tag_box.bg_color = Color("ffd23f")
	tag_box.set_corner_radius_all(8)
	_tag.add_theme_stylebox_override("normal", tag_box)


func _lbl(font: int, color: Color) -> Label:
	var l := Label.new()
	var s := LabelSettings.new()
	s.font_size = font
	s.font_color = color
	s.outline_size = 5
	s.outline_color = Color(0.02, 0.01, 0.06)
	l.label_settings = s
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.clip_text = true
	add_child(l)
	return l
