class_name MatchFinder
extends RefCounted
## Finds matches on the board.
##
## Plain English:
## 1) Mark every orb that is part of a straight line of 3+ of the same type
##    (left-right or up-down).
## 2) Marked orbs of the same type that touch each other count as ONE combo.
##    (So an L-shape or a 3+3 cross is one combo, not two.)
##
## Input: grid[x][y] = orb type (int), or -1 for an empty cell.
## Output: an Array of combos, each { "type": int, "cells": Array[Vector2i] },
##         ordered bottom row first (it reads naturally as orbs clear).


static func find_combos(grid: Array, cols: int, rows: int) -> Array:
	var marked := []
	for x in cols:
		var column := []
		column.resize(rows)
		column.fill(false)
		marked.append(column)

	# Step 1a: horizontal lines of 3+.
	for y in rows:
		var x := 0
		while x < cols:
			var t: int = grid[x][y]
			var run := 1
			while t != -1 and x + run < cols and grid[x + run][y] == t:
				run += 1
			if t != -1 and run >= 3:
				for i in run:
					marked[x + i][y] = true
			x += run

	# Step 1b: vertical lines of 3+.
	for x in cols:
		var y := 0
		while y < rows:
			var t: int = grid[x][y]
			var run := 1
			while t != -1 and y + run < rows and grid[x][y + run] == t:
				run += 1
			if t != -1 and run >= 3:
				for i in run:
					marked[x][y + i] = true
			y += run

	# Step 2: flood-fill touching marked cells of the same type into combos.
	var visited := {}
	var combos := []
	for y in range(rows - 1, -1, -1):
		for x in cols:
			var start := Vector2i(x, y)
			if not marked[x][y] or visited.has(start):
				continue
			var t: int = grid[x][y]
			var cells: Array[Vector2i] = []
			var stack: Array[Vector2i] = [start]
			visited[start] = true
			while not stack.is_empty():
				var c: Vector2i = stack.pop_back()
				cells.append(c)
				for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var n: Vector2i = c + d
					if n.x < 0 or n.y < 0 or n.x >= cols or n.y >= rows:
						continue
					if visited.has(n) or not marked[n.x][n.y] or grid[n.x][n.y] != t:
						continue
					visited[n] = true
					stack.append(n)
			combos.append({"type": t, "cells": cells})
	return combos
