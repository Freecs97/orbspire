class_name RosterPicker
extends Control
## Stage 5A: REPLACE = look through your Roster and pick who goes into a team slot.
## Used on the Team screen and in battle.
##
## Plain English: every character you own is shown (except the one already in
## this slot). Sort by level, rarity, element or type. Tap one to put it in the
## slot. The one you replace goes back to your Roster: nothing is ever deleted.
## Picking someone who is already in another slot swaps the two.

signal picked(uid: int)
signal closed

const SORTS := ["LEVEL", "RARITY", "ELEMENT", "TYPE"]
const ELEMENT_ORDER := [Element.Type.FIRE, Element.Type.WATER, Element.Type.WOOD, Element.Type.LIGHT, Element.Type.DARK]

var profile: Profile
var slot := -1
var sort_mode := "LEVEL"
var title_label: Label
var sub_label: Label
var grid: GridContainer
var scroll: ScrollContainer
var close_button: Button
var sort_buttons := {}


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 1.0)
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
	title_label = _label(46, Color.WHITE, content)
	title_label.position = Vector2(30, 40)
	title_label.size = Vector2(1020, 60)
	sub_label = _label(26, Color("c9c2ff"), content)
	sub_label.position = Vector2(30, 106)
	sub_label.size = Vector2(1020, 76)
	sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var sort_l := _label(26, Color("8a85a8"), content)
	sort_l.text = "SORT"
	sort_l.position = Vector2(30, 214)
	for i in SORTS.size():
		var b := Button.new()
		b.text = SORTS[i]
		b.position = Vector2(130 + i * 230, 196)
		b.size = Vector2(210, 74)
		b.focus_mode = Control.FOCUS_NONE
		var mode: String = SORTS[i]
		b.pressed.connect(func() -> void:
			sort_mode = mode
			_fill())
		content.add_child(b)
		sort_buttons[mode] = b
	scroll = ScrollContainer.new()
	scroll.position = Vector2(30, 290)
	scroll.size = Vector2(1020, 1380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)
	close_button = Button.new()
	close_button.text = "CLOSE"
	close_button.position = Vector2(290, 1700)
	close_button.size = Vector2(500, 110)
	close_button.focus_mode = Control.FOCUS_NONE
	MenuStyle.apply(close_button, 36)
	close_button.pressed.connect(close)
	content.add_child(close_button)


## Pick who goes into team slot `team_slot` (0-3).
func open(p: Profile, team_slot: int) -> void:
	profile = p
	slot = team_slot
	var cur := current_uid()
	var slot_text := "slot %d%s" % [slot + 1, " (LEADER)" if slot == 0 else ""]
	if cur >= 0:
		var who := Catalog.display_name(profile.unit(cur)["id"])
		title_label.text = "REPLACE %s" % who
		sub_label.text = "Tap a hunter to put them in %s. %s goes back to your Roster (nothing is lost). Someone already in your team swaps slots." % [slot_text, who]
	else:
		title_label.text = "CHOOSE A HUNTER"
		sub_label.text = "Tap a hunter to put them in %s." % slot_text
	_fill()
	scroll.scroll_vertical = 0
	visible = true


func close() -> void:
	visible = false
	closed.emit()


## The uid now in the slot being replaced (-1 = empty).
func current_uid() -> int:
	var t: Array = profile.data["team"]
	return int(t[slot]) if slot < t.size() else -1


func cards() -> Array:
	return grid.get_children().filter(func(c: Node) -> bool: return not c.is_queued_for_deletion())


func _fill() -> void:
	for c in grid.get_children():
		c.queue_free()
	for m in sort_buttons:
		MenuStyle.apply(sort_buttons[m], 26, Color("ffd23f") if m == sort_mode else MenuStyle.NEON)
	var cur := current_uid()
	var units: Array = profile.data["units"].filter(func(u: Dictionary) -> bool: return int(u["uid"]) != cur)
	units.sort_custom(_less)
	var team: Array = profile.data["team"]
	for u in units:
		var c := UnitCard.new()
		var at := team.find(int(u["uid"]))
		c.show_unit(u, false, Vector2(240, 320))
		if at >= 0:
			c.set_tag(" IN SLOT %d " % (at + 1))
		c.pressed.connect(_pick.bind(int(u["uid"])))
		grid.add_child(c)


## Sort order for the current SORT tab (ties: higher level first).
func _less(a: Dictionary, b: Dictionary) -> bool:
	var la := int(a["level"])
	var lb := int(b["level"])
	match sort_mode:
		"RARITY":
			if a["rarity"] != b["rarity"]:
				return a["rarity"] > b["rarity"]
		"ELEMENT":
			var ea := ELEMENT_ORDER.find(Catalog.template(a["id"]).element)
			var eb := ELEMENT_ORDER.find(Catalog.template(b["id"]).element)
			if ea != eb:
				return ea < eb
		"TYPE":
			var ra := int(Catalog.template(a["id"]).role)
			var rb := int(Catalog.template(b["id"]).role)
			if ra != rb:
				return ra < rb
		_:
			if la == lb:
				return a["rarity"] > b["rarity"]
	return la > lb


func _pick(uid: int) -> void:
	visible = false
	picked.emit(uid)
	closed.emit()


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
