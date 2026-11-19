class_name TeamScreen
extends HomePage
## TEAM: pick who fights. 4 slots; slot 1 is the leader. Act 1 uses the first 3,
## Acts 2-10 use all 4.
##
## Stage 5A: tap a party member -> REPLACE / DETAILS / CLOSE.
##   REPLACE opens your Roster (sort by level / rarity / element / type) and the
##   one you pick takes the slot; the old one goes back to the Roster.
##   Picking someone already in the team swaps the two slots.
##   DETAILS opens the full detail screen (Stage 5B).
## Tapping an EMPTY slot goes straight to the Roster picker.

signal changed

var profile: Profile
var slot_cards: Array[UnitCard] = []
var menu: PartyMenu
var picker: RosterPicker
var detail: UnitDetail
var leader_text: Label


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
	sub.text = "Slot 1 leads. Act 1 uses slots 1-3; Acts 2-10 use all 4.\nTap a hunter to REPLACE them or see their DETAILS."
	sub.position = Vector2(40, 240)
	for i in 4:
		var c := UnitCard.new()
		c.position = Vector2(24 + i * 262, 340)
		c.pressed.connect(_on_slot_pressed.bind(i))
		add_child(c)
		slot_cards.append(c)
	leader_text = make_label(28, Color("ffd23f"))
	leader_text.position = Vector2(40, 720)
	leader_text.size = Vector2(1000, 200)
	leader_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_build_bars()
	# Pop-ups on top of the bars.
	menu = PartyMenu.new()
	add_child(menu)
	menu.replace_pressed.connect(open_replace)
	menu.details_pressed.connect(open_details)
	picker = RosterPicker.new()
	add_child(picker)
	picker.picked.connect(_pick)
	detail = UnitDetail.new()
	add_child(detail)
	detail.changed.connect(func() -> void:
		refresh()
		changed.emit())
	detail.message.connect(show_toast)


func refresh() -> void:
	set_bar_values(profile.data["credits"], profile.data["cores"], profile.highest_level())
	for i in 4:
		var uid: int = profile.data["team"][i] if i < profile.data["team"].size() else -1
		slot_cards[i].show_unit(profile.unit(uid) if uid != -1 else {}, i == 0, Vector2(240, 330))
	var lead := profile.unit(profile.data["team"][0]) if not profile.data["team"].is_empty() else {}
	if not lead.is_empty():
		var t := Catalog.template(lead["id"])
		leader_text.text = "LEADER: %s (%s)\n%s: %s" % [t.display_name, t.title, Skills.display_name(t.leader_skill), Skills.describe(t.leader_skill, t.element)]


## The unit in team slot i (-1 = empty).
func slot_uid(i: int) -> int:
	var t: Array = profile.data["team"]
	return int(t[i]) if i < t.size() else -1


func _on_slot_pressed(i: int) -> void:
	var uid := slot_uid(i)
	if uid >= 0 and not profile.unit(uid).is_empty():
		menu.open(i, profile.unit(uid))
	else:
		open_replace(i)


func open_replace(i: int) -> void:
	picker.open(profile, i)


func open_details(i: int) -> void:
	var uid := slot_uid(i)
	if uid >= 0:
		detail.open_unit(profile, uid)


func picker_cards() -> Array:
	return picker.cards()


func _pick(uid: int) -> void:
	var slot := picker.slot
	var old := slot_uid(slot)
	profile.set_team_slot(slot, uid)
	refresh()
	changed.emit()
	var new_name := Catalog.display_name(profile.unit(uid)["id"])
	if old >= 0 and old != uid:
		var moved: int = profile.data["team"].find(old)
		show_toast("%s is in slot %d. %s %s" % [new_name, slot + 1, Catalog.display_name(profile.unit(old)["id"]),
			"moved to slot %d" % (moved + 1) if moved >= 0 else "went back to your Roster"])
	else:
		show_toast("%s is in slot %d" % [new_name, slot + 1])
