class_name CodexScreen
extends Control
## The codex: optional to read, readable any time (from an Act clear, or CODEX on
## the map).
##
## Plain English: three pages.
##   SINGULARITY - a boss's 4-line entry: the colony, what was rationed there, what
##                 it was spliced from, why it was abandoned. Locked ("???") until
##                 you kill it. < and > browse the 10 Act singularities.
##   TIMELINE    - the history of technomancy, Year 0 to now. After Reaper-0 falls,
##                 "Year 61 · The real first splice" appears.
##   CLEANSING   - what "Cleansed" means in free exploration.

const ACTS_FOR_BROWSING := 10

var _title: Label
var _sub: Label
var _art: TextureRect
var _body: VBoxContainer
var tab_entry: Button
var tab_timeline: Button
var tab_cleansing: Button
var prev_button: Button
var next_button: Button
var close_button: Button
var _act: ActData
var _story: StoryData
var _unlocked := false
## Singularity names you have defeated (unlocks entries while browsing, and
## Reaper-0 unlocks the Year 61 timeline line).
var defeated: Array = []
## Shown under the cleansing page, e.g. "Worlds 12/744 · Singularities 11/107".
var record_text := ""
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
	tab_entry = _button("SINGULARITY", Vector2(40, 130), Vector2(320, 90))
	tab_entry.pressed.connect(func() -> void: _show("entry"))
	c.add_child(tab_entry)
	tab_timeline = _button("TIMELINE", Vector2(380, 130), Vector2(320, 90))
	tab_timeline.pressed.connect(func() -> void: _show("timeline"))
	c.add_child(tab_timeline)
	tab_cleansing = _button("CLEANSING", Vector2(720, 130), Vector2(320, 90))
	tab_cleansing.pressed.connect(func() -> void: _show("cleansing"))
	c.add_child(tab_cleansing)

	_title = _label(60, Color.WHITE)
	_title.position = Vector2(60, 245)
	c.add_child(_title)
	_sub = _label(30, Color("ffd23f"))
	_sub.position = Vector2(60, 330)
	c.add_child(_sub)
	_art = TextureRect.new()
	_art.position = Vector2(340, 385)
	_art.size = Vector2(400, 400)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(_art)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 10)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(_body)

	prev_button = _button("<  PREV", Vector2(60, 1610), Vector2(300, 100))
	prev_button.pressed.connect(func() -> void: _browse(-1))
	c.add_child(prev_button)
	next_button = _button("NEXT  >", Vector2(720, 1610), Vector2(300, 100))
	next_button.pressed.connect(func() -> void: _browse(1))
	c.add_child(next_button)
	close_button = _button("CLOSE", Vector2(290, 1740), Vector2(500, 110))
	close_button.pressed.connect(func() -> void: visible = false)
	c.add_child(close_button)


## Open on one Act's singularity. defeated_names: every singularity you have
## killed (for browsing and the Year 61 line); [] = only this one counts.
func open(act: ActData, unlocked: bool, story: StoryData, start_page := "entry", defeated_names: Array = []) -> void:
	_act = act
	_story = story
	_unlocked = unlocked
	defeated = defeated_names.duplicate()
	if unlocked and not act.singularity_name in defeated:
		defeated.append(act.singularity_name)
	visible = true
	_show(start_page)


func _browse(step: int) -> void:
	var n := clampi(_act.act_number + step, 1, ACTS_FOR_BROWSING)
	_act = Cosmos.ACTS[n - 1]
	_unlocked = _act.singularity_name in defeated
	_show("entry")


func _show(p: String) -> void:
	page = p
	for child in _body.get_children():
		child.queue_free()
	tab_entry.modulate = Color.WHITE if p == "entry" else Color(1, 1, 1, 0.5)
	tab_timeline.modulate = Color.WHITE if p == "timeline" else Color(1, 1, 1, 0.5)
	tab_cleansing.modulate = Color.WHITE if p == "cleansing" else Color(1, 1, 1, 0.5)
	prev_button.visible = p == "entry"
	next_button.visible = p == "entry"
	_art.texture = null
	if p == "timeline":
		_title.text = "TIMELINE"
		_sub.text = "The history of technomancy"
		_body.position = Vector2(60, 400)
		for i in _story.timeline_titles.size():
			_line(_story.timeline_titles[i], 34, Color("ffd23f"))
			_line(_story.timeline_texts[i], 30, Color.WHITE)
			# Bailey's fix 3: the real first splice, once Reaper-0 has fallen.
			if i == 0 and reaper_down():
				_line(StoryText.SECRET_TIMELINE_TITLE, 34, Color("ff7ad9"))
				_line(StoryText.SECRET_TIMELINE_TEXT, 30, Color.WHITE)
		return
	if p == "cleansing":
		_title.text = "CLEANSING"
		_sub.text = "What \"Cleansed\" means"
		_body.position = Vector2(60, 400)
		for line in StoryText.cleansing_codex():
			_line(line, 32, Color.WHITE)
		if record_text != "":
			_line("Your record:  " + record_text, 32, Color("8fefff"))
		return
	prev_button.disabled = _act.act_number <= 1
	next_button.disabled = _act.act_number >= ACTS_FOR_BROWSING
	_body.position = Vector2(60, 800)
	if not _unlocked:
		_title.text = "???"
		_sub.text = "Act %d singularity" % _act.act_number
		_line("Defeat the Act %d boss to unlock this entry." % _act.act_number, 34, Color("a9a3c9"))
		return
	_title.text = _act.singularity_name.to_upper()
	_sub.text = "%s  ·  %s  ·  %s" % [_act.singularity_kind, Element.display_name(_act.element), _act.colony_name]
	_art.texture = _act.boss_art
	if _act.codex_spliced_from == "":
		_line("This singularity's codex entry arrives with its Act's story.", 32, Color("a9a3c9"))
		return
	for row in [["THE COLONY", _act.codex_colony], ["WHAT WAS RATIONED", _act.codex_rationed],
			["SPLICED FROM", _act.codex_spliced_from], ["WHY IT WAS ABANDONED", _act.codex_abandoned]]:
		_line(row[0], 28, Color("4fd8ff"))
		_line(row[1], 30, Color.WHITE)


func reaper_down() -> bool:
	return "Reaper-0" in defeated


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
	MenuStyle.apply(b, 34)
	return b
