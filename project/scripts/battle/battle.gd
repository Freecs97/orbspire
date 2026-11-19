extends Node2D
## Runs the whole battle loop. This is the "director".
##
## Plain English, one turn:
##   1. Board unlocks. Tap an enemy to target it (optional). Drag an orb.
##   2. Board clears combos and reports: combos, orbs of each type, and every group.
##   3. Hearts heal the team.
##   4. Each hunter whose element was cleared attacks:
##        - Berserker with 4+ of its orbs in one group -> hits EVERY enemy
##        - everyone else -> hits the target (tapped enemy, or the front one)
##   5. Every enemy still alive attacks the team, one after another.
##   6. Back to 1, until all enemies or the team are down -> WIN or LOSE.
##
## This script builds the screen in code, so the scene file is tiny.
## Stats live in res://data/*.tres. Edit those, not this file, to rebalance.
##
## Screen sizes: the design is 1080 x 1920. On a taller phone the screen gets
## extra height (stretch aspect = "expand"). _apply_layout() keeps the enemy
## title at the top, pushes the team + board down to the bottom (thumb zone)
## and lets the corridor grow to fill the gap. Nothing is stretched.

## The starting story trio (Act 1). Slot 1 is the leader.
const STORY_TEAM := [
	preload("res://data/team/fire_berserker.tres"),
	preload("res://data/team/water_biotech.tres"),
	preload("res://data/team/wood_titan.tres"),
]
## Act 1 (Orbspire, Furnace District): the 8 fights, in the locked order.
const ACT1_FIGHTS := [
	preload("res://data/fights/act1/fight_1.tres"),
	preload("res://data/fights/act1/fight_2.tres"),
	preload("res://data/fights/act1/fight_3.tres"),
	preload("res://data/fights/act1/fight_4.tres"),
	preload("res://data/fights/act1/fight_5.tres"),
	preload("res://data/fights/act1/fight_6.tres"),
	preload("res://data/fights/act1/fight_7.tres"),
	preload("res://data/fights/act1/fight_8.tres"),
]
## The old placeholder fights. Only the automated tests use these now.
const TEST_FIGHTS := [
	preload("res://data/fights/test_fight_1.tres"),
	preload("res://data/fights/test_fight_2.tres"),
	preload("res://data/fights/test_fight_3.tres"),
	preload("res://data/fights/test_fight_4.tres"),
]
const DARK_SPECTRE := preload("res://data/team/dark_spectre.tres")
const ACT_NAME := "ACT 1"   ## Used when no Act is set (tests).
const ROLE_NAMES := ["BERSERKER", "TITAN", "SPECTRE", "BIOTECH", "ENEMY"]

# Layout for the base 1080 x 1920 screen.
const BASE_SIZE := Vector2(1080, 1920)
const ENEMY_FEET_Y := 640.0   ## Stage 4: 80 px lower (was 560) so the bigger enemies fit under the titles
## Stage 4: enemies are drawn 20% bigger (15% in a fight where 20% would make two overlap).
const ENEMY_SCALE := 1.2
const ENEMY_SCALE_TIGHT := 1.15
const ENEMY_X := {1: [540.0], 2: [320.0, 760.0], 3: [190.0, 540.0, 890.0]}
const ENEMY_BAR_W := {1: 440.0, 2: 330.0, 3: 270.0}
const TEAM_FEET_Y := 935.0
const TEAM_X := {1: [540.0], 2: [395.0, 685.0], 3: [250.0, 540.0, 830.0], 4: [150.0, 395.0, 685.0, 930.0]}
## Stage 4: head-only plates (were full-body cards 260 x 270).
const TEAM_CARD := {1: FighterView.DEFAULT_CARD, 2: FighterView.DEFAULT_CARD, 3: FighterView.DEFAULT_CARD, 4: FighterView.DEFAULT_CARD}
const TEAM_BAR_Y := 975.0
const TIMER_BAR_Y := 1030.0
const BOARD_POS := Vector2(45, 1090)
const FRONT_Z := 11   ## Above the scenery (z 10), which is above the board (z 0).
## Bailey's attack animation on every orb hit: drawn this tall, over this many seconds.
const ATTACK_FX_HEIGHT := 300.0
const ATTACK_FX_TIME := 0.36

var stage: Node2D          ## Centres the 1080-wide layout on wider screens.
var world: Node2D          ## Everything that shakes with the screen.
var backdrop: Backdrop
var board: Board
var enemy_views: Array[FighterView] = []
var enemy_bars: Array[HpBar] = []
var team_views: Array[FighterView] = []
var team_labels: Array[Label] = []
var team_bar: HpBar
var timer_bar: MoveTimerBar
var enemy_title: Label
var enemy_hint: Label
var enemy_attack_label: Label
var team_status_label: Label
var combo_counter: ComboCounter   ## Stage 4: live "COMBO 3  x1.50" next to the board
var cut_in: SkillCutIn            ## Skill cut-in: the hunter's portrait over the BOARD (never the arena)
var cut_in_toggle: Button         ## In the MENU dialog: Skill Cut-ins ON / OFF
var roster_picker: RosterPicker   ## Stage 5A: REPLACE from the plate pop-up
var unit_detail: UnitDetail       ## Stage 5B: DETAILS from the plate pop-up
var notice_label: Label           ## short notes ("DREK VANE joins from the next fight")
var _notice_tween: Tween
var _replace_slot := -1
var _skill_used_this_fight := false
var _act_skill_uids: Array = []   ## whose charge _act_skill_turns holds (games with a save)
var _fight_start_uids: Array = []
var level_label: Label
var result_panel: ResultPanel
var skill_popup: SkillPopup

var team_data: Array[FighterData] = []   ## Who is in the team (set_team to change).
var team: Team
var enemies: Array[Enemy] = []
var act_fights: Array = ACT1_FIGHTS      ## The fights of the Act being played.
var fight_index := 0
var team_level := 1                       ## Level the team is shown at in this fight.
var target_index := -1     ## -1 = no target chosen: attacks go to the front enemy.
var turn_count := 0
var _extra_height := 0.0
## How big enemies are drawn in this fight (ENEMY_SCALE or ENEMY_SCALE_TIGHT).
var enemy_scale := ENEMY_SCALE
## Tests only: force a scale (e.g. 1.0 for an old-size screenshot). 0 = automatic.
var enemy_scale_override := 0.0

## Skill charge carries over from fight to fight inside an Act.
var _act_skill_turns: Array[int] = []    ## charge at the end of the last won fight
var _fight_start_turns: Array[int] = []  ## charge when this fight began (for Retry)
var _busy := false                       ## true while a skill animation plays
var _player_turn := false                ## true until the player picks up an orb
## Tests only: when set, every fight uses this instead of act_fights.
var test_fight_override: FightData = null

# --- Set these BEFORE adding the battle to the scene (main.gd does). ---
## The Act being played: its fights, arena art and story beats. null = plain test mode.
var act: ActData = null
## True when there is a home screen to go back to after the last fight.
var has_home := false
## Which fight to start on (Continue resumes mid-Act).
var start_fight := 0
## Play the Act's 2-line intro before the first fight.
var play_act_intro := false
## Show the one-time "team slot 4 is open" notice (first time in Act 2+).
var show_join_notice := false
## The player's profile (real levels, rewards). null = test mode with the Lv preview.
var profile: Profile = null
## true = show the team at each fight's expected level (only without a profile).
var use_level_preview := true
var _team_uids: Array = []
## What the last fight paid out (tests read this).
var last_rewards: Dictionary = {}

signal progress_changed

var story_beat: StoryBeat
var menu_button: Button
var leave_dialog: Control
var leave_yes: Button
var leave_no: Button

signal fight_won(index: int)
signal act_won(act: ActData)
signal home_requested
signal codex_requested

enum StartMode { NEW_ACT, NEXT_FIGHT, RETRY }


func _ready() -> void:
	if profile:
		# Your chosen team at their real levels and rarities (3 in Act 1, 4 later).
		use_level_preview = false
		_load_profile_team()
	else:
		for d in STORY_TEAM:
			team_data.append(d)
		# Without a profile (tests), the Dark Spectre fights from Act 2.
		if act and act.act_number >= 2:
			team_data.append(DARK_SPECTRE)
	if act:
		act_fights = act.fights
	_build_scene()
	if act:
		backdrop.arena = act.arena
	get_viewport().size_changed.connect(_apply_layout)
	_start_battle(start_fight, StartMode.NEW_ACT)
	if play_act_intro and act and not act.intro_lines.is_empty():
		_play_beat(act.intro_lines, act.intro_seconds, ("%s  ·  %s" % [act.colony_name, act.colony_kind]).to_upper())
	elif show_join_notice:
		_play_beat(["Team slot 4 is open.", "From Act 2 on, you fight as a team of 4. Fill it on the TEAM screen."], 6.0, "NEW SLOT")


## Lock the board, show a story beat, then hand the turn back to the player.
func _play_beat(lines: Array, seconds: float, speaker: String) -> void:
	_player_turn = false
	board.lock()
	await story_beat.play(lines, seconds, speaker)
	if not result_panel.visible:
		_begin_player_turn()


func _team_size() -> int:
	return 3 if act == null or act.act_number == 1 else 4


## Rebuild the team from the profile (after level-ups the stats change).
func _load_profile_team() -> void:
	_team_uids = profile.team_uids(_team_size())
	team_data.clear()
	for f in profile.team_fighters(_team_size()):
		team_data.append(f)


func _act_name() -> String:
	return "ACT %d" % act.act_number if act else ACT_NAME


func _is_boss_fight(index: int) -> bool:
	return act != null and test_fight_override == null and index == act_fights.size() - 1


# ---------------------------------------------------------------- setup

func _build_scene() -> void:
	stage = Node2D.new()
	add_child(stage)
	world = Node2D.new()
	stage.add_child(world)

	board = Board.new()
	world.add_child(board)

	backdrop = Backdrop.new()
	backdrop.z_index = 10
	world.add_child(backdrop)

	enemy_title = _make_label(Vector2(0, 28), 1080, 44, Color.WHITE)
	enemy_hint = _make_label(Vector2(0, 80), 1080, 28, Color("d6ccff"))
	enemy_attack_label = _make_label(Vector2(0, 116), 1080, 26, Color("ff8a8a"))

	team_bar = HpBar.new()
	team_bar.bar_size = Vector2(990, 38)
	team_bar.show_heart = true
	team_bar.z_index = FRONT_Z
	world.add_child(team_bar)

	timer_bar = MoveTimerBar.new()
	timer_bar.bar_size = Vector2(990, 28)
	timer_bar.z_index = FRONT_Z
	world.add_child(timer_bar)

	# Small line above the team HP bar showing shields / guards that are active.
	team_status_label = _make_label(Vector2.ZERO, 990, 24, Color("8fd8ff"))
	team_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# Top-left corner: the Act and the team's level in this fight.
	level_label = _make_label(Vector2(20, 2), 1040, 22, Color("ffd23f"))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# Live combo counter, right above the board (over the timer bar, which is
	# empty while the board resolves).
	combo_counter = ComboCounter.new()
	combo_counter.z_index = FRONT_Z + 5
	world.add_child(combo_counter)
	# Skill cut-in: covers exactly the board, above the orbs and effects.
	cut_in = SkillCutIn.new()
	cut_in.z_index = 60
	cut_in.size = Vector2(Board.COLS * Board.CELL, Board.ROWS * Board.CELL)
	world.add_child(cut_in)

	# Pop-up screens live on their own layer so the screen shake doesn't move them.
	var ui := CanvasLayer.new()
	add_child(ui)
	result_panel = ResultPanel.new()
	ui.add_child(result_panel)
	skill_popup = SkillPopup.new()
	ui.add_child(skill_popup)
	story_beat = StoryBeat.new()
	ui.add_child(story_beat)
	# Stage 5: REPLACE (Roster picker) and DETAILS (full detail screen) from the pop-up.
	roster_picker = RosterPicker.new()
	ui.add_child(roster_picker)
	unit_detail = UnitDetail.new()
	ui.add_child(unit_detail)
	notice_label = Label.new()
	var ns := LabelSettings.new()
	ns.font_size = 32
	ns.font_color = Color("ffe9a0")
	ns.outline_size = 8
	ns.outline_color = Color(0.02, 0.01, 0.06)
	notice_label.label_settings = ns
	var nb := StyleBoxFlat.new()
	nb.bg_color = Color(0.02, 0.01, 0.06, 0.82)
	nb.set_corner_radius_all(18)
	nb.border_width_bottom = 3
	nb.border_color = Color("ffd23f")
	nb.content_margin_left = 24
	nb.content_margin_right = 24
	notice_label.add_theme_stylebox_override("normal", nb)
	# In the arena, under the fight titles (clear of the HP bar and the board).
	notice_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	notice_label.offset_left = 50
	notice_label.offset_right = -50
	notice_label.offset_top = 165
	notice_label.offset_bottom = 275
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_label.modulate.a = 0.0
	ui.add_child(notice_label)
	_build_menu_ui(ui)
	result_panel.codex_pressed.connect(func() -> void: codex_requested.emit())
	skill_popup.use_pressed.connect(func(i: int) -> void: use_skill(i))
	skill_popup.replace_pressed.connect(open_replace)
	skill_popup.details_pressed.connect(open_details)
	skill_popup.closed.connect(_on_popup_closed)
	roster_picker.picked.connect(_on_replace_picked)
	roster_picker.closed.connect(_resume_after_overlay)
	unit_detail.closed.connect(_resume_after_overlay)
	unit_detail.changed.connect(func() -> void: progress_changed.emit())

	board.move_started.connect(func() -> void:
		_player_turn = false
		combo_counter.reset())   # each drag starts from COMBO 0
	board.timer_changed.connect(_on_timer_changed)
	board.combo_made.connect(_on_combo_made)
	board.turn_finished.connect(_on_turn_finished)
	result_panel.retry_pressed.connect(func() -> void: _start_battle(fight_index, StartMode.RETRY))
	result_panel.next_pressed.connect(_on_next_pressed)


## MENU button (top-right) + the "Leave this fight?" check.
## Plain English: the button only works on your turn (before you pick up an
## orb), so a fight is never cut off half-way through an attack. YES takes you
## back to the star map; that fight starts fresh next time.
func _build_menu_ui(ui: CanvasLayer) -> void:
	menu_button = Button.new()
	menu_button.text = "MENU"
	menu_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	menu_button.offset_left = -170
	menu_button.offset_right = -14
	menu_button.offset_top = 10
	menu_button.offset_bottom = 72
	MenuStyle.apply(menu_button, 30)
	menu_button.focus_mode = Control.FOCUS_NONE
	menu_button.visible = has_home
	menu_button.pressed.connect(open_leave_dialog)
	ui.add_child(menu_button)

	leave_dialog = Control.new()
	leave_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	leave_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	leave_dialog.visible = false
	ui.add_child(leave_dialog)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.01, 0.04, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leave_dialog.add_child(dim)
	var content := Control.new()
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.offset_left = -540
	content.offset_right = 540
	content.offset_top = -960
	content.offset_bottom = 960
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leave_dialog.add_child(content)
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = MenuStyle.PANEL
	sb.set_corner_radius_all(26)
	sb.set_border_width_all(3)
	sb.border_color = MenuStyle.NEON
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(100, 520)
	panel.size = Vector2(880, 660)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(panel)
	# Settings you may want mid-fight: Skill Cut-ins ON / OFF (same setting as ⚙ at home).
	cut_in_toggle = Button.new()
	cut_in_toggle.text = GameSettings.cut_ins_text()
	cut_in_toggle.position = Vector2(190, 560)
	cut_in_toggle.size = Vector2(700, 100)
	MenuStyle.apply(cut_in_toggle, 36, MenuStyle.NEON)
	cut_in_toggle.focus_mode = Control.FOCUS_NONE
	content.add_child(cut_in_toggle)
	cut_in_toggle.pressed.connect(func() -> void:
		GameSettings.set_skill_cut_ins(not GameSettings.skill_cut_ins)
		cut_in_toggle.text = GameSettings.cut_ins_text())
	var line := ColorRect.new()
	line.color = Color(MenuStyle.NEON, 0.5)
	line.position = Vector2(160, 700)
	line.size = Vector2(760, 3)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(line)
	var l := Label.new()
	var s := LabelSettings.new()
	s.font_size = 40
	s.font_color = Color.WHITE
	l.label_settings = s
	l.text = "Leave this fight?\n\nYou go back to the star map.\nThis fight starts over next time."
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(100, 740)
	l.size = Vector2(880, 260)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(l)
	leave_yes = Button.new()
	leave_yes.text = "YES, LEAVE"
	leave_yes.position = Vector2(150, 1030)
	leave_yes.size = Vector2(360, 110)
	MenuStyle.apply(leave_yes, 40, Color("ff5a5a"))
	content.add_child(leave_yes)
	leave_no = Button.new()
	leave_no.text = "NO, STAY"
	leave_no.position = Vector2(570, 1030)
	leave_no.size = Vector2(360, 110)
	MenuStyle.apply(leave_no, 40, MenuStyle.NEON)
	content.add_child(leave_no)
	leave_yes.pressed.connect(_on_leave_confirmed)
	leave_no.pressed.connect(close_leave_dialog)


## Can the player leave right now? (Their turn, nothing animating, no pop-up.)
func can_leave() -> bool:
	return has_home and _player_turn and not _busy and not result_panel.visible \
		and not skill_popup.visible and not leave_dialog.visible and not _overlay_open() \
		and (board.state == Board.State.READY or board.state == Board.State.LOCKED)


## Returns false (and does nothing) if it isn't safe to leave right now.
func open_leave_dialog() -> bool:
	if not can_leave():
		return false
	board.lock()   # so a tap on YES / NO can never pick up an orb underneath
	cut_in_toggle.text = GameSettings.cut_ins_text()
	leave_dialog.visible = true
	return true


func close_leave_dialog() -> void:
	leave_dialog.visible = false
	if _player_turn and not _busy and not result_panel.visible:
		board.begin_player_turn()


func _on_leave_confirmed() -> void:
	leave_dialog.visible = false
	_player_turn = false
	board.lock()
	home_requested.emit()


func _process(_delta: float) -> void:
	if team:
		for v in team_views:
			v.hp_ratio = team.hp_ratio()   # head plates: the team's shared HP
	if menu_button and has_home:
		menu_button.visible = not _overlay_open()   # hidden under Replace / Details
	if menu_button and menu_button.visible:
		# Dimmed while enemies attack / combos resolve; lights up on your turn.
		menu_button.disabled = not can_leave() and not leave_dialog.visible


## Replace the team (tests use this; Phase 6+ team select will too). Slot 1 leads.
func set_team(members: Array) -> void:
	team_data.clear()
	for m in members:
		team_data.append(m)
	_act_skill_turns.clear()   # a new team starts a new Act's charge
	_fight_start_turns.clear()
	_act_skill_uids.clear()
	_fight_start_uids.clear()
	_build_team_views()


func _build_team_views() -> void:
	for v in team_views:
		v.queue_free()
	for l in team_labels:
		l.queue_free()
	team_views.clear()
	team_labels.clear()
	for d in team_data:
		var view := FighterView.new()
		view.z_index = FRONT_Z
		world.add_child(view)
		view.card_size = TEAM_CARD[clampi(team_data.size(), 1, 4)]
		view.setup(d)
		team_views.append(view)
		var label := _make_label(Vector2.ZERO, view.card_size.x, 22, Element.color(d.element).lightened(0.4))
		label.text = d.display_name if d.title != "" else "%s · %s" % [Element.display_name(d.element), ROLE_NAMES[d.role]]
		team_labels.append(label)
	_apply_layout()


func _build_enemy_views() -> void:
	for v in enemy_views:
		v.queue_free()
	for b in enemy_bars:
		b.queue_free()
	enemy_views.clear()
	enemy_bars.clear()
	enemy_scale = enemy_scale_override if enemy_scale_override > 0.0 else fit_enemy_scale(enemies)
	for e in enemies:
		var view := FighterView.new()
		view.z_index = FRONT_Z
		view.scale = Vector2.ONE * enemy_scale
		world.add_child(view)
		view.setup(e.data)
		view.armor_up = e.armor_up
		enemy_views.append(view)
		var bar := HpBar.new()
		bar.bar_size = Vector2(ENEMY_BAR_W[clampi(enemies.size(), 1, 3)], 30)
		bar.fill_color = Color("e2456e")
		bar.tick_color = Color("ffe08a")
		bar.z_index = FRONT_Z
		world.add_child(bar)
		bar.set_values(e.hp, e.data.max_hp, false)
		enemy_bars.append(bar)
	_apply_layout()


## Place everything for the current screen size.
## Extra height goes into the corridor; the team, bars and board slide down
## together so the board always sits at the bottom of the screen.
func _apply_layout() -> void:
	if stage == null:
		return
	var view := get_viewport_rect().size
	var extra := maxf(view.y - BASE_SIZE.y, 0.0)
	var side := maxf(view.x - BASE_SIZE.x, 0.0) * 0.5
	_extra_height = extra
	stage.position = Vector2(side, 0.0)

	var enemy_y := ENEMY_FEET_Y + extra * 0.6
	backdrop.set_layout(extra, side, enemy_y)
	for i in enemy_views.size():
		var p := enemy_position(i)
		enemy_views[i].position = p
		enemy_bars[i].position = Vector2(p.x - enemy_bars[i].bar_size.x * 0.5, p.y + 26)
	var n := clampi(team_views.size(), 1, 4)
	for i in team_views.size():
		var x: float = TEAM_X[n][mini(i, n - 1)]
		team_views[i].position = Vector2(x, TEAM_FEET_Y + extra)
		team_labels[i].position = Vector2(x - team_views[i].card_size.x * 0.5, TEAM_FEET_Y + extra - 4)
	team_bar.position = Vector2(45, TEAM_BAR_Y + extra)
	team_status_label.position = Vector2(45, TEAM_BAR_Y + extra - 34)
	combo_counter.position = Vector2(540 - combo_counter.size.x * 0.5, TIMER_BAR_Y + extra + 14 - combo_counter.size.y * 0.5)
	timer_bar.position = Vector2(45, TIMER_BAR_Y + extra)
	board.position = BOARD_POS + Vector2(0, extra)
	cut_in.position = board.position


## Stage 4: 1.20, or 1.15 if at 1.20 two neighbouring enemies' visible art
## would overlap (measured from the art's non-transparent pixels).
static func fit_enemy_scale(list: Array) -> float:
	var n := list.size()
	if n <= 1:
		return ENEMY_SCALE
	var xs: Array = ENEMY_X[clampi(n, 1, 3)]
	for s in [ENEMY_SCALE, ENEMY_SCALE_TIGHT]:
		var ok := true
		for i in n - 1:
			var right: float = enemy_extent(list[i].data)[1]
			var left: float = enemy_extent(list[i + 1].data)[0]
			if (right + left) * s > xs[i + 1] - xs[i]:
				ok = false
		if ok:
			return s
	return ENEMY_SCALE_TIGHT


## How far an enemy's visible art reaches [left, right] of its centre at scale 1.
static func enemy_extent(d: FighterData) -> Array:
	if d.art == null:
		return [d.figure_width * 0.5, d.figure_width * 0.5]
	var r := ArtBounds.opaque_rect(d.art)
	var k := d.figure_height / float(d.art.get_height())
	var half := d.art.get_width() * 0.5
	return [(half - r.position.x) * k, (r.end.x - half) * k]


## Where enemy number i stands (world space).
func enemy_position(i: int) -> Vector2:
	var xs: Array = ENEMY_X[clampi(enemies.size(), 1, 3)]
	return Vector2(xs[mini(i, xs.size() - 1)], ENEMY_FEET_Y + _extra_height * 0.6)


## Fresh fight number `index`. Everyone at full HP.
## Skill charge: NEW_ACT = half charged, NEXT_FIGHT = carried over from the
## last fight, RETRY = whatever it was when this fight first began.
func _start_battle(index: int, mode := StartMode.RETRY) -> void:
	fight_index = index
	turn_count = 0
	target_index = -1
	_busy = false
	_skill_used_this_fight = false
	# New plates if the team changed (a Replace, or an evolution's new art).
	var stale := team_views.size() != team_data.size()
	for k in mini(team_views.size(), team_data.size()):
		stale = stale or team_views[k].data.display_name != team_data[k].display_name or team_views[k].data.art != team_data[k].art
	if stale:
		_build_team_views()
	var fight: FightData = test_fight_override if test_fight_override else act_fights[index]
	# Until Phase 6 levelling exists, the team is shown at the level a player
	# would normally have reached by this fight (balance is tuned for that).
	team_level = fight.expected_level if use_level_preview and CombatRules.PROGRESSION.preview_expected_level else 1
	var leveled: Array[FighterData] = []
	for d in team_data:
		leveled.append(CombatRules.at_level(d, team_level))
	team = Team.new(leveled)
	if mode == StartMode.RETRY and not _fight_start_turns.is_empty():
		team.skill_turns = _carried_charges(_fight_start_turns, _fight_start_uids)
	elif mode == StartMode.NEXT_FIGHT and not _act_skill_turns.is_empty():
		team.skill_turns = _carried_charges(_act_skill_turns, _act_skill_uids)
	else:
		for i in team_data.size():
			team.skill_turns[i] = CombatRules.act_start_turns(team_data[i])
	_fight_start_turns = team.skill_turns.duplicate()
	_fight_start_uids = _team_uids.duplicate()
	enemies.clear()
	for d in fight.enemies:
		enemies.append(Enemy.new(d))
	_build_enemy_views()
	for v in team_views:
		v.animator.reset()

	enemy_title.text = fight.display_name
	if profile:
		var lv := []
		for uid in _team_uids:
			lv.append(profile.unit(uid)["level"])
		level_label.text = "%s  ·  TEAM Lv%d-%d" % [_act_name(), lv.min(), lv.max()] if lv.min() != lv.max() else "%s  ·  TEAM Lv%d" % [_act_name(), lv.min()]
	else:
		level_label.text = "%s  ·  TEAM Lv%d%s" % [_act_name(), team_level, " (preview)" if team_level > 1 else ""]
	_update_enemy_labels()
	team_bar.set_values(team.hp, team.max_hp, false)
	_refresh_team_ui()
	result_panel.hide()
	skill_popup.hide()
	combo_counter.reset()
	board.fill_new_board()
	_begin_player_turn()
	# Boss fight: the singularity speaks first (5 s, skippable).
	if _is_boss_fight(index) and act.boss_taunt != "":
		_play_beat([act.boss_taunt], act.taunt_seconds, act.singularity_name.to_upper())


## Skill charge carried over from `turns` (saved for the hunters in `uids`).
## With a save, charge follows the HUNTER, so a replaced hunter's charge never
## moves to its replacement (a newcomer starts half charged, like a new Act).
## Without a save (tests), it follows the slot when the team size is the same.
func _carried_charges(turns: Array[int], uids: Array) -> Array[int]:
	var out: Array[int] = []
	for i in team_data.size():
		var j := -1
		if not _team_uids.is_empty() and uids.size() == turns.size():
			j = uids.find(_team_uids[i]) if i < _team_uids.size() else -1
		elif _team_uids.is_empty() and turns.size() == team_data.size():
			j = i
		out.append(turns[j] if j >= 0 else CombatRules.act_start_turns(team_data[i]))
	return out


## Unlock the board for a new player turn (skills can be used until an orb is picked up).
func _begin_player_turn() -> void:
	_player_turn = true
	for e in enemies:
		e.new_turn()   # Resolve: the per-turn damage limit starts over
	board.move_time = CombatRules.move_time(team)
	# Night Bloom: heal at the start of each of the next turns.
	if team.regen_turns > 0 and turn_count > 0:
		team.regen_turns -= 1
		_heal_fx(team.heal(roundi(team.max_hp * team.regen_ratio)), Color("6dff8a"))
		_refresh_team_ui()
	# Inferno Cleaver: burning enemies take their burn now. It can win the fight.
	if turn_count > 0 and _apply_burns():
		_player_turn = false
		board.lock()
		await _wait(0.85)
		_show_result(true)
		return
	board.begin_player_turn()


## Inferno Cleaver (Logan): every burning enemy takes its burn (start of your turn).
## Returns true if that defeated the last enemy.
func _apply_burns() -> bool:
	var any := false
	for k in enemies.size():
		var e := enemies[k]
		if e.is_defeated() or e.burn_turns <= 0:
			continue
		e.burn_turns -= 1
		var dealt := e.take_hit(e.burn_damage)
		enemy_views[k].animator.play_hit()
		enemy_bars[k].set_values(e.hp, e.data.max_hp)
		SkillFx.sheet(world, _enemy_center(k), SkillFx.SHEET_FOR_ELEMENT[Element.Type.FIRE], 200.0, 0.34)
		FloatingText.spawn(world, enemy_position(k) + Vector2(0, -230), "BURN %d" % dealt, Color("ff9a3d"), 54)
		if e.is_defeated():
			_enemy_down(k)
		any = true
	if any:
		_update_enemy_labels()
	return any and _all_enemies_down()


func _on_next_pressed() -> void:
	var next := fight_index + 1
	if next >= act_fights.size() and has_home:
		home_requested.emit()                 # finished the Act: back to the home screen
	elif next >= act_fights.size():
		_start_battle(0, StartMode.NEW_ACT)   # finished the Act: start it over
	else:
		_start_battle(next, StartMode.NEXT_FIGHT)


## Skill badges, LEADER tag and the shield/guard status line.
func _refresh_team_ui() -> void:
	for i in team_views.size():
		team_views[i].is_leader = (i == 0)
		var cd := team.members[i].skill_cooldown()
		team_views[i].set_skill(team.skill_turns[i] if cd > 0 else -1, cd)
	var parts := PackedStringArray()
	if team.bulwark_attacks > 0:
		parts.append("BULWARK: -%d%% x%d" % [roundi((1.0 - Skills.TUNING.bulwark_damage_taken) * 100), team.bulwark_attacks])
	for s in team.shields:
		parts.append("%s: %s x%d" % [s["name"], "BLOCK" if s["mult"] <= 0.0 else "-%d%%" % roundi((1.0 - s["mult"]) * 100), s["attacks"]])
	if team.guard_next_hit:
		parts.append("GUARD: -%d%% next hit" % roundi((1.0 - team.guard_mult) * 100))
	if team.regen_turns > 0:
		parts.append("NIGHT BLOOM x%d" % team.regen_turns)
	team_status_label.text = "   ".join(parts)


# ---------------------------------------------------------------- input

## Taps that the board didn't use: tapping an enemy targets it, tapping a
## hunter's card opens its skill pop-up.
func _unhandled_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press == null or not press.pressed or press.button_index != MOUSE_BUTTON_LEFT:
		return
	if board.state != Board.State.READY or result_panel.visible or skill_popup.visible or _busy or _overlay_open():
		return
	var p := world.get_global_transform_with_canvas().affine_inverse() * press.position
	for i in team_views.size():
		if team_views[i].hit_rect().has_point(p - team_views[i].position):
			open_skill_popup(i)
			get_viewport().set_input_as_handled()
			return
	for i in enemy_views.size():
		if enemies[i].is_defeated():
			continue
		if enemy_views[i].hit_rect().has_point((p - enemy_views[i].position) / enemy_views[i].scale):
			set_target(-1 if target_index == i else i)
			get_viewport().set_input_as_handled()
			return


## The board is LOCKED while the pop-up is open, so a tap on the pop-up's
## buttons can never pick up an orb underneath it.
func open_skill_popup(i: int) -> void:
	board.lock()
	skill_popup.open(i, team.members[i], i == 0, team.skill_turns[i], _player_turn, profile != null and i < _team_uids.size())


func _on_popup_closed() -> void:
	if _player_turn and not _busy and not result_panel.visible and not _overlay_open():
		board.begin_player_turn()


## The Replace picker or the detail screen is up (the board stays locked under them).
func _overlay_open() -> bool:
	return (roster_picker != null and roster_picker.visible) or (unit_detail != null and unit_detail.visible)


func _resume_after_overlay() -> void:
	if _player_turn and not _busy and not result_panel.visible and not _overlay_open() and not skill_popup.visible:
		board.begin_player_turn()


# ---------------------------------------------------------------- Stage 5: Replace / Details

## Has anything happened in this fight yet? (A move or a skill.)
func fight_started() -> bool:
	return turn_count > 0 or _skill_used_this_fight


## REPLACE (plate i): pick a hunter from the Roster for that team slot.
func open_replace(i: int) -> void:
	if profile == null or i >= _team_uids.size():
		return
	board.lock()
	_replace_slot = profile.data["team"].find(_team_uids[i])
	roster_picker.open(profile, _replace_slot)


## DETAILS (plate i): the full detail screen (training / evolving stay on the Roster).
func open_details(i: int) -> void:
	board.lock()
	if profile and i < _team_uids.size():
		unit_detail.open_unit(profile, _team_uids[i], true)
	else:
		unit_detail.open_fighter(team.members[i], team_level)


## The replacement goes into the team (saved). Before the first move of a fight
## it joins right away (the fight starts fresh); otherwise it joins from the next
## fight and the current team finishes this one. The old hunter goes back to the
## Roster (or swaps slots if the new one was already in the team).
func _on_replace_picked(uid: int) -> void:
	var slot := _replace_slot
	var team_list: Array = profile.data["team"]
	var old: int = int(team_list[slot]) if slot >= 0 and slot < team_list.size() else -1
	profile.set_team_slot(slot, uid)
	progress_changed.emit()
	var new_name := Catalog.display_name(profile.unit(uid)["id"])
	var where := ""
	if old >= 0 and old != uid:
		var moved: int = profile.data["team"].find(old)
		where = "  ·  %s %s" % [Catalog.display_name(profile.unit(old)["id"]), "moves to slot %d" % (moved + 1) if moved >= 0 else "goes back to your Roster"]
	if not fight_started():
		_load_profile_team()
		_start_battle(fight_index, StartMode.RETRY)
		show_notice("%s joins the team now%s" % [new_name, where])
	else:
		show_notice("%s joins from the next fight%s" % [new_name, where])


func show_notice(text: String) -> void:
	notice_label.text = text
	if _notice_tween and _notice_tween.is_valid():
		_notice_tween.kill()
	notice_label.modulate.a = 1.0
	_notice_tween = create_tween()
	_notice_tween.tween_interval(2.6)
	_notice_tween.tween_property(notice_label, "modulate:a", 0.0, 0.5)


func _can_use_skills() -> bool:
	return _player_turn and not _busy and not result_panel.visible \
		and (board.state == Board.State.READY or board.state == Board.State.LOCKED)


# ---------------------------------------------------------------- active skills

## Use hunter i's active skill (only before moving orbs, only when charged).
## Returns false if it can't be used right now. Never ends the turn.
func use_skill(i: int) -> bool:
	if i < 0 or i >= team.members.size() or not team.skill_ready(i):
		return false
	if not _can_use_skills():
		return false
	_busy = true
	_skill_used_this_fight = true
	board.lock()
	var member := team.members[i]
	var t := Skills.TUNING
	team.skill_turns[i] = member.skill_cooldown()
	# Skill cut-in over the board first (tap to skip; off in Settings). The arena
	# stays visible; the effects and damage numbers land after it clears.
	if GameSettings.skill_cut_ins:
		await cut_in.play(member, Skills.display_name(member.active_skill))
	team_views[i].light_up()
	team_views[i].animator.play_attack(Vector2.UP)
	FloatingText.spawn(world, team_views[i].position + Vector2(0, -team_views[i].card_size.y - 20), Skills.display_name(member.active_skill).to_upper() + "!", Element.color(member.element).lightened(0.4), 58, 50.0, 0.6)
	await _wait(0.2)   # Stage 4: every skill finishes in under 1.0 s

	var col := Element.color(member.element)
	var from_pos := team_views[i].position + Vector2(0, -team_views[i].card_size.y * 0.55)
	SkillFx.ring(world, from_pos, col, 40.0, 190.0, 0.4)
	match member.active_skill:
		&"overrun":
			# Every orb of the element this hunter beats becomes its own element.
			var from: int = Element.BEATS.get(member.element, -1)
			_board_burst(col)
			var changed := board.convert_type(from, member.element)
			FloatingText.spawn(world, board.position + Vector2(495, 400), "%d %s -> %s" % [changed, Element.display_name(from), Element.display_name(member.element)], col.lightened(0.4), 52, 40.0, 0.6)
		&"bulwark":
			team.bulwark_attacks = t.bulwark_attacks
			_team_dome(col)
		&"execute":
			var target := CombatRules.pick_target(enemies, target_index)
			if target >= 0:
				var enemy := enemies[target]
				await _strike_fx(from_pos, target, col, 20.0, member.element)
				var damage := CombatRules.execute_damage(member, enemy)
				var dealt := enemy.take_hit(damage, true)   # a skill hit always breaks armour
				_show_hit(target, dealt, member, 1)
				_update_enemy_labels()
		&"mend":
			var healed := team.heal(roundi(team.max_hp * t.mend_heal_ratio))
			_heal_fx(healed, Color("6dff8a"))
			_board_burst(Element.color(Element.Type.HEART))
			board.convert_random(t.mend_hearts, Element.Type.HEART)
		&"night_rend":
			# Hits EVERY enemy for ATK x2 (its element), and breaks their armour.
			for k in enemies.size():
				if enemies[k].is_defeated():
					continue
				var c := _enemy_center(k)
				SkillFx.streak(world, c + Vector2(-140, -140), c + Vector2(140, 140), col, 22.0, 0.3)
				SkillFx.streak(world, c + Vector2(140, -140), c + Vector2(-140, 140), col, 22.0, 0.3)
			await _wait(0.16)
			_shake_screen(9.0, 0.25)
			for k in enemies.size():
				if enemies[k].is_defeated():
					continue
				SkillFx.ring(world, _enemy_center(k), col, 30.0, 170.0, 0.4)
				var dealt := enemies[k].take_hit(CombatRules.skill_hit(member, enemies[k], t.night_rend_atk_mult), true)
				_show_hit(k, dealt, member, 1)
			_update_enemy_labels()
		&"solar_flare":
			# Bottom row -> its element; its element's hunters hit x1.5 this turn.
			var y := Board.ROWS - 1
			SkillFx.flash(world, board.position + Vector2(0, y * Board.CELL), Vector2(Board.COLS * Board.CELL, Board.CELL), Color(col, 0.75), 0.5)
			SkillFx.sparkles(world, board.position + Vector2(Board.COLS * Board.CELL * 0.5, (y + 0.5) * Board.CELL), Vector2(480, 40), col, 24)
			for x in Board.COLS:
				(board.grid[x][y] as Orb).change_to(member.element)
			team.boost_element = member.element
			team.boost_mult = t.solar_flare_atk_mult
			FloatingText.spawn(world, board.position + Vector2(495, 400), "%s x%s THIS TURN" % [Element.display_name(member.element), Skills._num(t.solar_flare_atk_mult)], col.lightened(0.4), 50, 40.0, 0.6)
		&"ember_lance", &"thorn_snipe", &"undertow_strike", &"radiant_pierce":
			var target := CombatRules.pick_target(enemies, target_index)
			if target >= 0:
				var enemy := enemies[target]
				var mult := 1.0
				match member.active_skill:
					&"ember_lance": mult = t.ember_lance_atk_mult
					&"thorn_snipe": mult = t.thorn_snipe_atk_mult
					&"undertow_strike": mult = t.undertow_low_atk_mult if enemy.hp_ratio() < t.undertow_low_ratio else t.undertow_atk_mult
					&"radiant_pierce": mult = t.radiant_pierce_atk_mult
				await _strike_fx(from_pos, target, col, 30.0 if member.active_skill == &"ember_lance" else 18.0, member.element)
				# Skill hits break armour (Ember Lance goes straight through it).
				var dealt := enemy.take_hit(CombatRules.skill_hit(member, enemy, mult), true)
				_show_hit(target, dealt, member, 1)
				if member.active_skill == &"thorn_snipe" and not enemy.is_defeated():
					enemy.vulnerable_turns = t.thorn_snipe_turns
					enemy.vulnerable_mult = t.thorn_snipe_vulnerable
					FloatingText.spawn(world, _enemy_center(target) + Vector2(0, -150), "VULNERABLE +%d%%" % roundi((t.thorn_snipe_vulnerable - 1.0) * 100), col.lightened(0.4), 42, 40.0, 0.6)
				if member.active_skill == &"radiant_pierce":
					_board_burst(col)
					board.convert_random(t.radiant_pierce_orbs, member.element)
				_update_enemy_labels()
		&"forge_guard":
			team.add_shield("FORGE GUARD", t.forge_guard_attacks, t.forge_guard_damage_taken, i)
			_team_dome(col)
		&"tidewall":
			_heal_fx(team.heal(roundi(team.max_hp * t.tidewall_heal_ratio)), Color("6dff8a"))
			team.add_shield("TIDEWALL", t.tidewall_attacks, t.tidewall_damage_taken)
			_team_dome(col)
		&"gravity_well":
			for k in enemies.size():
				if enemies[k].is_defeated():
					continue
				SkillFx.ring(world, _enemy_center(k), col, 220.0, 20.0, 0.6, 16.0)
				_weaken(enemies[k], t.gravity_well_turns, t.gravity_well_atk_mult)
				FloatingText.spawn(world, _enemy_center(k) + Vector2(0, -150), "ATK -%d%%" % roundi((1.0 - t.gravity_well_atk_mult) * 100), col.lightened(0.4), 46, 40.0, 0.6)
		&"sanctuary":
			team.add_shield("SANCTUARY", t.sanctuary_blocks, 0.0)
			_team_dome(Color("ffe9a0"))
			_heal_fx(team.heal(roundi(team.max_hp * t.sanctuary_heal_ratio)), Color("6dff8a"))
		&"spore_bloom":
			_board_burst(Element.color(Element.Type.HEART))
			var changed := board.convert_type(Element.Type.DARK, Element.Type.HEART)
			FloatingText.spawn(world, board.position + Vector2(495, 400), "%d DARK -> HEART" % changed, Element.color(Element.Type.HEART).lightened(0.3), 52, 40.0, 0.6)
		&"cauterize":
			_heal_fx(team.heal(roundi(team.max_hp * t.cauterize_heal_ratio)), Color("6dff8a"))
			team.boost_element = member.element
			team.boost_mult = t.cauterize_atk_mult
			FloatingText.spawn(world, board.position + Vector2(495, 400), "%s x%s THIS TURN" % [Element.display_name(member.element), Skills._num(t.cauterize_atk_mult)], col.lightened(0.4), 50, 40.0, 0.6)
		&"night_bloom":
			team.regen_turns = t.night_bloom_turns
			team.regen_ratio = t.night_bloom_heal_ratio
			SkillFx.sparkles(world, _team_text_pos() + Vector2(0, -120), Vector2(420, 60), col.lightened(0.3), 26, 1.0)
		&"dawn_chorus":
			_board_burst(Element.color(Element.Type.HEART))
			board.convert_random(t.dawn_chorus_hearts, Element.Type.HEART)
			board.move_time += t.dawn_chorus_seconds
			_on_timer_changed(1.0)
			FloatingText.spawn(world, board.position + Vector2(495, 400), "+%s s THIS TURN" % Skills._num(t.dawn_chorus_seconds), col.lightened(0.4), 52, 40.0, 0.6)
		# ---- playable enemies (Stage 3 Part B)
		&"cinder_burst":
			# Hits EVERY enemy for ATK x1.5 (its element).
			for k in enemies.size():
				if not enemies[k].is_defeated():
					SkillFx.streak(world, from_pos, _enemy_center(k), col, 16.0, 0.28)
			await _wait(0.14)
			_shake_screen(7.0, 0.2)
			for k in enemies.size():
				if enemies[k].is_defeated():
					continue
				SkillFx.ring(world, _enemy_center(k), col, 20.0, 150.0, 0.4)
				var dealt := enemies[k].take_hit(CombatRules.skill_hit(member, enemies[k], t.cinder_burst_atk_mult), true)
				_show_hit(k, dealt, member, 1)
			_update_enemy_labels()
		&"coolant_flush":
			var from: int = Element.BEATS.get(member.element, -1)
			_board_burst(Element.color(Element.Type.HEART))
			var changed := board.convert_type(from, Element.Type.HEART)
			FloatingText.spawn(world, board.position + Vector2(495, 400), "%d %s -> HEART" % [changed, Element.display_name(from)], Element.color(Element.Type.HEART).lightened(0.3), 52, 40.0, 0.6)
			_heal_fx(team.heal(roundi(team.max_hp * t.coolant_flush_heal_ratio)), Color("6dff8a"))
		&"spore_puff":
			_heal_fx(team.heal(roundi(team.max_hp * t.spore_puff_heal_ratio)), Color("6dff8a"))
			for k in enemies.size():
				if enemies[k].is_defeated():
					continue
				SkillFx.sparkles(world, _enemy_center(k), Vector2(120, 80), col.lightened(0.2), 16, 0.7)
				_weaken(enemies[k], 1, t.spore_puff_atk_mult)
				FloatingText.spawn(world, _enemy_center(k) + Vector2(0, -150), "NEXT HIT -%d%%" % roundi((1.0 - t.spore_puff_atk_mult) * 100), col.lightened(0.4), 42, 40.0, 0.6)
		&"sunburst_charge":
			SkillFx.flash(world, board.position, Vector2(Board.COLS * Board.CELL, Board.CELL), Color(col, 0.75), 0.5)
			SkillFx.sparkles(world, board.position + Vector2(Board.COLS * Board.CELL * 0.5, Board.CELL * 0.5), Vector2(480, 40), col, 24)
			for x in Board.COLS:
				(board.grid[x][0] as Orb).change_to(member.element)
			board.convert_random(t.sunburst_hearts, Element.Type.HEART, 0)   # not on the new top row
		&"twin_shiv", &"strangle", &"void_bite":
			var target := CombatRules.pick_target(enemies, target_index)
			if target >= 0:
				var enemy := enemies[target]
				var hits := 2 if member.active_skill == &"twin_shiv" else 1
				var mult: float = {&"twin_shiv": t.twin_shiv_atk_mult, &"strangle": t.strangle_atk_mult, &"void_bite": t.void_bite_atk_mult}[member.active_skill]
				var total := 0
				for h in hits:
					if enemy.is_defeated():
						break
					await _strike_fx(from_pos + Vector2((h * 2 - 1) * 40 if hits > 1 else 0, 0), target, col, 16.0, member.element)
					var dealt := enemy.take_hit(CombatRules.skill_hit(member, enemy, mult), true)
					total += dealt
					_show_hit(target, dealt, member, h)
				if member.active_skill == &"strangle" and not enemy.is_defeated():
					_weaken(enemy, 1, t.strangle_weaken_mult)
					FloatingText.spawn(world, _enemy_center(target) + Vector2(0, -150), "NEXT HIT -%d%%" % roundi((1.0 - t.strangle_weaken_mult) * 100), col.lightened(0.4), 42, 40.0, 0.6)
				if member.active_skill == &"void_bite":
					_heal_fx(team.heal(roundi(total * t.void_bite_lifesteal)), Color("6dff8a"))
				_update_enemy_labels()
		&"heat_vent":
			team.add_shield("HEAT VENT", t.heat_vent_attacks, t.heat_vent_damage_taken)
			_team_dome(col)
			team.boost_element = member.element
			team.boost_mult = t.heat_vent_atk_mult
			FloatingText.spawn(world, board.position + Vector2(495, 400), "%s x%s THIS TURN" % [Element.display_name(member.element), Skills._num(t.heat_vent_atk_mult)], col.lightened(0.4), 50, 40.0, 0.6)
		&"trident_wall":
			team.add_shield("TRIDENT WALL", t.trident_wall_attacks, t.trident_wall_damage_taken)
			_team_dome(col)
			_heal_fx(team.heal(roundi(team.max_hp * t.trident_wall_heal_ratio)), Color("6dff8a"))
		&"refract":
			var from: int = Element.BEATS.get(member.element, -1)
			_board_burst(col)
			var changed := board.convert_type(from, member.element)
			FloatingText.spawn(world, board.position + Vector2(495, 400), "%d %s -> %s" % [changed, Element.display_name(from), Element.display_name(member.element)], col.lightened(0.4), 52, 40.0, 0.6)
			_heal_fx(team.heal(roundi(team.max_hp * t.refract_heal_ratio)), Color("6dff8a"))
		# ---- Bailey's friends (ultra-rare drops)
		&"twin_comet":
			# Jake: hits EVERY enemy twice (its element), then random orbs -> its element.
			for h in t.twin_comet_hits:
				for k in enemies.size():
					if not enemies[k].is_defeated():
						SkillFx.streak(world, from_pos + Vector2((h * 2 - 1) * 60, 0), _enemy_center(k), col, 16.0, 0.26)
				await _wait(0.13)
				_shake_screen(6.0, 0.16)
				for k in enemies.size():
					if enemies[k].is_defeated():
						continue
					SkillFx.sheet(world, _enemy_center(k), SkillFx.SHEET_FOR_ELEMENT.get(member.element, ""), 250.0, 0.34)
					var dealt := enemies[k].take_hit(CombatRules.skill_hit(member, enemies[k], t.twin_comet_atk_mult), true)
					_show_hit(k, dealt, member, h)
				_update_enemy_labels()
			_board_burst(col)
			board.convert_random(t.twin_comet_orbs, member.element)
		&"thunder_hammer":
			# Johnny: a heavy hit that stuns (bosses: their next attack is weaker instead).
			var target := CombatRules.pick_target(enemies, target_index)
			if target >= 0:
				var enemy := enemies[target]
				await _strike_fx(from_pos, target, col, 28.0, member.element)
				_shake_screen(10.0, 0.25)
				var dealt := enemy.take_hit(CombatRules.skill_hit(member, enemy, t.thunder_hammer_atk_mult), true)
				_show_hit(target, dealt, member, 1)
				if not enemy.is_defeated():
					if enemy.data.is_boss:
						_weaken(enemy, 1, t.thunder_hammer_boss_weaken)
						FloatingText.spawn(world, _enemy_center(target) + Vector2(0, -150), "NEXT HIT -%d%%" % roundi((1.0 - t.thunder_hammer_boss_weaken) * 100), col.lightened(0.4), 42, 40.0, 0.6)
					else:
						enemy.stunned_attacks = maxi(enemy.stunned_attacks, 1)
						FloatingText.spawn(world, _enemy_center(target) + Vector2(0, -150), "STUNNED!", Color("ffe08a"), 50, 40.0, 0.7)
				_update_enemy_labels()
		&"overclock":
			# Khoel: every OTHER hunter's skill charges, and a small heal.
			for j in team.skill_turns.size():
				if j != i:
					team.skill_turns[j] = maxi(team.skill_turns[j] - t.overclock_turns, 0)
					SkillFx.ring(world, team_views[j].position + Vector2(0, -team_views[j].card_size.y * 0.55), col, 20.0, 130.0, 0.45)
			_heal_fx(team.heal(roundi(team.max_hp * t.overclock_heal_ratio)), Color("6dff8a"))
			FloatingText.spawn(world, board.position + Vector2(495, 400), "SKILLS +%d TURNS" % t.overclock_turns, col.lightened(0.4), 52, 40.0, 0.6)
		&"inferno_cleaver":
			# Logan: a big hit, then the target burns for 3 turns.
			var target := CombatRules.pick_target(enemies, target_index)
			if target >= 0:
				var enemy := enemies[target]
				await _strike_fx(from_pos, target, col, 30.0, member.element)
				var dealt := enemy.take_hit(CombatRules.skill_hit(member, enemy, t.inferno_cleaver_atk_mult), true)
				_show_hit(target, dealt, member, 1)
				if not enemy.is_defeated():
					enemy.burn_turns = t.inferno_burn_turns
					enemy.burn_damage = CombatRules.skill_hit(member, enemy, t.inferno_burn_mult)
					FloatingText.spawn(world, _enemy_center(target) + Vector2(0, -150), "BURNING x%d" % t.inferno_burn_turns, Color("ff9a3d"), 46, 40.0, 0.6)
				_update_enemy_labels()
	if member.has_passive(&"field_medic"):
		# Field Medic: using the skill charges every OTHER ally's skill by 1 turn.
		for j in team.skill_turns.size():
			if j != i:
				team.skill_turns[j] = maxi(team.skill_turns[j] - t.field_medic_turns, 0)
	_refresh_team_ui()
	await _wait(0.3)
	if _all_enemies_down():
		await _wait(0.6)
		_show_result(true)
		_busy = false
		return true
	_busy = false
	board.begin_player_turn()
	return true


## Weaken an enemy's next `attacks` attacks to x`mult` (keeps the stronger effect).
func _weaken(enemy: Enemy, attacks: int, mult: float) -> void:
	if enemy.weakened_attacks > 0:
		enemy.weakened_attacks = maxi(enemy.weakened_attacks, attacks)
		enemy.weakened_mult = minf(enemy.weakened_mult, mult)
	else:
		enemy.weakened_attacks = attacks
		enemy.weakened_mult = mult


## Skill FX helpers (code-only effects, see scripts/anim/skill_fx.gd).
func _enemy_center(k: int) -> Vector2:
	return enemy_position(k) + Vector2(0, -enemies[k].data.figure_height * 0.5 * enemy_scale)


## A beam from the hunter to enemy `target`, then a ring where it lands.
## Returns when the beam arrives, so the damage number shows on impact.
func _strike_fx(from_pos: Vector2, target: int, col: Color, w: float, element := -1) -> void:
	SkillFx.streak(world, from_pos, _enemy_center(target), col, w, 0.32)
	await _wait(0.15)
	SkillFx.ring(world, _enemy_center(target), col, 30.0, 180.0, 0.4)
	SkillFx.sheet(world, _enemy_center(target), SkillFx.SHEET_FOR_ELEMENT.get(element, ""))   # FX sheet if you've added it
	_shake_screen(6.0, 0.18)


func _board_burst(col: Color) -> void:
	var c := board.position + Vector2(Board.COLS * Board.CELL, Board.ROWS * Board.CELL) * 0.5
	SkillFx.ring(world, c, col, 60.0, 520.0, 0.5, 18.0)
	SkillFx.sparkles(world, c, Vector2(440, 330), col.lightened(0.2), 22)


## A shield dome over the team cards.
func _team_dome(col: Color) -> void:
	SkillFx.dome(world, Vector2(540, TEAM_FEET_Y + _extra_height + 10), Vector2(520, 330), col.lightened(0.2), 1.0)


func _heal_fx(healed: int, col: Color) -> void:
	team_bar.set_values(team.hp, team.max_hp)
	SkillFx.sparkles(world, _team_text_pos() + Vector2(0, -60), Vector2(420, 40), col, 20)
	SkillFx.sheet(world, _team_text_pos() + Vector2(0, -120), SkillFx.HEAL_SHEET, 240.0)   # fx_heal.png if added
	FloatingText.spawn(world, _team_text_pos(), "+%d" % healed, col, 64, 60.0)


## Choose which enemy single-target attacks go to (-1 = the front enemy).
func set_target(i: int) -> void:
	target_index = i
	_update_enemy_labels()


func _update_enemy_labels() -> void:
	for i in enemy_views.size():
		enemy_views[i].targeted = (i == target_index and not enemies[i].is_defeated())
	var shown := CombatRules.pick_target(enemies, target_index)
	if shown < 0:
		return
	var e := enemies[shown]
	var prefix := "TARGET: " if target_index >= 0 else ""
	var who := e.data.display_name + (" (%s)" % e.data.title if e.data.title != "" else "")
	enemy_hint.text = "%s%s · %s   ·   %s" % [prefix, who, Element.display_name(e.data.element), _matchup_hint(e.data.element)]
	if enemies.size() == 1 and e.stunned_attacks > 0:
		enemy_attack_label.text = "STUNNED  ·  skips its next attack"
	elif enemies.size() == 1 and e.turn_room() >= 0:
		enemy_attack_label.text = "Attacks after your turn  ·  ATK %d  ·  RESOLVE: max -%d%% HP per turn" % [e.data.atk, roundi(Skills.TUNING.boss_turn_cap * 100)]
	elif enemies.size() == 1:
		enemy_attack_label.text = "Attacks after your turn  ·  ATK %d" % e.data.atk
	else:
		enemy_attack_label.text = "%d enemies · each attacks after your turn · tap one to target it" % enemies.size()


# ---------------------------------------------------------------- board events

func _on_timer_changed(ratio: float) -> void:
	match board.state:
		Board.State.DRAGGING:
			timer_bar.set_ratio(ratio, "%.1f s" % (ratio * board.move_time), true)
		Board.State.READY:
			timer_bar.set_ratio(1.0, "DRAG AN ORB  ·  %s s starts on pickup" % _seconds_text(board.move_time), false)
		_:
			timer_bar.set_ratio(0.0, "", false)


## Show "COMBO n" right where the group cleared.
## Every combo tick (cascades too): the popup at the group AND the big counter
## both show the count and the multiplier right now.
func _on_combo_made(count: int, _orb_type: int, world_position: Vector2) -> void:
	var color := Color.WHITE
	if count >= 8:
		color = Color("ff7a3d")
	elif count >= 5:
		color = Color("ffd23f")
	FloatingText.spawn(world, world.to_local(world_position), "COMBO %d  %s" % [count, ComboCounter.multiplier_text(count)], color, 50, 40.0, 0.7)
	combo_counter.tick(count)


## The rest of the turn after the board finishes.
func _on_turn_finished(combos: int, cleared: Dictionary, groups: Array) -> void:
	turn_count += 1
	await _wait(0.15)

	# 1) Healing: Hearts (+ Overflow Heal, + Biotech leader). Never above max HP.
	var hearts: int = cleared.get(Element.Type.HEART, 0)
	var heal_amount := CombatRules.turn_heal(team, hearts, groups)
	if hearts > 0 or heal_amount > 0:
		var healed := team.heal(heal_amount)
		team_bar.set_values(team.hp, team.max_hp)
		FloatingText.spawn(world, _team_text_pos(), "+%d" % healed, Color("6dff8a"), 64, 60.0)
		SkillFx.sheet(world, _team_text_pos() + Vector2(0, -120), SkillFx.HEAL_SHEET, 220.0, 0.45)
		if hearts > 0 and Skills.TUNING.combo_boosts_healing:
			# Hearts x RCV x combo: show the multiplier on the heal too.
			FloatingText.spawn(world, _team_text_pos() + Vector2(150, 0), "x%.2f" % DamageCalculator.combo_multiplier(combos), Color("ffe9a0"), 30, 60.0)
		await _wait(0.35)
	# Stone Wall leader: matching Hearts arms a guard against the next enemy hit.
	# Riptide leader: a 4+ group of its element does the same (smaller guard).
	var lead := team.leader()
	if hearts > 0 and lead.leader_skill == &"leader_titan":
		team.guard_next_hit = true
		team.guard_mult = Skills.TUNING.leader_titan_damage_taken
		_refresh_team_ui()
	elif lead.leader_skill == &"leader_riptide" and CombatRules.has_group(groups, lead.element, Skills.TUNING.leader_berserker_group):
		team.guard_next_hit = true
		team.guard_mult = Skills.TUNING.leader_riptide_damage_taken
		_refresh_team_ui()

	# Skills charge by one turn, but only on turns where you made a match.
	if combos > 0:
		team.tick_skills()
		# Neural Link (Khoel leader): 3+ elements matched -> every skill 1 extra turn.
		var extra := CombatRules.leader_skill_charge(team.leader(), groups)
		if extra > 0:
			team.tick_skills(extra)
		# Heart Charge: 5+ Hearts this turn charge that hunter's skill 1 extra turn.
		for k in team.members.size():
			if team.members[k].has_passive(&"heart_charge") and hearts >= Skills.TUNING.heart_charge_hearts:
				team.skill_turns[k] = maxi(team.skill_turns[k] - Skills.TUNING.heart_charge_turns, 0)
		_refresh_team_ui()

	# 2) Each hunter whose element was cleared attacks.
	for i in team_views.size():
		var member := team.members[i]
		var orbs: int = cleared.get(member.element, 0)
		if orbs <= 0:
			continue
		var targets := CombatRules.targets_for(member, groups, enemies, target_index)
		if targets.is_empty():
			break
		var first_attack := not team.has_attacked[i]   # Ambush
		team.has_attacked[i] = true
		team_views[i].light_up()
		team_views[i].animator.play_attack(Vector2.UP)
		await _wait(0.2)
		for t in targets:
			var enemy := enemies[t]
			# Leader skill x this hunter's passives x a one-turn skill boost
			# (worked out before the hit lands).
			var marked := target_index >= 0 and t == target_index
			var bonus := CombatRules.leader_multiplier(team.leader(), member, groups, combos, enemy, team, marked) \
				* CombatRules.passive_multiplier(member, groups, combos, enemy, first_attack, team) \
				* team.boost_for(member)
			var damage := DamageCalculator.attack_damage(member.atk, orbs, combos, member.element, enemy.data.element, bonus)
			damage = CombatRules.after_def(damage, enemy)
			var dealt := enemy.take_hit(damage, CombatRules.breaks_armor(member, groups), CombatRules.ignores_armor(member, groups))
			_show_hit(t, dealt, member, i, DamageCalculator.combo_multiplier(combos))
			# The attack animation of the hunter's element (doesn't slow the turn down).
			SkillFx.sheet(world, _enemy_center(t), SkillFx.SHEET_FOR_ELEMENT.get(member.element, ""), ATTACK_FX_HEIGHT, ATTACK_FX_TIME)
		await _wait(0.28)
		_update_enemy_labels()
		if _all_enemies_down():
			break
	team.boost_element = -1   # one-turn skill boosts (Solar Flare, Cauterize) end here
	combo_counter.fade_out()  # the combo never carries over to the enemy turn

	if _all_enemies_down():
		await _wait(0.85)
		_show_result(true)
		return

	# 3) Every enemy still alive attacks, one after another.
	var team_was_hit := false
	for t in enemies.size():
		var enemy := enemies[t]
		if enemy.is_defeated():
			continue
		# Thunder Hammer: a stunned enemy skips this attack.
		if enemy.stunned_attacks > 0:
			enemy.stunned_attacks -= 1
			_update_enemy_labels()
			await _wait(0.25)
			FloatingText.spawn(world, _enemy_center(t) + Vector2(0, -150), "STUNNED", Color("ffe08a"), 50, 40.0, 0.6)
			await _wait(0.35)
			continue
		team_was_hit = true
		await _wait(0.25)
		enemy_views[t].animator.play_attack(Vector2.DOWN)
		await _wait(0.2)
		var forge_counter := _forge_guard_member()   # read before the shield is used up
		var incoming := _enemy_attack_damage(enemy)
		# Last Stand (TEAM, once per fight): a hit that would defeat the team leaves 1 HP.
		var saved := false
		if incoming >= team.hp and team.hp > 0 and CombatRules.team_has(team, &"last_stand") and not team.last_stand_used:
			incoming = team.hp - 1
			team.last_stand_used = true
			saved = true
		var taken := team.take_damage(incoming)
		_refresh_team_ui()
		for v in team_views:
			v.animator.play_hit()
		team_bar.set_values(team.hp, team.max_hp)
		FloatingText.spawn(world, _team_text_pos(), "-%d" % taken, Color("ff5a5a"), 64, 60.0)
		if saved:
			FloatingText.spawn(world, _team_text_pos() + Vector2(0, -90), "LAST STAND!", Color("ffd23f"), 60, 50.0, 0.8)
			SkillFx.dome(world, Vector2(540, TEAM_FEET_Y + _extra_height + 10), Vector2(520, 330), Color("ffd23f"), 0.8)
		_shake_screen(5.0, 0.2)
		await _wait(0.35)
		if team.is_defeated():
			break
		# Counter (Titan passive): strike back at the enemy that just hit.
		# Retaliation doubles it while team HP is below 50%. Forge Guard adds one more strike.
		for k in team.members.size():
			var m := team.members[k]
			var hits := 0.0
			if m.has_passive(&"counter"):
				hits += Skills.TUNING.counter_atk_mult * (Skills.TUNING.retaliation_mult if m.has_passive(&"retaliation") and team.hp_ratio() < Skills.TUNING.retaliation_hp_ratio else 1.0)
			if k == forge_counter:
				hits += Skills.TUNING.forge_guard_counter_mult
			if hits > 0.0 and not enemy.is_defeated():
				var back := roundi(m.atk * hits * Element.multiplier(m.element, enemy.data.element))
				back = CombatRules.after_def(back, enemy)
				var dealt_back := enemy.take_hit(back)
				team_views[k].animator.play_attack(Vector2.UP)
				SkillFx.streak(world, team_views[k].position + Vector2(0, -150), _enemy_center(t), Element.color(m.element), 12.0, 0.25)
				_show_hit(t, dealt_back, m, k)
				await _wait(0.3)
		if _all_enemies_down():
			break

	# Storm Battery (Johnny): the team was hit this enemy turn -> its skill charges.
	if team_was_hit and not team.is_defeated():
		for k in team.members.size():
			if team.members[k].has_passive(&"storm_battery") and team.skill_turns[k] > 0:
				team.skill_turns[k] = maxi(team.skill_turns[k] - Skills.TUNING.storm_battery_turns, 0)
				FloatingText.spawn(world, team_views[k].position + Vector2(0, -team_views[k].card_size.y - 10), "CHARGE +%d" % Skills.TUNING.storm_battery_turns, Element.color(team.members[k].element).lightened(0.4), 34, 40.0, 0.6)
		_refresh_team_ui()

	if _all_enemies_down():
		await _wait(0.85)
		_show_result(true)
		return

	if team.is_defeated():
		for v in team_views:
			v.animator.play_defeat()
		await _wait(0.95)
		_show_result(false)
		return

	_begin_player_turn()


# ---------------------------------------------------------------- helpers

## Which hunter has an active Forge Guard (strikes back each attack), or -1.
func _forge_guard_member() -> int:
	for s in team.shields:
		if s["counter"] >= 0:
			return s["counter"]
	return -1


## How hard this enemy's attack lands after every damage cut, and uses them up:
##   Gravity Well (on the enemy)   x0.7 for its next 2 attacks
##   Bulwark (active)              x0.5 for the next 2 attacks
##   Forge Guard / Tidewall        x0.65 / x0.6 for the next 3 / 2 attacks
##   Sanctuary                     blocks the next attack completely
##   Leader guard                  x0.75 (Stone Wall) / x0.85 (Riptide), next hit only
##   Leader always-on              Dawn Aegis x0.85; Iron Pact x0.7 below 50% HP
##   Damage Resist (TEAM passive)  x0.9 (counts once)
func _enemy_attack_damage(enemy: Enemy) -> int:
	var t := Skills.TUNING
	var power := enemy.attack_power()
	var mult := 1.0
	if team.bulwark_attacks > 0:
		mult *= t.bulwark_damage_taken
		team.bulwark_attacks -= 1
	for s in team.shields:
		mult *= s["mult"]
		s["attacks"] -= 1
	team.shields = team.shields.filter(func(s: Dictionary) -> bool: return s["attacks"] > 0)
	if team.guard_next_hit:
		mult *= team.guard_mult
		team.guard_next_hit = false
	mult *= CombatRules.leader_damage_taken(team, enemy)
	if CombatRules.team_has(team, &"damage_resist"):
		mult *= t.damage_resist_taken
	return roundi(power * mult)


## One hit landing on enemy t: flash, HP bar, damage number, defeat.
func _show_hit(t: int, dealt: int, member: FighterData, attacker_index: int, combo_mult := 0.0) -> void:
	var enemy := enemies[t]
	enemy_views[t].animator.play_hit()
	enemy_bars[t].set_values(enemy.hp, enemy.data.max_hp)
	_show_damage(dealt, member, t, attacker_index, combo_mult)
	if enemy_views[t].armor_up and not enemy.armor_up:
		FloatingText.spawn(world, enemy_position(t) + Vector2(0, -enemy.data.figure_height * enemy_scale - 30), "ARMOUR BROKEN!", Color("8fd8ff"), 46, 50.0, 0.6)
	enemy_views[t].armor_up = enemy.armor_up
	if enemy.is_defeated():
		_enemy_down(t)


## Enemy t was just defeated (once per enemy): fall over, and the Executioner
## leader (Logan) charges every skill.
func _enemy_down(t: int) -> void:
	if enemy_views[t].has_meta("down"):
		return
	enemy_views[t].set_meta("down", true)
	enemy_views[t].targeted = false
	enemy_views[t].animator.play_defeat()
	var charge := CombatRules.leader_kill_charge(team.leader())
	if charge > 0:
		team.tick_skills(charge)
		_refresh_team_ui()


## Damage numbers in the attacker's colour. Super-effective hits are bigger with "!".
## combo_mult > 0: an orb attack; the combo multiplier that applied to THIS hit
## is shown next to the number (e.g. "x1.50"). Skill / counter hits pass 0.
func _show_damage(amount: int, member: FighterData, enemy_i: int, attacker_index: int, combo_mult := 0.0) -> void:
	var mult := Element.multiplier(member.element, enemies[enemy_i].data.element)
	var size := 66
	var text := str(amount)
	if mult > 1.0:
		size = 92
		text += "!"
	elif mult < 1.0:
		size = 48
	if enemies.size() > 1:
		size = int(size * 0.8)
	var spread := 170.0 if enemies.size() == 1 else 70.0
	var pos := enemy_position(enemy_i) + Vector2(-spread + attacker_index * spread, -230 - attacker_index * 24)
	FloatingText.spawn(world, pos, text, Element.color(member.element).lightened(0.3), size)
	if combo_mult > 0.0:
		FloatingText.spawn(world, pos + Vector2(0, size * 0.75), "x%.2f" % combo_mult, Color("ffe9a0"), 30, 110.0)


func _team_text_pos() -> Vector2:
	return team_bar.position + Vector2(team_bar.bar_size.x * 0.5, 15)


func _all_enemies_down() -> bool:
	for e in enemies:
		if not e.is_defeated():
			return false
	return true


func _matchup_hint(el: int) -> String:
	if Element.is_light_or_dark(el):
		return "Weak to %s (2x)" % Element.display_name(Element.beaten_by(el))
	if el == Element.Type.NONE or not Element.BEATS.has(el):
		return "No element: every attack is neutral (1x)"
	return "Weak to %s (2x)  ·  Resists %s (0.5x)" % [
		Element.display_name(Element.beaten_by(el)),
		Element.display_name(Element.BEATS[el]),
	]


func _seconds_text(s: float) -> String:
	return str(int(s)) if is_equal_approx(s, roundf(s)) else "%.1f" % s


func _show_result(won: bool) -> void:
	_player_turn = false
	board.lock()
	skill_popup.hide()
	if won:
		_act_skill_turns = team.skill_turns.duplicate()   # carry into the next fight
		_act_skill_uids = _team_uids.duplicate()
		fight_won.emit(fight_index)
	var is_last := fight_index >= act_fights.size() - 1
	var fight: FightData = test_fight_override if test_fight_override else act_fights[fight_index]
	var act_clear := won and _is_boss_fight(fight_index)
	if act_clear:
		# The Act's last word (10 s, skippable), then the codex entry unlocks.
		if act.outro_line != "":
			await story_beat.play([act.outro_line], act.outro_seconds, "")
		act_won.emit(act)
	# Rewards (real profile only): XP + level-ups, Credits, Essence, first-clear Keys.
	var reward_text := ""
	if profile:
		var fight_no := fight_index + 1 if act and test_fight_override == null else 0
		var r := profile.fight_rewards(fight, act.act_number if act else 1, won, _team_uids, act_clear, fight_no)
		last_rewards = r
		reward_text = Profile.rewards_text(r)
		_load_profile_team()   # new levels -> new stats for the next fight
		progress_changed.emit()
	var next_text := "Next Fight"
	if is_last:
		next_text = "Back to Star Map" if has_home else "Play %s Again" % _act_name().capitalize()
	result_panel.show_result(won, turn_count, next_text, fight.xp, (_act_name() + " CLEAR!") if won and is_last else "",
		("CODEX UNLOCKED: " + act.singularity_name.to_upper()) if act_clear else "", reward_text)


func _shake_screen(strength: float, duration: float) -> void:
	var tw := create_tween()
	var steps := 5
	for i in steps:
		var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
		tw.tween_property(world, "position", offset, duration / (steps + 1))
	tw.tween_property(world, "position", Vector2.ZERO, duration / (steps + 1))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _make_label(pos: Vector2, width: float, font_size: int, color: Color) -> Label:
	var label := Label.new()
	var s := LabelSettings.new()
	s.font_size = font_size
	s.font_color = color
	s.outline_size = maxi(5, int(font_size / 5.0))
	s.outline_color = Color(0.04, 0.02, 0.08)
	label.label_settings = s
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = pos
	label.size = Vector2(width, font_size * 1.4)
	label.z_index = FRONT_Z
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(label)
	return label
