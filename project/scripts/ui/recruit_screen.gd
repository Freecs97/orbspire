class_name RecruitScreen
extends HomePage
## RECRUIT: spend Credits (or a Key) on a random character.
##
## Plain English: any of the 20 characters can come out (so a random type AND
## affinity), with a random rarity. Pricier tiers have better odds, a Key pull
## has the best odds. Odds depend on how far you are (rarity bands by Act, see
## data/economy.tres). The odds are always shown on this screen.
## Duplicates are allowed (retire them in the Roster for Training Cores).

signal changed

var profile: Profile
var tier_buttons: Array[Button] = []
var odds_label: Label
var keys_label: Label
var reveal: Control
var reveal_card: UnitCard
var reveal_text: Label
var reveal_ok: Button
var last_result: Dictionary = {}


func _init() -> void:
	_setup_page("RECRUIT")
	var bg := ColorRect.new()
	bg.color = Color("0b0b14")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var title := make_label(56, Color.WHITE)
	title.text = "RECRUIT"
	title.position = Vector2(40, 160)
	keys_label = make_label(32, GOLD)
	keys_label.position = Vector2(40, 240)
	for i in 4:
		var b := make_button("", Vector2(90, 310 + i * 150), Vector2(900, 120), 36, GOLD if i == 3 else MenuStyle.NEON)
		b.pressed.connect(_on_recruit.bind(i))
		tier_buttons.append(b)
	odds_label = make_label(26, Color("cfc8ee"))
	odds_label.position = Vector2(60, 930)
	odds_label.size = Vector2(960, 600)
	odds_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	reveal = Control.new()
	reveal.visible = false
	reveal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(reveal)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.95)
	dim.size = Vector2(1080, 2600)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal.add_child(dim)
	reveal_card = UnitCard.new()
	reveal_card.position = Vector2(240, 260)
	reveal.add_child(reveal_card)
	reveal_text = make_label(44, Color.WHITE, reveal)
	reveal_text.position = Vector2(0, 1030)
	reveal_text.size = Vector2(1080, 200)
	reveal_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reveal_ok = make_button("OK", Vector2(290, 1260), Vector2(500, 110), 40, MenuStyle.NEON, reveal)
	reveal_ok.pressed.connect(func() -> void:
		reveal.visible = false
		refresh())
	_build_bars()


func refresh() -> void:
	var e := Profile.ECONOMY
	set_bar_values(profile.data["credits"], profile.data["cores"], profile.highest_level())
	keys_label.text = "KEYS: %d   ·   Roster %d / %d" % [profile.data["keys"], profile.data["units"].size(), profile.data["roster_cap"]]
	var act := profile.progress_act()
	for i in 3:
		tier_buttons[i].text = "%s RECRUIT  ·  %d Credits" % [e.recruit_names[i].to_upper(), e.recruit_costs[i]]
	tier_buttons[3].text = "KEY RECRUIT  ·  1 Key  (up to %s)" % e.rarity_names[e.best_rarity(3, act)]
	var band := e.band_for_act(act)
	var last_act := e.band_first_act[band + 1] - 1 if band + 1 < e.band_first_act.size() else 10
	var lines := PackedStringArray(["ODDS (%%) for Acts %d-%d (you have unlocked Act %d):" % [e.band_first_act[band], mini(last_act, 10), mini(act, 10)]])
	if act > 10:
		lines = PackedStringArray(["ODDS (%) for Galaxies 2-10 (your team has reached Lv31+):"])
	for i in 4:
		var odds := e.odds_for(i, act)
		var parts := PackedStringArray()
		for r in 6:
			if odds[r] > 0:
				parts.append("%s %d" % [e.rarity_names[r], odds[r]])
		lines.append("%s:  %s" % ["Key" if i == 3 else e.recruit_names[i], "  ·  ".join(parts)])
	lines.append("\nBetter rarities unlock as you clear Acts: Prime from Act 3, Ascendant from Act 5, Singularity from Act 7 (Key only).")
	lines.append("Galaxies 2-10: once your team is Lv31+, Singularity can also come from Advanced and Elite Recruit.")
	lines.append("Keys: 1 for the first clear of each Act. Any of the 20 characters can appear. Duplicates are allowed.")
	odds_label.text = "\n".join(lines)


func _on_recruit(tier: int) -> void:
	var why := profile.can_recruit(tier)
	if why != "":
		show_toast(why)
		return
	var had := {}
	for u in profile.data["units"]:
		had[u["id"]] = true
	last_result = profile.recruit(tier)
	var u := profile.unit(last_result["uid"])
	reveal_card.show_unit(u, false, Vector2(600, 740))
	reveal_text.text = "%s  ·  %s\n%s%s" % [Catalog.display_name(u["id"]), Catalog.template(u["id"]).title, Catalog.rarity_name(u["rarity"]).to_upper(),
		"  ·  DUPLICATE" if had.has(u["id"]) else "  ·  NEW!"]
	reveal_text.label_settings.font_color = Catalog.rarity_color(u["rarity"]).lightened(0.2)
	reveal.visible = true
	reveal.modulate.a = 0.0
	reveal_card.scale = Vector2(0.6, 0.6)
	reveal_card.pivot_offset = Vector2(300, 370)
	var tw := create_tween().set_parallel()
	tw.tween_property(reveal, "modulate:a", 1.0, 0.25)
	tw.tween_property(reveal_card, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	changed.emit()
