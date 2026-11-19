class_name TeamScreen
extends HomePage
## TEAM: pick who fights. 4 slots; slot 1 is the leader. Act 1 uses the first 3,
## Acts 2-10 use all 4. Tap a slot, then tap a character from your roster.
## Picking someone already in the team swaps the two slots.

signal changed

var profile: Profile
var slot_cards: Array[UnitCard] = []
var picker: Control
var picker_grid: GridContainer
var picker_close: Button
var leader_text: Label
var _picking_slot := -1


func _init() -> void:
	_setup_page("TEAM")
	var bg := ColorRect.new()
	bg.color = Color("0b0b14")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var title := make_label(56, Color.WHITE)
	title.text = "TEAM"
	title.position = Vector2(40, 160)
	var sub := make_label(26, Color("a9a3c9"))
	sub.text = "Slot 1 leads. Act 1 uses slots 1-3; Acts 2-10 use all 4.\nTap a slot to choose who fights there."
	sub.position = Vector2(40, 240)
	for i in 4:
		var c := UnitCard.new()
		c.position = Vector2(24 + i * 262, 340)
		c.pressed.connect(_open_picker.bind(i))
		add_child(c)
		slot_cards.append(c)
	leader_text = make_label(28, Color("ffd23f"))
	leader_text.position = Vector2(40, 720)
	leader_text.size = Vector2(1000, 200)
	leader_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	picker = Control.new()
	picker.visible = false
	picker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(picker)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.97)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1080, 2600)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picker.add_child(dim)
	var ptitle := make_label(40, Color.WHITE, picker)
	ptitle.text = "CHOOSE A HUNTER"
	ptitle.position = Vector2(40, 160)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(30, 230)
	scroll.size = Vector2(1020, 1300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	picker.add_child(scroll)
	picker_grid = GridContainer.new()
	picker_grid.columns = 4
	picker_grid.add_theme_constant_override("h_separation", 16)
	picker_grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(picker_grid)
	picker_close = make_button("CLOSE", Vector2(290, 1560), Vector2(500, 100), 36, MenuStyle.NEON, picker)
	picker_close.pressed.connect(func() -> void: picker.visible = false)
	_build_bars()


func refresh() -> void:
	set_bar_values(profile.data["credits"], profile.data["cores"], profile.highest_level())
	for i in 4:
		var uid: int = profile.data["team"][i] if i < profile.data["team"].size() else -1
		slot_cards[i].show_unit(profile.unit(uid) if uid != -1 else {}, i == 0, Vector2(240, 330))
	var lead := profile.unit(profile.data["team"][0]) if not profile.data["team"].is_empty() else {}
	if not lead.is_empty():
		var t := Catalog.template(lead["id"])
		leader_text.text = "LEADER: %s (%s)\n%s: %s" % [t.display_name, t.title, Skills.display_name(t.leader_skill), Skills.describe(t.leader_skill, t.element)]
	picker.size = size


func _open_picker(slot: int) -> void:
	_picking_slot = slot
	for c in picker_grid.get_children():
		c.queue_free()
	var units: Array = profile.data["units"].duplicate()
	units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["level"] > b["level"] or (a["level"] == b["level"] and a["rarity"] > b["rarity"]))
	for u in units:
		var c := UnitCard.new()
		c.show_unit(u, false, Vector2(240, 320))
		c.pressed.connect(_pick.bind(int(u["uid"])))
		picker_grid.add_child(c)
	picker.visible = true


func picker_cards() -> Array:
	return picker_grid.get_children().filter(func(c: Node) -> bool: return not c.is_queued_for_deletion())


func _pick(uid: int) -> void:
	profile.set_team_slot(_picking_slot, uid)
	picker.visible = false
	refresh()
	changed.emit()
