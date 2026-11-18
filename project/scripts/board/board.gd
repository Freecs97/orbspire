class_name Board
extends Node2D
## The 6 x 5 orb board: drag input, the 5-second move timer, matching,
## gravity and refilling.
##
## Plain English:
## - Press on an orb to pick it up. The 5 s timer starts right then.
## - Move your finger: every orb you pass over swaps with the one you hold.
## - Let go (or run out of time): matches clear one combo at a time, orbs above
##   fall down, new orbs drop in, and any new matches count as more combos.
## - When nothing else matches, the board reports what was cleared.
## The board does NOT know about damage. The battle script does that.

## Emitted when the player picks up an orb.
signal move_started
## 1.0 = full time left, 0.0 = out of time.
signal timer_changed(ratio: float)
## One combo cleared. world_position = the middle of the matched group.
signal combo_made(combo_count: int, orb_type: int, world_position: Vector2)
## Whole turn done. cleared = { orb type: number of orbs cleared }.
## groups = every matched group, in the order it cleared:
##   [{ "type": orb type, "cells": [Vector2i, ...] }, ...]
## (Skills need the groups: "4+ orbs in one group", "a 3x3 square", etc.)
signal turn_finished(combos: int, cleared: Dictionary, groups: Array)

const COLS := 6
const ROWS := 5
const CELL := 165.0
const MOVE_TIME := 5.0      ## Normal move time. Time Extend adds to move_time.
const HELD_SCALE := 1.15
const SWAP_TIME := 0.12
const POP_GAP := 0.24       ## Pause between each combo popping.
const TRAIL_POINTS := 16    ## Length of the glowing drag trail.
const CORNER_ZONE := 0.25   ## Outer 25% of a cell counts as "heading diagonally".

enum State { LOCKED, READY, DRAGGING, RESOLVING }

var state: State = State.LOCKED
var grid: Array = []        ## grid[x][y] -> Orb (or null while empty)
var move_time := MOVE_TIME  ## Seconds you can hold an orb this turn.

var _held: Orb = null
var _held_cell := Vector2i.ZERO
var _time_left := 0.0
var _trail: Line2D


func _ready() -> void:
	_trail = Line2D.new()
	_trail.width = 30.0
	_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.z_index = 1
	add_child(_trail)
	fill_new_board()


# ---------------------------------------------------------------- public API

## Let the player move.
func begin_player_turn() -> void:
	state = State.READY
	timer_changed.emit(1.0)


## Stop all input (enemy turn, WIN / LOSE screen).
func lock() -> void:
	state = State.LOCKED


## Wipe the board and deal a fresh one with NO ready-made matches.
func fill_new_board() -> void:
	for column in grid:
		for orb in column:
			if orb:
				orb.queue_free()
	grid.clear()
	for x in COLS:
		var column := []
		column.resize(ROWS)
		grid.append(column)
	for x in COLS:
		for y in ROWS:
			grid[x][y] = _spawn_orb(_safe_type(x, y), cell_center(Vector2i(x, y)))


## Centre of a cell, in board-local pixels.
func cell_center(c: Vector2i) -> Vector2:
	return Vector2((c.x + 0.5) * CELL, (c.y + 0.5) * CELL)


## Turn every orb of one type into another (used by board-change skills).
## Returns how many orbs changed.
func convert_type(from_type: int, to_type: int) -> int:
	var changed := 0
	for x in COLS:
		for y in ROWS:
			var orb: Orb = grid[x][y]
			if orb and orb.orb_type == from_type:
				orb.change_to(to_type)
				changed += 1
	return changed


## Turn `count` random orbs that are NOT `to_type` into `to_type`.
## Returns how many orbs changed (fewer if the board runs out).
func convert_random(count: int, to_type: int) -> int:
	var cells: Array[Vector2i] = []
	for x in COLS:
		for y in ROWS:
			var orb: Orb = grid[x][y]
			if orb and orb.orb_type != to_type:
				cells.append(Vector2i(x, y))
	cells.shuffle()
	var n := mini(count, cells.size())
	for i in n:
		var orb: Orb = grid[cells[i].x][cells[i].y]
		orb.change_to(to_type)
	return n


## How many orbs of a type are on the board right now.
func count_type(type: int) -> int:
	var n := 0
	for x in COLS:
		for y in ROWS:
			var orb: Orb = grid[x][y]
			if orb and orb.orb_type == type:
				n += 1
	return n


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	var size := Vector2(COLS * CELL, ROWS * CELL)
	# Frame around the board.
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("0d1020")
	frame.set_corner_radius_all(22)
	frame.border_color = Color("3b4470")
	frame.set_border_width_all(3)
	draw_style_box(frame, Rect2(Vector2(-12, -12), size + Vector2(24, 24)))
	# Checkerboard tiles.
	for x in COLS:
		for y in ROWS:
			var tile := Color("232a44") if (x + y) % 2 == 0 else Color("1a2036")
			draw_rect(Rect2(x * CELL, y * CELL, CELL, CELL), tile)
	# Faint top sheen so the board feels lit from above.
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, CELL * 0.6)), Color(1, 1, 1, 0.03))


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	var mouse := event as InputEventMouse
	if mouse == null:
		return
	# Convert the screen position into board-local pixels.
	var local := make_input_local(mouse) as InputEventMouse
	var pos := local.position
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed and state == State.READY and _inside(pos):
			_start_drag(pos)
			get_viewport().set_input_as_handled()
		elif not button.pressed and state == State.DRAGGING:
			_end_drag()
	elif event is InputEventMouseMotion and state == State.DRAGGING:
		_drag_to(pos)


func _process(delta: float) -> void:
	if state != State.DRAGGING:
		return
	_time_left -= delta
	timer_changed.emit(maxf(_time_left, 0.0) / move_time)
	if _time_left <= 0.0:
		_end_drag()


func _start_drag(pos: Vector2) -> void:
	_held_cell = _cell_at(pos)
	_held = grid[_held_cell.x][_held_cell.y]
	_held.held = true
	_held.z_index = 2
	_held.scale = Vector2.ONE * HELD_SCALE
	_held.position = pos
	_time_left = move_time
	var c := Element.color(_held.orb_type)
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(c, 0.0), Color(c.lightened(0.3), 0.7)])
	_trail.gradient = fade
	_trail.clear_points()
	_trail.add_point(pos)
	state = State.DRAGGING
	move_started.emit()
	timer_changed.emit(1.0)


func _drag_to(pos: Vector2) -> void:
	var limit := Vector2(COLS * CELL, ROWS * CELL) - Vector2.ONE
	var p := pos.clamp(Vector2.ZERO, limit)
	_held.position = p
	_trail.add_point(p)
	if _trail.get_point_count() > TRAIL_POINTS:
		_trail.remove_point(0)
	var target := _cell_at(p)
	if target == _held_cell:
		return
	# Forgiving diagonals: if the finger only just clipped the corner of a
	# side neighbour on its way to a diagonal cell, wait a moment instead of
	# swapping sideways. When it reaches the diagonal cell we swap diagonally.
	if _is_corner_clip(p, target):
		return
	# Walk one cell at a time so a fast swipe still swaps every orb it crosses.
	while target != _held_cell:
		var step := Vector2i(signi(target.x - _held_cell.x), signi(target.y - _held_cell.y))
		_swap_held_with(_held_cell + step)


## True when the finger has entered a SIDE neighbour (left/right/up/down) but is
## still inside the outer quarter of it, right next to a diagonal cell.
## That usually means "I'm heading diagonally", so we hold off the side swap.
func _is_corner_clip(p: Vector2, target: Vector2i) -> bool:
	var d := target - _held_cell
	if absi(d.x) + absi(d.y) != 1:
		return false
	var inside := p - Vector2(target) * CELL   # finger position within the target cell
	var zone := CELL * CORNER_ZONE
	if d.x != 0:
		# Moved sideways: are we hugging the top or bottom edge (toward a diagonal)?
		return (inside.y < zone and target.y > 0) or (inside.y > CELL - zone and target.y < ROWS - 1)
	# Moved up/down: are we hugging the left or right edge?
	return (inside.x < zone and target.x > 0) or (inside.x > CELL - zone and target.x < COLS - 1)


func _swap_held_with(c: Vector2i) -> void:
	var other: Orb = grid[c.x][c.y]
	grid[_held_cell.x][_held_cell.y] = other
	grid[c.x][c.y] = _held
	other.move_to(cell_center(_held_cell), SWAP_TIME)
	_held_cell = c


func _end_drag() -> void:
	state = State.RESOLVING
	_held.held = false
	_held.z_index = 0
	var tw := _held.create_tween()
	tw.tween_property(_held, "scale", Vector2.ONE, 0.08)
	_held.move_to(cell_center(_held_cell), 0.08)
	_held = null
	_trail.clear_points()
	timer_changed.emit(0.0)
	_resolve()


# ---------------------------------------------------------------- resolving

## Clear combos one by one, drop orbs, refill, repeat until no matches.
func _resolve() -> void:
	await get_tree().create_timer(0.12).timeout
	var combos := 0
	var cleared := {}
	var groups: Array = []
	for t in Element.BOARD_TYPES:
		cleared[t] = 0
	while true:
		var found := MatchFinder.find_combos(_type_grid(), COLS, ROWS)
		if found.is_empty():
			break
		for combo in found:
			combos += 1
			var cells: Array = combo["cells"]
			var t: int = combo["type"]
			cleared[t] += cells.size()
			groups.append({"type": t, "cells": cells.duplicate()})
			combo_made.emit(combos, t, to_global(_cells_center(cells)))
			_pop_cells(cells)
			await get_tree().create_timer(POP_GAP).timeout
		await get_tree().create_timer(0.1).timeout
		await _drop_and_refill()
	turn_finished.emit(combos, cleared, groups)


func _pop_cells(cells: Array) -> void:
	for c in cells:
		var orb: Orb = grid[c.x][c.y]
		grid[c.x][c.y] = null
		if orb:
			orb.pop()


## Gravity: slide orbs down into gaps, then drop new random orbs in from above.
func _drop_and_refill() -> void:
	var longest := 0.0
	for x in COLS:
		var write_y := ROWS - 1
		for y in range(ROWS - 1, -1, -1):
			var orb: Orb = grid[x][y]
			if orb == null:
				continue
			if y != write_y:
				grid[x][write_y] = orb
				grid[x][y] = null
				longest = maxf(longest, _fall(orb, Vector2i(x, write_y), write_y - y))
			write_y -= 1
		# New orbs start above the board (hidden behind the scenery) and fall in.
		var missing := write_y + 1
		for y in range(write_y, -1, -1):
			var start := cell_center(Vector2i(x, y)) - Vector2(0, CELL * missing)
			var fresh := _spawn_orb(Element.BOARD_TYPES.pick_random(), start)
			grid[x][y] = fresh
			longest = maxf(longest, _fall(fresh, Vector2i(x, y), missing))
	if longest > 0.0:
		await get_tree().create_timer(longest).timeout


func _fall(orb: Orb, cell: Vector2i, rows: int) -> float:
	var duration := 0.18 + 0.06 * rows
	orb.move_to(cell_center(cell), duration, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	return duration


# ---------------------------------------------------------------- helpers

func _spawn_orb(type: int, pos: Vector2) -> Orb:
	var orb := Orb.new()
	orb.setup(type)
	orb.position = pos
	add_child(orb)
	return orb


## A random type that won't create a 3-in-a-row with the orbs already placed
## to the left or above. Used only for a brand-new board.
func _safe_type(x: int, y: int) -> int:
	var options: Array = Element.BOARD_TYPES.duplicate()
	if x >= 2 and _type_at(x - 1, y) == _type_at(x - 2, y):
		options.erase(_type_at(x - 1, y))
	if y >= 2 and _type_at(x, y - 1) == _type_at(x, y - 2):
		options.erase(_type_at(x, y - 1))
	return options.pick_random()


func _type_at(x: int, y: int) -> int:
	var orb: Orb = grid[x][y]
	return orb.orb_type if orb else -1


func _type_grid() -> Array:
	var types := []
	for x in COLS:
		var column := []
		for y in ROWS:
			column.append(_type_at(x, y))
		types.append(column)
	return types


func _cells_center(cells: Array) -> Vector2:
	var sum := Vector2.ZERO
	for c in cells:
		sum += cell_center(c)
	return sum / cells.size()


func _cell_at(local_pos: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(local_pos.x / CELL), 0, COLS - 1),
		clampi(int(local_pos.y / CELL), 0, ROWS - 1))


func _inside(local_pos: Vector2) -> bool:
	return Rect2(0, 0, COLS * CELL, ROWS * CELL).has_point(local_pos)
