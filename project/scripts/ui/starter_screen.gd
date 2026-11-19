class_name StarterScreen
extends HomePage
## NEW GAME: pick your ONE starter before the tutorial fight.
##
## Plain English:
##   - Three Berserkers: Kaela Rynn (Fire), Iris Vale (Water), Drek Vane (Wood).
##     Same HP / ATK / RCV, same skills. Only the element (and the art) differs.
##   - Tap a card to select it, then START AS ... -> "Are you sure?" -> YES.
##   - The choice is saved. Only a New Game (which wipes the save) changes it.
##   - Everyone else is earned in Act 1: fight drops, Recruit and the Lab.
## main.gd calls choose(), which waits for the pick and returns the character id.

signal starter_chosen(id: String)

var cards: Array[UnitCard] = []
var element_labels: Array[Label] = []
var shared_label: Label
var start_button: Button
var confirm: Control
var confirm_text: Label
var confirm_yes: Button
var confirm_no: Button
var selected := -1


func _init() -> void:
	_setup_page("START")
	var bg := ColorRect.new()
	bg.color = Color("0b0b14")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var title := make_label(58, GOLD)
	title.text = "CHOOSE YOUR STARTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 110)
	title.size = Vector2(1080, 80)
	var sub := make_label(28, Color("cfc8ee"))
	sub.text = "All three are Berserkers with the SAME stats and skills.\nOnly the element is different. Pick the one you like.\nThe rest of your team is earned in Act 1."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 210)
	sub.size = Vector2(1080, 130)
	for i in Profile.STARTERS.size():
		var id: String = Profile.STARTERS[i]
		var c := UnitCard.new()
		c.show_unit({"uid": -1, "id": id, "level": 1, "rarity": Profile.ECONOMY.story_rarity}, false, Vector2(320, 440))
		c.position = Vector2(30 + i * 350, 380)
		c.pivot_offset = Vector2(160, 220)
		c.pressed.connect(select.bind(i))
		add_child(c)
		cards.append(c)
		var t := Catalog.template(id)
		var l := make_label(24, Element.color(t.element).lightened(0.3))
		l.text = "%s\nstrong vs %s\nweak vs %s" % [Element.display_name(t.element),
			Element.display_name(_beats(t.element)), Element.display_name(Element.beaten_by(t.element))]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.position = Vector2(30 + i * 350, 835)
		l.size = Vector2(320, 110)
		element_labels.append(l)
	var panel := make_panel(Vector2(40, 975), Vector2(1000, 520), MenuStyle.NEON)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shared_label = make_label(28, Color.WHITE)
	shared_label.position = Vector2(70, 995)
	shared_label.size = Vector2(940, 480)
	shared_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var t0 := Catalog.template(Profile.STARTERS[0])
	var f := Profile.ECONOMY.rarity_stat_mult[Profile.ECONOMY.story_rarity]
	shared_label.text = "SAME FOR ALL THREE  (%s, Lv1)\nHP %d   ATK %d   RCV %d\nActive: %s  (cooldown %d)\n   %s\nLeader: %s\nPassives: %s (Lv10), %s (Evolution 1), %s (Evolution 2)" % [
		Catalog.rarity_name(Profile.ECONOMY.story_rarity), roundi(t0.max_hp * f), roundi(t0.atk * f), roundi(t0.rcv * f),
		Skills.display_name(t0.active_skill), t0.skill_cooldown(), Skills.describe(t0.active_skill), Skills.describe(t0.leader_skill),
		Skills.display_name(t0.passives[0]), Skills.display_name(t0.passives[1]), Skills.display_name(t0.passives[2])]
	start_button = make_button("TAP A STARTER", Vector2(140, 1560), Vector2(800, 130), 40, GOLD)
	start_button.disabled = true
	start_button.pressed.connect(_open_confirm)
	_build_confirm()


func _beats(element: int) -> int:
	return Element.BEATS.get(element, Element.Type.NONE)


func _build_confirm() -> void:
	confirm = Control.new()
	confirm.visible = false
	confirm.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(confirm)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	confirm.add_child(dim)
	make_panel(Vector2(90, 620), Vector2(900, 620), GOLD, confirm)
	confirm_text = make_label(34, Color.WHITE, confirm)
	confirm_text.position = Vector2(130, 660)
	confirm_text.size = Vector2(820, 380)
	confirm_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm_yes = make_button("YES, START", Vector2(130, 1080), Vector2(390, 120), 36, GOLD, confirm)
	confirm_yes.pressed.connect(_on_yes)
	confirm_no = make_button("BACK", Vector2(560, 1080), Vector2(390, 120), 36, MenuStyle.NEON, confirm)
	confirm_no.pressed.connect(func() -> void: confirm.visible = false)


## Show the screen and wait for the pick. Returns the chosen character id.
func choose() -> String:
	selected = -1
	confirm.visible = false
	_refresh()
	visible = true
	var id: String = await starter_chosen
	visible = false
	return id


func select(i: int) -> void:
	selected = i
	_refresh()


func _refresh() -> void:
	for i in cards.size():
		var on := i == selected
		cards[i].modulate = Color.WHITE if (on or selected < 0) else Color(0.5, 0.5, 0.55)
		cards[i].scale = Vector2.ONE * (1.05 if on else 1.0)
	start_button.disabled = selected < 0
	start_button.text = "TAP A STARTER" if selected < 0 else "START AS %s" % Catalog.display_name(Profile.STARTERS[selected])


func _open_confirm() -> void:
	if selected < 0:
		return
	var t := Catalog.template(Profile.STARTERS[selected])
	confirm_text.text = "Start as %s?\n%s\n\nThis can't be changed later\n(only with NEW GAME, which wipes your save)." % [t.display_name, t.title]
	confirm.visible = true


func _on_yes() -> void:
	confirm.visible = false
	starter_chosen.emit(Profile.STARTERS[selected])
