class_name CodexScreen
extends Control
## The singularity codex: one screen, optional to read.
##
## Plain English: two pages.
##   SINGULARITY - the boss's entry: what it was spliced from, what it wanted,
##                 what it cost. Locked ("???") until you kill it.
##   TIMELINE    - the history of technomancy, Year 0 to now.

var _title: Label
var _sub: Label
var _art: TextureRect
var _body: VBoxContainer
var tab_entry: Button
var tab_timeline: Button
var close_button: Button
var _act: ActData
var _story: StoryData
var _unlocked := false
var page := "entry"


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.97)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_CENTER)
	c.offset_left = -540
	c.offset_right = 540
	c.offset_top = -960
	c.offset_bottom = 960
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)

	var head := _label(30, Color("4fd8ff"))
	head.text = "CODEX"
	head.position = Vector2(60, 70)
	c.add_child(head)
	tab_entry = _button("SINGULARITY", Vector2(60, 130), Vector2(460, 90))
	tab_entry.pressed.connect(func() -> void: _show("entry"))
	c.add_child(tab_entry)
	tab_timeline = _button("TIMELINE", Vector2(560, 130), Vector2(460, 90))
	tab_timeline.pressed.connect(func() -> void: _show("timeline"))
	c.add_child(tab_timeline)

	_title = _label(64, Color.WHITE)
	_title.position = Vector2(60, 250)
	c.add_child(_title)
	_sub = _label(32, Color("ffd23f"))
	_sub.position = Vector2(60, 340)
	c.add_child(_sub)
	_art = TextureRect.new()
	_art.position = Vector2(290, 400)
	_art.size = Vector2(500, 500)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(_art)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 16)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(_body)

	close_button = _button("CLOSE", Vector2(290, 1730), Vector2(500, 110))
	close_button.pressed.connect(func() -> void: visible = false)
	c.add_child(close_button)


func open(act: ActData, unlocked: bool, story: StoryData, start_page := "entry") -> void:
	_act = act
	_story = story
	_unlocked = unlocked
	visible = true
	_show(start_page)


func _show(p: String) -> void:
	page = p
	for child in _body.get_children():
		child.queue_free()
	tab_entry.modulate = Color.WHITE if p == "entry" else Color(1, 1, 1, 0.5)
	tab_timeline.modulate = Color.WHITE if p == "timeline" else Color(1, 1, 1, 0.5)
	if p == "timeline":
		_title.text = "TIMELINE"
		_sub.text = "The history of technomancy"
		_art.texture = null
		_body.position = Vector2(60, 420)
		for i in _story.timeline_titles.size():
			_line(_story.timeline_titles[i], 36, Color("ffd23f"))
			_line(_story.timeline_texts[i], 32, Color.WHITE)
		return
	_body.position = Vector2(60, 930)
	if not _unlocked:
		_title.text = "???"
		_sub.text = "Act %d singularity" % _act.act_number
		_art.texture = null
		_line("Defeat the Act %d boss to unlock this entry." % _act.act_number, 34, Color("a9a3c9"))
		return
	_title.text = _act.singularity_name.to_upper()
	_sub.text = "%s  ·  %s  ·  %s" % [_act.singularity_kind, Element.display_name(_act.element), _act.colony_name]
	_art.texture = _act.boss_art
	if _act.codex_spliced_from == "" and _act.codex_wanted == "" and _act.codex_cost == "":
		# The story for this Act isn't written yet: show the singularity, no text.
		_line("This singularity's codex entry arrives with its Act's story.", 32, Color("a9a3c9"))
		return
	_line("SPLICED FROM", 30, Color("4fd8ff"))
	_line(_act.codex_spliced_from, 32, Color.WHITE)
	_line("WHAT IT WANTED", 30, Color("4fd8ff"))
	_line(_act.codex_wanted, 32, Color.WHITE)
	_line("WHAT IT COST", 30, Color("4fd8ff"))
	_line(_act.codex_cost, 32, Color.WHITE)


## All text currently on the page (used by the tests).
func page_text() -> String:
	var parts := PackedStringArray([_title.text, _sub.text])
	for child in _body.get_children():
		if child is Label and not child.is_queued_for_deletion():
			parts.append(child.text)
	return "\n".join(parts)


func _line(text: String, size: int, color: Color) -> void:
	var l := _label(size, color)
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(960, 0)
	_body.add_child(l)


func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	var s := LabelSettings.new()
	s.font_size = size
	s.font_color = color
	s.outline_size = 5
	s.outline_color = Color(0.02, 0.01, 0.06)
	l.label_settings = s
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, pos: Vector2, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	MenuStyle.apply(b, 38)
	return b
