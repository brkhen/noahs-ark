class_name WordSearch
extends RefCounted
## Word Search's rules, without any screen: three rounds of words from the story hidden in
## a square of letters (7, then 8, then 9 across), in any of the eight directions. Same
## rounds as the prototype (docs/prototype/story-games.html, WS_ROUNDS). A word is picked
## by its first and last letter (or a slide across it); any straight line is allowed.

const ROUNDS := [
	{"size": 7, "words": [["NOAH", "Noah"], ["SHEM", "Shem"], ["HAM", "Ham"],
		["JAPHETH", "Japheth"], ["ARK", "Ark"], ["DOVE", "Dove"]]},
	{"size": 8, "words": [["PITCH", "Pitch"], ["FLOOD", "Flood"], ["RAVEN", "Raven"],
		["ALTAR", "Altar"], ["ARARAT", "Ararat"], ["CANAAN", "Canaan"]]},
	{"size": 9, "words": [["CYPRESS", "Cypress"], ["OLIVELEAF", "Olive Leaf"],
		["NEPHILIM", "Nephilim"], ["COVENANT", "Covenant"], ["RAINBOW", "Rainbow"],
		["VINEYARD", "Vineyard"]]},
]
const DIRS := [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]

var round_index := 0
var size := 7
var grid: Array = [] ## grid[row][col] is a letter
var placements: Array = [] ## {"word", "label", "cells": [Vector2i(row, col)...]}, in the round's order
var found: Array = [] ## words found this round
var _rng := RandomNumberGenerator.new()


func start(index: int = 0, rng: RandomNumberGenerator = null) -> void:
	round_index = clampi(index, 0, ROUNDS.size() - 1)
	if rng != null:
		_rng = rng
	else:
		_rng.randomize()
	size = ROUNDS[round_index]["size"]
	found.clear()
	# Keep trying until every word fits, so a word is never listed but missing.
	for attempt in 200:
		if _try_fill():
			return


func words() -> Array:
	return ROUNDS[round_index]["words"]


func label_of(word: String) -> String:
	for w: Array in words():
		if w[0] == word:
			return w[1]
	return word


## The cells from a to b, if they're in a straight line (across, down or diagonal); else [].
static func line_between(a: Vector2i, b: Vector2i) -> Array:
	var d := b - a
	if not (d.x == 0 or d.y == 0 or absi(d.x) == absi(d.y)):
		return []
	var steps := maxi(absi(d.x), absi(d.y))
	var step := Vector2i(signi(d.x), signi(d.y))
	var cells := []
	for i in steps + 1:
		cells.append(a + step * i)
	return cells


## Checks the cells picked (either way round). Returns the word found, or "".
func pick(cells: Array) -> String:
	if cells.size() < 2:
		return ""
	for p: Dictionary in placements:
		if p["word"] in found:
			continue
		var forward: Array = p["cells"]
		var backward := forward.duplicate()
		backward.reverse()
		if cells == forward or cells == backward:
			found.append(p["word"])
			return p["word"]
	return ""


func cells_of(word: String) -> Array:
	for p: Dictionary in placements:
		if p["word"] == word:
			return p["cells"]
	return []


func round_done() -> bool:
	return found.size() >= placements.size()


func is_last_round() -> bool:
	return round_index == ROUNDS.size() - 1


## Mid-round, with a word found: leaving now would lose it.
func has_progress() -> bool:
	return not found.is_empty() and not round_done()


func _try_fill() -> bool:
	grid = []
	for r in size:
		var row := []
		row.resize(size)
		row.fill("")
		grid.append(row)
	placements = []
	var longest_first := words().duplicate()
	longest_first.sort_custom(func(a: Array, b: Array) -> bool: return a[0].length() > b[0].length())
	for w: Array in longest_first:
		var cells := _place(w[0])
		if cells.is_empty():
			return false
		placements.append({"word": w[0], "label": w[1], "cells": cells})
	# Back into the round's order, so the word list reads like the prototype's.
	var order := words().map(func(w: Array) -> String: return w[0])
	placements.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return order.find(a["word"]) < order.find(b["word"]))
	for r in size:
		for c in size:
			if grid[r][c] == "":
				grid[r][c] = String.chr(65 + _rng.randi_range(0, 25))
	return true


func _place(word: String) -> Array:
	for attempt in 300:
		var dir: Vector2i = DIRS[_rng.randi_range(0, DIRS.size() - 1)]
		var start := Vector2i(_rng.randi_range(0, size - 1), _rng.randi_range(0, size - 1))
		var end := start + dir * (word.length() - 1)
		if end.x < 0 or end.x >= size or end.y < 0 or end.y >= size:
			continue
		var cells := []
		var ok := true
		for i in word.length():
			var cell := start + dir * i
			var there: String = grid[cell.x][cell.y]
			if there != "" and there != word[i]:
				ok = false
				break
			cells.append(cell)
		if not ok:
			continue
		for i in word.length():
			grid[cells[i].x][cells[i].y] = word[i]
		return cells
	return []
