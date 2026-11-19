class_name CosmosMap
extends HomePage
## The PLAY screen: the universe map, 4 levels deep.
##   UNIVERSE  - 10 galaxies scattered round Galaxy 1 (the centre). Picture as-is.
##   GALAXY    - 10 solar systems scattered round the galaxy's main system.
##   SYSTEM    - 5-10 worlds scattered round the star.
##   WORLD     - the planet, and its stages in order (Stage 5 = the boss).
##
## Plain English:
##   - Drag to pan, pinch / mouse wheel / + and - to zoom. Tap a node to preview it
##     (name, Recommended Level, danger, status, rewards); double-tap, or OPEN, to go in.
##   - Locked things can always be previewed; only PLAY waits for a nearer neighbour.
##   - Every level: breadcrumb (Universe > Galaxy > System > World > Stage), BACK,
##     GO TO CURRENT FIGHT, and the counters (Worlds Cleansed, Singularities Defeated).
##   - Only the level you look at is built; going in / back frees the old one.
##   - Colour is random VISUAL diversity. Affinity is gameplay, shown by the orb icon
##     and the label. A blue planet can be a Fire world.
##   - show_markers = numbered calibration markers + each node's hue shift.

signal play_world(key: String, stage: int)
## Something saved changed (a story beat was seen): main writes the save.
signal changed
## CODEX pressed: main opens the codex (singularities, timeline, cleansing).
signal codex_requested

const SUB_H := 130.0
const BOTTOM_H := 128.0
const MIN_ZOOM := 1.0
const MAX_ZOOM := 3.0

var journey: Journey
var profile: Profile
var level := "universe"
var cur_g := 1
var cur_s := 1
var cur_w := 1
var show_markers := false
var zoom := 1.0

var view: Control
var canvas: Control
var bg: Control
var shade: Control
var overlay: Control
## One entry per node on screen: {"kind", "id", "pos" (canvas px), "r", "data"}
var nodes: Array = []
var node_buttons: Array[Button] = []
var crumbs: HBoxContainer
var counter_label: Label
var stats_button: Button
var back_button: Button
var current_button: Button
var zoom_in_button: Button
var zoom_out_button: Button
var world_page: Control
var world_icon: TextureRect
var world_title: Label
var world_sub: Label
var world_play: Button
var stage_buttons: Array[Button] = []
var panel: Control
var panel_title: Label
var panel_sub: Label
var panel_info: Label
var panel_open: Button
var panel_play: Button
var panel_close: Button
var warn_panel: Control
var warn_title: Label
var warn_text: Label
var warn_go: Button
var warn_cancel: Button
var stats_panel: Control
var stats_label: Label
var codex_button: Button
## Part B story beats (on top of everything on the map).
var story_beat: StoryBeat
var _story_busy := false

var _panel_node := {}
var _pending := {}
var _pulse := 0.0
var _press_pos := Vector2.ZERO
var _press_canvas := Vector2.ZERO
var _pressing := false
var _panning := false
var _touches := {}
var _pinch_dist := 0.0
var _pinch_zoom := 1.0
var _pinched := false
var _last_tap_node := -1
var _last_tap_time := -10.0
var _bg_tex: Texture2D
var _bg_mat: Material
var _world_act: ActData


func _init() -> void:
	_setup_page("PLAY")
	var back := ColorRect.new()
	back.color = Color(0.01, 0.01, 0.03)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)

	view = Control.new()
	view.clip_contents = true
	view.mouse_filter = Control.MOUSE_FILTER_STOP
	view.gui_input.connect(_on_view_input)
	add_child(view)
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(canvas)
	bg = Control.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.draw.connect(_draw_bg)
	canvas.add_child(bg)
	shade = Control.new()
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.draw.connect(_draw_shade)
	canvas.add_child(shade)
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_draw_overlay)
	canvas.add_child(overlay)

	_build_world_page()
	_build_sub_bar()
	_build_bottom()
	_build_panel()
	_build_warning()
	_build_stats()
	_build_bars()
	story_beat = StoryBeat.new()
	add_child(story_beat)
	resized.connect(_layout)


# ---------------------------------------------------------------- public

## Show the map again after a fight / from another tab (keeps the level you were on).
func refresh() -> void:
	if profile:
		set_bar_values(profile.data["credits"], profile.data["cores"], profile.highest_level())
	_build_level()


func open_universe() -> void:
	level = "universe"
	_close_panels()
	_build_level()


func open_galaxy(g: int) -> void:
	cur_g = g
	level = "galaxy"
	_close_panels()
	_build_level()


func open_system(g: int, s: int) -> void:
	cur_g = g
	cur_s = s
	level = "system"
	_close_panels()
	_build_level()


func open_world(key: String) -> void:
	var w := Cosmos.world_by_key(key)
	cur_g = w["g"]
	cur_s = w["s"]
	cur_w = w["w"]
	level = "world"
	_close_panels()
	_build_level()


func go_back() -> void:
	match level:
		"world":
			open_system(cur_g, cur_s)
		"system":
			open_galaxy(cur_g)
		"galaxy":
			open_universe()


## GO TO CURRENT FIGHT: straight to the next uncleared fight (with the danger check).
func go_to_current() -> void:
	var cf := journey.current_fight()
	if cf.is_empty():
		show_toast("Every unlocked world is cleansed!")
		return
	open_world(cf["key"])
	request_play(cf["key"], int(cf["index"]))


## PLAY a stage: warns first if the team is under the Recommended Level (never blocks).
func request_play(key: String, stage: int) -> void:
	if not journey.stage_playable(key, stage):
		show_toast(journey.world_lock_reason(key) if not journey.world_unlocked(key) else "Clear the stages before it first")
		return
	var rec := _stage_rec(key, stage)
	var team := team_level()
	var d := Journey.danger(team, rec)
	if not journey.needs_warning(key, d):
		play_world.emit(key, stage)
		return
	_pending = {"key": key, "stage": stage, "danger": d}
	warn_title.text = "WARNING  ·  %s" % Journey.danger_name(d)
	warn_title.label_settings.font_color = Journey.danger_color(d)
	var w := Cosmos.world_by_key(key)
	var boss := "singularity" if bool(w["gate"]) or int(w["act"]) > 0 else "world"
	if d == "skull":
		warn_text.text = "Recommended Lv %d, your team is Lv %d.\nThis %s will probably kill you." % [rec, team, boss]
	elif d == "red":
		warn_text.text = "Recommended Lv %d, your team is Lv %d.\nThis fight is dangerous. You can still try." % [rec, team]
	else:
		warn_text.text = "Recommended Lv %d, your team is Lv %d.\nThis could be risky." % [rec, team]
	warn_panel.visible = true


## The team's level for danger: the average level of the fighting team.
func team_level() -> int:
	if profile == null:
		return 1
	var uids := profile.team_uids(4)
	if uids.is_empty():
		return 1
	var total := 0
	for uid in uids:
		total += int(profile.unit(uid)["level"])
	return total / uids.size()


func _stage_rec(key: String, stage: int) -> int:
	var w := Cosmos.world_by_key(key)
	if int(w["act"]) > 0:
		var act: ActData = Cosmos.ACTS[int(w["act"]) - 1]
		return act.fights[clampi(stage, 0, act.fights.size() - 1)].expected_level
	return int(w["rec"])


# ---------------------------------------------------------------- building a level

func _build_level() -> void:
	for b in node_buttons:
		b.queue_free()
	node_buttons.clear()
	for c in canvas.get_children():
		if c != bg and c != shade and c != overlay:
			c.queue_free()
	nodes.clear()
	_layout_view()
	_built_side = _side()
	world_page.visible = level == "world"
	view.visible = level != "world"
	_update_crumbs()
	_update_counters()
	back_button.disabled = level == "universe"
	back_button.modulate.a = 0.45 if level == "universe" else 1.0
	match level:
		"universe":
			_bg_tex = MapArt.UNIVERSE
			_bg_mat = null
			for gal in Cosmos.galaxies():
				_add_node("galaxy", gal["g"], gal["pos"], 62.0, gal)
		"galaxy":
			var gal := Cosmos.galaxy(cur_g)
			_bg_tex = MapArt.GALAXY_TEX[gal["art"]]
			_bg_mat = MapArt.galaxy_material(gal)
			for sys in Cosmos.systems(cur_g):
				_add_node("system", sys["s"], sys["pos"], 54.0, sys)
		"system":
			var sys := Cosmos.system(cur_g, cur_s)
			_bg_tex = MapArt.SYSTEM_TEX[sys["art"]]
			_bg_mat = MapArt.system_material(sys)
			for w in Cosmos.worlds(cur_g, cur_s):
				_add_node("world", w["w"], w["pos"], 66.0 if bool(w["gate"]) else 56.0, w)
		"world":
			_fill_world_page()
	bg.material = _bg_mat
	bg.queue_redraw()
	shade.queue_redraw()
	zoom = MIN_ZOOM
	canvas.position = Vector2.ZERO
	_layout()
	check_story()


# ---------------------------------------------------------------- Part B story (after Reaper-0)

## Plays any story beat due now, each only once (Bailey's approved text,
## StoryText): the Final Arc Intro (first universe map after Act 10), a ring's
## intro and a galaxy's intro (first time you enter one), the cleansing pop-up
## (first world cleansed outside the Acts) and the final outro (everything
## cleansed). All skippable; nothing waits on them.
func check_story() -> void:
	if journey == null or _story_busy or not visible:
		return
	var beats := []
	if journey.story_done() and level == "universe" and not journey.story_seen("final_arc"):
		beats.append(["final_arc", StoryText.FINAL_ARC_INTRO, 0.0, "", true])
	if level != "universe" and cur_g >= 2 and journey.galaxy_unlocked(cur_g):
		var ring := int(Cosmos.galaxy(cur_g)["ring"])
		var gal := Cosmos.galaxy(cur_g)
		if not journey.story_seen("ring%d" % ring):
			var first: int = Cosmos.galaxies_in_ring(ring)[0]["g"]
			beats.append(["ring%d" % ring, StoryText.RING_INTROS[ring], 12.0, "RING %d  ·  GALAXIES %d-%d" % [ring, first, first + 2], false])
		if not journey.story_seen("galaxy%d" % cur_g):
			beats.append(["galaxy%d" % cur_g, StoryText.GALAXY_INTROS[cur_g], 12.0, "GALAXY %d  ·  %s" % [cur_g, String(gal["name"]).to_upper()], false])
	if not journey.c["cleansed"].is_empty() and not journey.story_seen("cleanse_popup"):
		beats.append(["cleanse_popup", StoryText.CLEANSE_POPUP, 0.0, StoryText.CLEANSE_POPUP_TITLE, false])
	if journey.universe_cleansed() and not journey.story_seen("final_outro"):
		beats.append(["final_outro", StoryText.FINAL_OUTRO, 0.0, "", true])
	if not beats.is_empty():
		_run_story(beats)


func _run_story(beats: Array) -> void:
	_story_busy = true
	for b in beats:
		journey.mark_story_seen(b[0])   # seen once it starts (skipping counts)
		changed.emit()
		await story_beat.play(b[1], b[2], b[3], b[4])
	_story_busy = false


func _side() -> float:
	return view.size.x if view and view.size.x > 0.0 else 1080.0


var _built_side := 0.0


func _layout_view() -> void:
	var top := TOP_BAR_H + SUB_H
	view.position = Vector2(0, top)
	view.size = Vector2(maxf(size.x, 1.0), maxf(size.y - top - NAV_H, 1.0))


func _add_node(kind: String, id: int, p: Vector2, r: float, data: Dictionary) -> void:
	var s := _side()
	var pos := p * s
	var state := _state(kind, data)
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE   # the map does the hit test (so drags pan)
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, empty)
	b.position = pos - Vector2(r, r)
	b.size = Vector2(r, r) * 2.0
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size = b.size
	match kind:
		"galaxy":
			icon.texture = MapArt.GALAXY_TEX[data["art"]]
			icon.material = MapArt.galaxy_material(data, true)
		"system":
			icon.texture = MapArt.sun_icon(data)
			icon.material = MapArt.system_material(data, true)
		"world":
			icon.texture = MapArt.WORLD_TEX[data["template"]]
			icon.material = MapArt.world_material(data)
	if state == "locked":
		icon.modulate = Color(0.55, 0.55, 0.62)
	b.add_child(icon)
	canvas.add_child(b)
	canvas.move_child(overlay, -1)
	var index := nodes.size()
	b.pressed.connect(_on_node_tap.bind(index))
	node_buttons.append(b)
	nodes.append({"kind": kind, "id": id, "pos": pos, "r": r, "data": data, "state": state})
	# Labels (Godot text only): name, then level band / affinity, then status.
	var name_l := _canvas_label(26, Color.WHITE if state != "locked" else Color(0.75, 0.75, 0.82))
	name_l.text = _node_name(kind, data)
	# The level line is coloured by DANGER (team level vs the Recommended Level):
	# green safe, yellow risky, red dangerous, purple lethal.
	var info := _canvas_label(21, Journey.danger_color(_node_danger(kind, data)))
	info.text = _node_info(kind, data)
	var st_l := _canvas_label(20, _state_color(state))
	st_l.text = _state_text(state)
	var y := pos.y + r + 4.0
	for l in [name_l, info, st_l]:
		l.size = Vector2(300, 30)
		l.position = Vector2(pos.x - 150, y)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		y += 27.0


func _canvas_label(font_size: int, color: Color) -> Label:
	var l := make_label(font_size, color, canvas)
	l.label_settings.outline_size = 7
	return l


func _node_name(kind: String, d: Dictionary) -> String:
	match kind:
		"galaxy":
			return "%d · %s" % [d["g"], d["name"]]
		"world":
			if int(d["act"]) > 0:
				return "ACT %d · %s" % [d["act"], d["name"]]
			return d["name"]
	return d["name"]


func _node_info(kind: String, d: Dictionary) -> String:
	match kind:
		"galaxy":
			return "Lv %d-%d" % [d["band"][0], d["band"][1]]
		"system":
			return "Lv %d-%d · %s" % [d["band"][0], d["band"][1], "%d/%d worlds" % [journey.worlds_cleansed_in(d["g"], d["s"]), d["n_worlds"]]]
		"world":
			var tag := " · PURE" if bool(d["pure"]) else ""
			return "%s · Lv %d%s" % [Element.display_name(d["element"]), d["rec"], tag]
	return ""


## Danger for a node: its lowest Recommended Level vs your team's level.
func _node_danger(kind: String, d: Dictionary) -> String:
	var rec := 1
	match kind:
		"galaxy", "system":
			rec = int(d["band"][0])
		"world":
			rec = int(d["rec"])
	return Journey.danger(team_level(), rec)


func _state(kind: String, d: Dictionary) -> String:
	if journey == null:
		return "explorable"
	match kind:
		"galaxy":
			return journey.galaxy_state(d["g"])
		"system":
			return journey.system_state(d["g"], d["s"])
		"world":
			return journey.world_state(d["key"])
	return "explorable"


func _state_text(st: String) -> String:
	return {"completed": "COMPLETED", "current": "CURRENT", "locked": "LOCKED", "explorable": "EXPLORABLE"}.get(st, "")


func _state_color(st: String) -> Color:
	return {"completed": GOLD, "current": Color("6dff8a"), "locked": Color(0.65, 0.65, 0.72), "explorable": MenuStyle.NEON}.get(st, Color.WHITE)


# ---------------------------------------------------------------- layout, pan, zoom

func _layout() -> void:
	if view == null:
		return
	_layout_view()
	if not nodes.is_empty() and absf(_side() - _built_side) > 1.0:
		_build_level()   # the screen changed width: node positions are in pixels
		return
	world_page.position = view.position
	world_page.size = view.size
	var s := _side()
	for c in [bg, shade, overlay]:
		c.position = Vector2.ZERO
		c.size = Vector2(s, s)
	canvas.size = Vector2(s, s)
	_set_zoom(zoom, view.size * 0.5)
	_layout_sub_bar()
	_layout_bottom()
	if panel:
		panel.position = Vector2(30, size.y - NAV_H - BOTTOM_H - panel.size.y - 10)
		panel.size.x = size.x - 60
	_layout_world_page()
	_layout_bars()
	queue_redraw()


func _set_zoom(z: float, around: Vector2) -> void:
	var old := zoom
	zoom = clampf(z, MIN_ZOOM, MAX_ZOOM)
	var content := (around - canvas.position) / old
	canvas.scale = Vector2(zoom, zoom)
	canvas.position = around - content * zoom
	_clamp_pan()


func _clamp_pan() -> void:
	var s := _side() * zoom
	var v := view.size
	var p := canvas.position
	p.x = clampf(p.x, v.x - s, 0.0) if s >= v.x else (v.x - s) * 0.5
	p.y = clampf(p.y, v.y - s, 0.0) if s >= v.y else (v.y - s) * 0.5
	canvas.position = p


func zoom_by(f: float) -> void:
	_set_zoom(zoom * f, view.size * 0.5)


func _on_view_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touches[t.index] = t.position
		else:
			_touches.erase(t.index)
		if _touches.size() == 2:
			var pts: Array = _touches.values()
			_pinch_dist = (pts[0] as Vector2).distance_to(pts[1])
			_pinch_zoom = zoom
			_pinched = true
		if _touches.is_empty():
			_pinched = false
		return
	if event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_touches[d.index] = d.position
		if _touches.size() >= 2 and _pinch_dist > 0.0:
			var pts: Array = _touches.values()
			var dist := (pts[0] as Vector2).distance_to(pts[1])
			_set_zoom(_pinch_zoom * dist / _pinch_dist, ((pts[0] as Vector2) + (pts[1] as Vector2)) * 0.5)
		return
	if event is InputEventMagnifyGesture:
		var m := event as InputEventMagnifyGesture
		_set_zoom(zoom * m.factor, m.position)
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_set_zoom(zoom * 1.12, mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_set_zoom(zoom / 1.12, mb.position)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pressing = true
				_panning = false
				_press_pos = mb.position
				_press_canvas = canvas.position
			else:
				if _pressing and not _panning and not _pinched:
					_tap(mb.position)
				_pressing = false
				_panning = false
		return
	if event is InputEventMouseMotion and _pressing and not _pinched:
		var mm := event as InputEventMouseMotion
		if mm.position.distance_to(_press_pos) > 14.0:
			_panning = true
		if _panning:
			canvas.position = _press_canvas + (mm.position - _press_pos)
			_clamp_pan()


## A tap at a point in the view: the nearest node within reach is pressed.
func _tap(p: Vector2) -> void:
	var c := (p - canvas.position) / zoom
	var best := -1
	var best_d := INF
	for i in nodes.size():
		var d := (nodes[i]["pos"] as Vector2).distance_to(c)
		if d < float(nodes[i]["r"]) + 26.0 and d < best_d:
			best = i
			best_d = d
	if best >= 0:
		node_buttons[best].pressed.emit()
	elif panel.visible:
		panel.visible = false


## Where node i is on screen (for tests and the calibration screenshot).
func node_screen_pos(i: int) -> Vector2:
	return view.position + canvas.position + (nodes[i]["pos"] as Vector2) * zoom


func _on_node_tap(i: int) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var double := i == _last_tap_node and now - _last_tap_time < 0.4
	_last_tap_node = i
	_last_tap_time = now
	if double:
		_enter_node(i)
	else:
		open_preview(i)


func _enter_node(i: int) -> void:
	var n: Dictionary = nodes[i]
	var d: Dictionary = n["data"]
	match String(n["kind"]):
		"galaxy":
			open_galaxy(d["g"])
		"system":
			open_system(d["g"], d["s"])
		"world":
			open_world(d["key"])


# ---------------------------------------------------------------- preview panel

func open_preview(i: int) -> void:
	_panel_node = nodes[i]
	var d: Dictionary = _panel_node["data"]
	var kind: String = _panel_node["kind"]
	var st: String = _panel_node["state"]
	var lines := PackedStringArray()
	panel_play.visible = false
	match kind:
		"galaxy":
			panel_title.text = "GALAXY %d  ·  %s" % [d["g"], String(d["name"]).to_upper()]
			panel_sub.text = "Recommended Lv %d-%d  ·  Ring %d  ·  %s" % [d["band"][0], d["band"][1], d["ring"], _state_text(st)]
			var w := 0
			var cl := 0
			for sys in Cosmos.systems(d["g"]):
				w += int(sys["n_worlds"])
				cl += journey.worlds_cleansed_in(d["g"], sys["s"])
			lines.append("10 solar systems  ·  %d worlds  ·  %d cleansed" % [w, cl])
			lines.append("All 5 affinities: 2 systems each (Fire, Water, Wood, Light, Dark)")
			lines.append("Level cap here: Lv%d" % Cosmos.galaxy_cap(d["g"]))
			if d["g"] == 1:
				lines.append("Main story: Systems 1, 2, 3 (Acts 1-10), then free exploration")
			if st == "locked":
				lines.append("LOCKED: " + journey.galaxy_lock_reason(d["g"]))
		"system":
			panel_title.text = String(d["name"]).to_upper()
			panel_sub.text = "Recommended Lv %d-%d  ·  %s" % [d["band"][0], d["band"][1], _state_text(st)]
			lines.append("%d worlds  ·  %d cleansed  ·  worlds of all 5 affinities" % [d["n_worlds"], journey.worlds_cleansed_in(d["g"], d["s"])])
			lines.append("Singularity (gate boss): %s" % Element.display_name(d["element"]))
			if d["story"]:
				lines.append("MAIN STORY  ·  System %d" % d["s"])
			if st == "locked":
				lines.append("LOCKED: " + journey.system_lock_reason(d["g"], d["s"]))
		"world":
			_preview_world(d, st, lines)
	panel_info.text = "\n".join(lines)
	panel_open.text = "OPEN"
	panel_open.visible = true
	panel.visible = true


func _preview_world(d: Dictionary, st: String, lines: PackedStringArray) -> void:
	var key: String = d["key"]
	var rec: int = d["rec"]
	var dg := Journey.danger(team_level(), rec)
	panel_title.text = ("ACT %d  ·  " % d["act"] if int(d["act"]) > 0 else "") + String(d["name"]).to_upper()
	panel_title.label_settings.font_color = Color.WHITE
	panel_sub.text = "%s  ·  Recommended Lv %d  ·  %s" % [Element.display_name(d["element"]).to_upper(), rec, _state_text(st)]
	lines.append("Danger: %s (your team Lv %d)" % [Journey.danger_name(dg), team_level()])
	if int(d["act"]) > 0:
		var act: ActData = Cosmos.ACTS[int(d["act"]) - 1]
		lines.append("Singularity: %s  ·  %d fights" % [act.singularity_name, act.fights.size()])
		for l in act.intel_lines:
			lines.append(l)
	else:
		var a := Cosmos.build_world(d["g"], d["s"], d["w"])
		var boss := a.fights[4].enemies[0]
		lines.append("%s%s  ·  5 stages" % ["Singularity: " if bool(d["gate"]) else "World boss: ", boss.display_name])
		var total := 0
		for f in a.fights:
			total += f.xp
		lines.append("Rewards: about %d XP each, Credits, Essence" % total)
		lines.append("PURE world: every stage is %s" % Element.display_name(d["element"]) if bool(d["pure"]) else "Stages 1-4 mix 3+ affinities")
		if bool(d["side"]):
			lines.append("Side world (optional)")
	lines.append("Stage %d of %d next" % [mini(journey.stage_next(key), int(d["stage_count"]) - 1) + 1, d["stage_count"]] if st != "completed" else "CLEANSED  ·  replay any stage")
	if st == "locked":
		lines.append("LOCKED: " + journey.world_lock_reason(key))
	panel_play.visible = true
	panel_play.disabled = st == "locked"
	panel_play.text = "PLAY" if st != "completed" else "REPLAY"


func _on_panel_open() -> void:
	panel.visible = false
	var d: Dictionary = _panel_node["data"]
	match String(_panel_node["kind"]):
		"galaxy":
			open_galaxy(d["g"])
		"system":
			open_system(d["g"], d["s"])
		"world":
			open_world(d["key"])
		"stage":
			pass


func _on_panel_play() -> void:
	panel.visible = false
	var d: Dictionary = _panel_node["data"]
	if String(_panel_node["kind"]) == "stage":
		request_play(d["key"], int(d["stage"]))
		return
	var key: String = d["key"]
	var next := journey.stage_next(key)
	if journey.world_cleansed(key):
		next = 0
	request_play(key, mini(next, int(d["stage_count"]) - 1))


func _close_panels() -> void:
	if panel:
		panel.visible = false
	if warn_panel:
		warn_panel.visible = false


# ---------------------------------------------------------------- world page

func _build_world_page() -> void:
	world_page = Control.new()
	world_page.visible = false
	world_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world_page)
	world_icon = TextureRect.new()
	world_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	world_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_page.add_child(world_icon)
	world_title = make_label(46, Color.WHITE, world_page)
	world_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_sub = make_label(28, GOLD, world_page)
	world_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_play = make_button("PLAY NEXT STAGE", Vector2.ZERO, Vector2(600, 100), 38, GOLD, world_page)
	world_play.pressed.connect(func() -> void:
		var key := Cosmos.world(cur_g, cur_s, cur_w)["key"] as String
		var next := journey.stage_next(key)
		if journey.world_cleansed(key):
			next = 0
		request_play(key, mini(next, stage_buttons.size() - 1)))


func _fill_world_page() -> void:
	for b in stage_buttons:
		b.queue_free()
	stage_buttons.clear()
	var w := Cosmos.world(cur_g, cur_s, cur_w)
	_world_act = Cosmos.build_world(cur_g, cur_s, cur_w)
	world_icon.texture = MapArt.WORLD_TEX[w["template"]]
	world_icon.material = MapArt.world_material(w)
	world_title.text = (("ACT %d  ·  " % w["act"]) if int(w["act"]) > 0 else "") + String(w["name"]).to_upper()
	var dg := Journey.danger(team_level(), int(w["rec"]))
	world_sub.text = "%s  ·  Lv %d  ·  %s%s" % [Element.display_name(w["element"]).to_upper(), w["rec"], Journey.danger_name(dg), "  ·  PURE" if bool(w["pure"]) else ""]
	world_sub.label_settings.font_color = Journey.danger_color(dg)
	var key: String = w["key"]
	var unlocked := journey.world_unlocked(key)
	world_play.disabled = not unlocked
	world_play.text = "REPLAY STAGE 1" if journey.world_cleansed(key) else ("PLAY STAGE %d" % (journey.stage_next(key) + 1) if unlocked else "LOCKED")
	for i in _world_act.fights.size():
		var f := _world_act.fights[i]
		var b := Button.new()
		var state := "CLEARED" if journey.world_cleansed(key) or i < journey.stage_next(key) else ("NEXT" if journey.stage_playable(key, i) else "LOCKED")
		var names := PackedStringArray()
		var els := PackedStringArray()
		for e in f.enemies:
			names.append(e.display_name)
			if not Element.display_name(e.element) in els:
				els.append(Element.display_name(e.element))
		var label := f.display_name if int(w["act"]) > 0 else "STAGE %d%s" % [i + 1, "  ·  BOSS" if i == _world_act.fights.size() - 1 else ("  ·  WARDEN" if i == 3 else "")]
		b.text = "    %s\n    %s  ·  %s  ·  %s" % [label, ", ".join(names), "/".join(els), state]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var neon := GOLD if state == "NEXT" else (MenuStyle.NEON if state == "CLEARED" else Color(0.5, 0.5, 0.58))
		MenuStyle.apply(b, 24, neon)
		b.clip_text = true
		b.pressed.connect(_on_stage_pressed.bind(i))
		world_page.add_child(b)
		stage_buttons.append(b)
	_layout_world_page()


func _layout_world_page() -> void:
	if world_page == null:
		return
	var w := world_page.size.x
	var icon := 300.0
	world_icon.position = Vector2((w - icon) * 0.5, 6)
	world_icon.size = Vector2(icon, icon)
	world_title.position = Vector2(0, icon + 6)
	world_title.size = Vector2(w, 56)
	world_sub.position = Vector2(0, icon + 62)
	world_sub.size = Vector2(w, 40)
	world_play.position = Vector2((w - 600) * 0.5, icon + 108)
	var top := icon + 222.0
	var room := world_page.size.y - top - BOTTOM_H - 10.0
	var count := maxi(stage_buttons.size(), 1)
	var h := minf(118.0, room / count - 10.0)
	for i in stage_buttons.size():
		stage_buttons[i].position = Vector2(40, top + i * (h + 10.0))
		stage_buttons[i].size = Vector2(w - 80, h)


func _on_stage_pressed(i: int) -> void:
	var w := Cosmos.world(cur_g, cur_s, cur_w)
	var key: String = w["key"]
	var f := _world_act.fights[i]
	_panel_node = {"kind": "stage", "data": {"key": key, "stage": i}}
	panel_title.text = "%s  ·  STAGE %d / %d" % [String(w["name"]).to_upper(), i + 1, _world_act.fights.size()]
	var rec := _stage_rec(key, i)
	var dg := Journey.danger(team_level(), rec)
	panel_sub.text = "Recommended Lv %d  ·  %s" % [rec, Journey.danger_name(dg)]
	var lines := PackedStringArray()
	for e in f.enemies:
		lines.append("%s  ·  %s%s  ·  HP %d  ATK %d" % [e.display_name, Element.display_name(e.element), ("  ·  " + e.title) if e.title != "" else "", e.max_hp, e.atk])
	lines.append("Win: %d XP each" % f.xp)
	if not journey.stage_playable(key, i):
		lines.append("LOCKED: " + (journey.world_lock_reason(key) if not journey.world_unlocked(key) else "clear the stages before it"))
	panel_info.text = "\n".join(lines)
	panel_open.visible = false
	panel_play.visible = true
	panel_play.disabled = not journey.stage_playable(key, i)
	panel_play.text = "PLAY"
	panel.visible = true


# ---------------------------------------------------------------- bars and panels

func _build_sub_bar() -> void:
	var bar := ColorRect.new()
	bar.color = Color(0.03, 0.03, 0.07, 0.88)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.name = "SubBar"
	add_child(bar)
	crumbs = HBoxContainer.new()
	crumbs.add_theme_constant_override("separation", 6)
	add_child(crumbs)
	counter_label = make_label(28, Color("8fefff"))
	stats_button = make_button("STATS", Vector2.ZERO, Vector2(150, 56), 26)
	stats_button.pressed.connect(open_stats)
	codex_button = make_button("CODEX", Vector2.ZERO, Vector2(150, 56), 26)
	codex_button.pressed.connect(func() -> void: codex_requested.emit())


func _layout_sub_bar() -> void:
	var bar: ColorRect = get_node("SubBar")
	bar.position = Vector2(0, TOP_BAR_H)
	bar.size = Vector2(size.x, SUB_H)
	crumbs.position = Vector2(20, TOP_BAR_H + 6)
	crumbs.size = Vector2(size.x - 40, 56)
	counter_label.position = Vector2(24, TOP_BAR_H + 72)
	counter_label.size = Vector2(size.x - 380, 44)
	counter_label.clip_text = true
	codex_button.position = Vector2(size.x - 340, TOP_BAR_H + 66)
	stats_button.position = Vector2(size.x - 170, TOP_BAR_H + 66)


func _update_crumbs() -> void:
	for c in crumbs.get_children():
		c.queue_free()
	var parts: Array = [["Universe", "universe"]]
	if level != "universe":
		parts.append(["Galaxy %d" % cur_g, "galaxy"])
	if level == "system" or level == "world":
		parts.append(["System %d" % cur_s, "system"])
	if level == "world":
		parts.append(["World %d" % cur_w, "world"])
		var key := Cosmos.world(cur_g, cur_s, cur_w)["key"] as String
		if journey and not journey.world_cleansed(key):
			parts.append(["Stage %d" % (journey.stage_next(key) + 1), "world"])
	for i in parts.size():
		var b := Button.new()
		b.text = parts[i][0] + ("  >" if i < parts.size() - 1 else "")
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 26)
		b.add_theme_color_override("font_color", Color.WHITE if i == parts.size() - 1 else Color("8fefff"))
		b.pressed.connect(_on_crumb.bind(String(parts[i][1])))
		crumbs.add_child(b)


func _on_crumb(target: String) -> void:
	match target:
		"universe":
			open_universe()
		"galaxy":
			open_galaxy(cur_g)
		"system":
			open_system(cur_g, cur_s)


## "Worlds X/Y  •  Singularities X/Y" (+ worlds of this system on a system map).
func _update_counters() -> void:
	if journey == null:
		return
	var t := journey.counters_text()
	if level == "system" or level == "world":
		t += "  •  System %d/%d" % [journey.worlds_cleansed_in(cur_g, cur_s), Cosmos.system(cur_g, cur_s)["n_worlds"]]
	counter_label.text = t


func _build_bottom() -> void:
	back_button = make_button("< BACK", Vector2.ZERO, Vector2(200, 96), 30)
	back_button.pressed.connect(go_back)
	current_button = make_button("GO TO CURRENT FIGHT", Vector2.ZERO, Vector2(470, 96), 30, GOLD)
	current_button.pressed.connect(go_to_current)
	zoom_out_button = make_button("-", Vector2.ZERO, Vector2(96, 96), 46)
	zoom_out_button.pressed.connect(func() -> void: zoom_by(1.0 / 1.35))
	zoom_in_button = make_button("+", Vector2.ZERO, Vector2(96, 96), 46)
	zoom_in_button.pressed.connect(func() -> void: zoom_by(1.35))


func _layout_bottom() -> void:
	var y := size.y - NAV_H - BOTTOM_H + 16
	back_button.position = Vector2(24, y)
	current_button.position = Vector2(236, y)
	zoom_out_button.position = Vector2(size.x - 232, y)
	zoom_in_button.position = Vector2(size.x - 120, y)
	zoom_in_button.visible = level != "world"
	zoom_out_button.visible = level != "world"


func _build_panel() -> void:
	panel = Control.new()
	panel.size = Vector2(1020, 560)
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	var box := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(MenuStyle.PANEL, 0.96)
	sb.set_corner_radius_all(28)
	sb.set_border_width_all(3)
	sb.border_color = MenuStyle.NEON
	box.add_theme_stylebox_override("panel", sb)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	panel_title = make_label(38, Color.WHITE, panel)
	panel_title.position = Vector2(30, 22)
	panel_title.size = Vector2(960, 50)
	panel_title.clip_text = true
	panel_sub = make_label(26, GOLD, panel)
	panel_sub.position = Vector2(30, 76)
	panel_sub.size = Vector2(960, 36)
	panel_info = make_label(25, Color.WHITE, panel)
	panel_info.position = Vector2(30, 122)
	panel_info.size = Vector2(960, 300)
	panel_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_open = make_button("OPEN", Vector2(30, 440), Vector2(300, 96), 34, MenuStyle.NEON, panel)
	panel_open.pressed.connect(_on_panel_open)
	panel_play = make_button("PLAY", Vector2(350, 440), Vector2(320, 96), 38, GOLD, panel)
	panel_play.pressed.connect(_on_panel_play)
	panel_close = make_button("CLOSE", Vector2(690, 440), Vector2(300, 96), 34, MenuStyle.NEON, panel)
	panel_close.pressed.connect(func() -> void: panel.visible = false)




func _build_warning() -> void:
	warn_panel = Control.new()
	warn_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	warn_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	warn_panel.visible = false
	add_child(warn_panel)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.0, 0.03, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warn_panel.add_child(dim)
	var box := make_panel(Vector2(60, 640), Vector2(960, 560), Color("ff5a4a"), warn_panel)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warn_title = make_label(54, Color.WHITE, warn_panel)
	warn_title.position = Vector2(60, 680)
	warn_title.size = Vector2(960, 70)
	warn_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn_text = make_label(34, Color.WHITE, warn_panel)
	warn_text.position = Vector2(100, 780)
	warn_text.size = Vector2(880, 200)
	warn_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warn_go = make_button("PLAY ANYWAY", Vector2(100, 1030), Vector2(420, 120), 36, Color("ff5a4a"), warn_panel)
	warn_go.pressed.connect(func() -> void:
		warn_panel.visible = false
		if String(_pending.get("danger", "")) == "yellow":
			journey.mark_warned(_pending["key"])
		play_world.emit(_pending["key"], int(_pending["stage"])))
	warn_cancel = make_button("CANCEL", Vector2(560, 1030), Vector2(420, 120), 36, MenuStyle.NEON, warn_panel)
	warn_cancel.pressed.connect(func() -> void: warn_panel.visible = false)


func _build_stats() -> void:
	stats_panel = Control.new()
	stats_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	stats_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	stats_panel.visible = false
	add_child(stats_panel)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.0, 0.03, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_panel.add_child(dim)
	var box := make_panel(Vector2(60, 420), Vector2(960, 900), GOLD, stats_panel)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := make_label(52, GOLD, stats_panel)
	title.text = "PROFILE  ·  STATS"
	title.position = Vector2(60, 460)
	title.size = Vector2(960, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label = make_label(34, Color.WHITE, stats_panel)
	stats_label.position = Vector2(120, 570)
	stats_label.size = Vector2(840, 560)
	stats_label.label_settings.line_spacing = 14
	var close := make_button("CLOSE", Vector2(360, 1170), Vector2(360, 110), 36, MenuStyle.NEON, stats_panel)
	close.pressed.connect(func() -> void: stats_panel.visible = false)


func open_stats() -> void:
	stats_label.text = stats_text()
	stats_panel.visible = true


func stats_text() -> String:
	var j := journey
	return "\n".join(PackedStringArray([
		"Worlds Cleansed:  %d / %d" % [j.worlds_cleansed(), Cosmos.total_worlds()],
		"Singularities Defeated:  %d / %d" % [j.singularities_defeated(), Cosmos.total_singularities()],
		"Wardens Defeated:  %d / %d" % [j.wardens_defeated(), Cosmos.total_wardens()],
		"Acts Cleared:  %d / %d" % [j.save.get("cleared_acts", []).size(), Cosmos.ACTS.size()],
		"Total Fights Won:  %d" % int(j.c["fights_won"]),
		"Highest Combo:  %d" % int(j.c["highest_combo"]),
		"Total Play Time:  %s" % Journey.play_time_text(float(j.c["play_time"])),
	]))


# ---------------------------------------------------------------- drawing

func _process(delta: float) -> void:
	if not visible:
		return
	_pulse = fmod(_pulse + delta * 3.0, TAU)
	overlay.queue_redraw()


func _draw_bg() -> void:
	if _bg_tex == null:
		return
	var s := _side()
	# The picture, plus mirrored copies round it (dimmed by `shade`) so zooming
	# and panning never show black bars.
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var flip := Vector2(-1.0 if dx != 0 else 1.0, -1.0 if dy != 0 else 1.0)
			var origin := Vector2(s * dx, s * dy) + Vector2(s if flip.x < 0 else 0.0, s if flip.y < 0 else 0.0)
			bg.draw_set_transform(origin, 0.0, flip)
			bg.draw_texture_rect(_bg_tex, Rect2(0, 0, s, s), false)
	bg.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Dims the mirrored copies round the picture, fading in over 160 px so there is
## no hard line where the picture ends.
func _draw_shade() -> void:
	var s := _side()
	var full := Color(0.0, 0.0, 0.02, 0.55)
	var none := Color(0.0, 0.0, 0.02, 0.0)
	var f := 160.0
	shade.draw_rect(Rect2(-s, -s, 3 * s, s - f), full)
	shade.draw_rect(Rect2(-s, s + f, 3 * s, s - f), full)
	shade.draw_rect(Rect2(-s, -f, s - f, s + 2 * f), full)
	shade.draw_rect(Rect2(s + f, -f, s - f, s + 2 * f), full)
	# Soft edges: top, bottom, left, right.
	shade.draw_polygon(PackedVector2Array([Vector2(-s, -f), Vector2(2 * s, -f), Vector2(2 * s, 0), Vector2(-s, 0)]), PackedColorArray([full, full, none, none]))
	shade.draw_polygon(PackedVector2Array([Vector2(-s, s), Vector2(2 * s, s), Vector2(2 * s, s + f), Vector2(-s, s + f)]), PackedColorArray([none, none, full, full]))
	shade.draw_polygon(PackedVector2Array([Vector2(-f, 0), Vector2(0, 0), Vector2(0, s), Vector2(-f, s)]), PackedColorArray([full, none, none, full]))
	shade.draw_polygon(PackedVector2Array([Vector2(s, 0), Vector2(s + f, 0), Vector2(s + f, s), Vector2(s, s)]), PackedColorArray([none, full, full, none]))


func _draw_overlay() -> void:
	var o := overlay
	var s := _side()
	if level == "galaxy":
		for r in [0.2, 0.305, 0.395]:
			o.draw_arc(Vector2(0.5, 0.5) * s, r * s, 0.0, TAU, 96, Color(0.7, 0.9, 1.0, 0.12), 2.0, true)
	elif level == "system":
		var sys := Cosmos.system(cur_g, cur_s)
		var sun: Vector2 = MapArt.SYSTEM_SUN[sys["art"]] * s
		for n in nodes:
			o.draw_arc(sun, (n["pos"] as Vector2).distance_to(sun), 0.0, TAU, 128, Color(0.8, 0.9, 1.0, 0.13), 2.0, true)
	var font := ThemeDB.fallback_font
	for i in nodes.size():
		var n: Dictionary = nodes[i]
		var p: Vector2 = n["pos"]
		var r: float = n["r"]
		var st: String = n["state"]
		var col := _state_color(st)
		if st == "current":
			var grow := 8.0 + 8.0 * (0.5 + 0.5 * sin(_pulse))
			o.draw_arc(p, r + grow, 0.0, TAU, 64, Color(col, 0.9), 4.0, true)
		elif st == "completed":
			var cp := p + Vector2(r * 0.75, -r * 0.75)
			o.draw_circle(cp, 15.0, GOLD)
			o.draw_polyline(PackedVector2Array([cp + Vector2(-8, 0), cp + Vector2(-2, 6), cp + Vector2(9, -7)]), Color(0.15, 0.1, 0.0), 4.0, true)
		elif st == "locked":
			_draw_padlock(p + Vector2(r * 0.7, -r * 0.7))
		else:
			o.draw_arc(p, r + 5.0, 0.0, TAU, 64, Color(col, 0.6), 2.0, true)
		# Affinity: the orb icon (not the colour) tells a world's / system's affinity.
		if String(n["kind"]) != "galaxy":
			var d: Dictionary = n["data"]
			var el: int = d["element"]
			var ic := p + Vector2(-r * 0.75, -r * 0.75)
			o.draw_circle(ic, 19.0, Color(0.05, 0.04, 0.09))
			o.draw_circle(ic, 16.0, Element.color(el).darkened(0.1))
			ElementIcons.draw_icon(o, el, ic + Vector2(0, 1), 10.0, Color.WHITE, Element.color(el).darkened(0.6))
		if show_markers:
			o.draw_circle(p, 22.0, Color(1, 0.1, 0.4))
			o.draw_string(font, p + Vector2(-22, 10), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 44, 28, Color.WHITE)
			var d: Dictionary = n["data"]
			var swatch := Color.from_hsv(float(d.get("seen_hue", 0.0)), 0.85, 0.95)
			o.draw_rect(Rect2(p + Vector2(r + 4, -r), Vector2(26, 26)), swatch)
			o.draw_string(font, p + Vector2(r + 34, -r + 21), "%.2f" % float(d.get("hue", 0.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)


func _draw_padlock(p: Vector2) -> void:
	var o := overlay
	o.draw_arc(p + Vector2(0, -6), 9.0, PI, TAU, 16, Color(0.85, 0.85, 0.9), 4.0, true)
	o.draw_rect(Rect2(p + Vector2(-12, -6), Vector2(24, 19)), Color(0.85, 0.85, 0.9))
	o.draw_circle(p + Vector2(0, 2), 3.0, Color(0.2, 0.2, 0.25))
