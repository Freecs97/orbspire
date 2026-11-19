class_name PartyMenu
extends Control
## Stage 5A: tap a party member on the Team screen -> REPLACE / DETAILS / CLOSE.
## (In battle the same choices sit on the skill pop-up, next to USE.)

signal replace_pressed(slot: int)
signal details_pressed(slot: int)
signal closed

var slot := -1
var pic: TextureRect
var title: Label
var sub: Label
var replace_button: Button
var details_button: Button
var close_button: Button


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.06, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var content := Control.new()
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.offset_left = -540
	content.offset_right = 540
	content.offset_top = -960
	content.offset_bottom = 960
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("161a30")
	sb.set_corner_radius_all(32)
	sb.set_border_width_all(4)
	sb.border_color = Color("6b5fd8")
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(80, 520)
	panel.size = Vector2(920, 820)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(panel)
	pic = TextureRect.new()
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.position = Vector2(120, 560)
	pic.size = Vector2(220, 220)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(pic)
	title = _label(50, Color.WHITE, content)
	title.position = Vector2(370, 580)
	title.size = Vector2(600, 70)
	sub = _label(28, Color("c9c2ff"), content)
	sub.position = Vector2(370, 660)
	sub.size = Vector2(600, 120)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	replace_button = _button("REPLACE", Vector2(140, 820), Color("ffd23f"), content)
	replace_button.pressed.connect(func() -> void:
		var s := slot
		visible = false
		replace_pressed.emit(s))
	details_button = _button("DETAILS", Vector2(140, 970), MenuStyle.NEON, content)
	details_button.pressed.connect(func() -> void:
		var s := slot
		visible = false
		details_pressed.emit(s))
	close_button = _button("CLOSE", Vector2(140, 1120), Color("8a85a8"), content)
	close_button.pressed.connect(func() -> void:
		visible = false
		closed.emit())


## Party member in team slot `team_slot` (unit = its Profile unit dictionary).
func open(team_slot: int, unit: Dictionary) -> void:
	slot = team_slot
	var t := Catalog.template(unit["id"])
	pic.texture = Catalog.art(unit["id"], int(unit.get("stage", 1)))
	title.text = t.display_name
	title.label_settings.font_color = Element.color(t.element).lightened(0.35)
	sub.text = "%s  ·  Lv%d  ·  %s\nSlot %d%s" % [t.title, unit["level"], Catalog.rarity_name(int(unit["rarity"])), slot + 1, "  ·  LEADER" if slot == 0 else ""]
	visible = true


func _label(font_size: int, color: Color, parent: Node) -> Label:
	var l := Label.new()
	var s := LabelSettings.new()
	s.font_size = font_size
	s.font_color = color
	s.outline_size = 6
	s.outline_color = Color(0.02, 0.01, 0.06)
	l.label_settings = s
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _button(text: String, pos: Vector2, neon: Color, parent: Node) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(800, 120)
	b.focus_mode = Control.FOCUS_NONE
	MenuStyle.apply(b, 44, neon)
	parent.add_child(b)
	return b
