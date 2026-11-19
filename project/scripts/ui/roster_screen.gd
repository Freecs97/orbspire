class_name RosterScreen
extends HomePage
## ROSTER: every character you own, plus the LAB (Digital Essence).
##
## Plain English:
##   - Tap a character for its full detail screen (Stage 5B, scripts/ui/unit_detail.gd):
##     full art, stats, evolution 1/3-3/3, every skill in full words, Essence, and
##     buttons to use a Training Core (+XP), evolve, lock it, or retire it (asks twice).
##   - EXPAND buys +5 roster slots with Credits. BUY CORE buys a Training Core.
##   - LAB shows your Essence for the 20 humans and the 10 playable enemies
##     (e.g. 7/10). At 10 you can CRAFT that character (Lv1, Stage 1).

signal changed

var profile: Profile
var header: Label
var expand_button: Button
var core_button: Button
var lab_button: Button
var grid: GridContainer
var lab_list: VBoxContainer
var scroll: ScrollContainer
var detail: UnitDetail
var craft_buttons := {}   ## character id -> CRAFT button
var showing_lab := false


func _init() -> void:
	_setup_page("ROSTER")
	var bg := ColorRect.new()
	bg.color = Color("0b0b14")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	header = make_label(44, Color.WHITE)
	header.position = Vector2(40, 155)
	expand_button = make_button("EXPAND +5", Vector2(40, 230), Vector2(320, 90), 28)
	expand_button.pressed.connect(_on_expand)
	core_button = make_button("BUY CORE", Vector2(380, 230), Vector2(320, 90), 28)
	core_button.pressed.connect(_on_buy_core)
	lab_button = make_button("LAB", Vector2(720, 230), Vector2(320, 90), 30, GOLD)
	lab_button.pressed.connect(func() -> void:
		showing_lab = not showing_lab
		refresh())
	scroll = ScrollContainer.new()
	scroll.position = Vector2(30, 340)
	scroll.size = Vector2(1020, 1380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var holder := VBoxContainer.new()
	scroll.add_child(holder)
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	holder.add_child(grid)
	lab_list = VBoxContainer.new()
	lab_list.add_theme_constant_override("separation", 12)
	holder.add_child(lab_list)
	_build_bars()
	detail = UnitDetail.new()
	add_child(detail)
	detail.changed.connect(func() -> void: changed.emit())
	detail.closed.connect(refresh)
	detail.message.connect(show_toast)


func refresh() -> void:
	var d := profile.data
	set_bar_values(d["credits"], d["cores"], profile.highest_level())
	var e := Profile.ECONOMY
	header.text = ("LAB  ·  Digital Essence" if showing_lab else "ROSTER  %d / %d" % [d["units"].size(), d["roster_cap"]])
	expand_button.text = "EXPAND +%d  (%d Cr)" % [e.roster_expand_slots, e.roster_expand_cost]
	core_button.text = "BUY CORE  (%d Cr)" % e.core_cost
	lab_button.text = "ROSTER" if showing_lab else "LAB"
	grid.visible = not showing_lab
	lab_list.visible = showing_lab
	for c in grid.get_children():
		c.queue_free()
	for c in lab_list.get_children():
		c.queue_free()
	craft_buttons.clear()
	if showing_lab:
		_fill_lab()
		return
	var units: Array = d["units"].duplicate()
	units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["level"] > b["level"] or (a["level"] == b["level"] and a["rarity"] > b["rarity"]))
	for u in units:
		var c := UnitCard.new()
		c.show_unit(u, false, Vector2(240, 320))
		c.pressed.connect(open_detail.bind(int(u["uid"])))
		grid.add_child(c)


func cards() -> Array:
	return grid.get_children().filter(func(c: Node) -> bool: return not c.is_queued_for_deletion())


func _fill_lab() -> void:
	var e := Profile.ECONOMY
	# Closest to crafting first.
	var ids: Array = Catalog.lab_ids()
	ids.sort_custom(func(a: String, b: String) -> bool: return int(profile.data["essence"].get(a, 0)) > int(profile.data["essence"].get(b, 0)))
	for id in ids:
		var have := int(profile.data["essence"].get(id, 0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		var pic := TextureRect.new()
		pic.texture = Catalog.art(id)
		pic.custom_minimum_size = Vector2(110, 110)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(pic)
		var l := make_label(30, Color.WHITE, row)
		var fixed := Catalog.template(id).fixed_rarity
		l.text = "%s  ·  %s%s\nEssence %d / %d" % [Catalog.display_name(id), Catalog.template(id).title,
			"  ·  %s" % Catalog.rarity_name(fixed) if fixed >= 0 else "", have, e.essence_to_craft]
		l.custom_minimum_size = Vector2(560, 110)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var b := Button.new()
		b.text = "CRAFT"
		b.custom_minimum_size = Vector2(240, 90)
		MenuStyle.apply(b, 30, GOLD)
		b.disabled = profile.can_craft(id) != ""
		b.pressed.connect(_on_craft.bind(id))
		row.add_child(b)
		craft_buttons[id] = b
		lab_list.add_child(row)


# ---------------------------------------------------------------- detail screen (Stage 5B)

func open_detail(uid: int) -> void:
	detail.open_unit(profile, uid)


func _on_expand() -> void:
	if profile.expand_roster():
		show_toast("Roster expanded")
		changed.emit()
	else:
		show_toast("Not enough Credits")
	refresh()


func _on_buy_core() -> void:
	if profile.buy_core():
		show_toast("+1 Training Core")
		changed.emit()
	else:
		show_toast("Not enough Credits")
	refresh()


func _on_craft(id: String) -> void:
	var uid := profile.craft(id)
	if uid >= 0:
		show_toast("Crafted: %s" % Catalog.display_name(id))
		changed.emit()
	refresh()
