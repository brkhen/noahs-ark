class_name WordSearchScreen
extends StoryGameScreen
## Word Search, laid out like the web prototype's (docs/prototype/): a square of letters as
## wide as the panel, the words to find below it, and a button that reads them aloud. Tap a
## word's first letter and then its last, or slide a finger across it. A found word turns
## gold and Noah says it. Three rounds (7, 8, then 9 letters across). No timer.

const HINT := "Tap the first letter, then the last letter of a word, or slide your finger across it."
const GAP := 6 ## between letters
const CELL := Color("#FFFCF4")
const SELECTING := Color("#F7C45E")
const CORAL := Color("#E8735C")
const FOUND_CHIP := Color("#DCEFDD")
const FOUND_INK := Color("#3E7A47")

var game := WordSearch.new()
var cells: Array = [] ## cells[row][col], each a Panel holding its letter
var chips: Dictionary = {} ## word -> its chip in the list
var board: Control ## the letters; takes the taps and slides
var letters: GridContainer
var word_list: HFlowContainer
var hear_button: Button
var anchor := Vector2i(-1, -1) ## the first letter of a two-tap pick, or (-1, -1)
var _press := Vector2i(-1, -1) ## where the finger went down
var _path: Array = [] ## the cells under the finger's line now


func _ready() -> void:
	super()
	resized.connect(_fit)


func has_progress() -> bool:
	return game.has_progress()


## Taps a letter, as a finger would. For tests.
func tap_cell(cell: Vector2i) -> void:
	_down(cell)
	_up()


## Slides a finger from one letter to another. For tests.
func slide(from: Vector2i, to: Vector2i) -> void:
	_down(from)
	_drag(to)
	_up()


func _round_count() -> int:
	return WordSearch.ROUNDS.size()


func _round_index() -> int:
	return game.round_index


func _start_round(index: int) -> void:
	game.start(index)
	_begin_round_ui()
	anchor = Vector2i(-1, -1)
	_press = Vector2i(-1, -1)
	_path = []
	for child in letters.get_children():
		letters.remove_child(child)
		child.queue_free()
	letters.columns = game.size
	cells = []
	for r in game.size:
		var row := []
		for c in game.size:
			var cell := Panel.new()
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var letter := _label(game.grid[r][c], 60, INK, PROMPT_FONT)
			letter.name = "Letter"
			letter.set_anchors_preset(Control.PRESET_FULL_RECT)
			letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(letter)
			letters.add_child(cell)
			row.append(cell)
		cells.append(row)
	for child in word_list.get_children():
		word_list.remove_child(child)
		child.queue_free()
	chips.clear()
	for p: Dictionary in game.placements:
		var chip := _chip(p["label"])
		word_list.add_child(chip)
		chips[p["word"]] = chip
	_paint()
	_fit()


func _show_round_complete() -> void:
	if game.is_last_round():
		_show_overlay("All Words Found!", "You uncovered every word from the story. Now let's build the ark!", "See them build!", "finish")
	else:
		_show_overlay("Round Complete!", "Nicely spotted! A bigger grid is next.", "Continue", "continue")


func _hear_words() -> void:
	_stop_speaking()
	for p: Dictionary in game.placements:
		if not p["word"] in game.found:
			_speak(p["label"], false)


## The finger went down on a letter.
func _down(cell: Vector2i) -> void:
	if overlay.visible or game.round_done():
		return
	_press = cell
	_path = [cell]
	_paint()


## The finger slid onto another letter: the line follows it while it stays straight.
func _drag(cell: Vector2i) -> void:
	if _press.x < 0:
		return
	var line := WordSearch.line_between(_press, cell)
	if not line.is_empty() and line != _path:
		_path = line
		_paint()


## The finger lifted: a slide checks its line; a tap is a first or last letter.
func _up() -> void:
	if _press.x < 0:
		return
	var pressed := _press
	_press = Vector2i(-1, -1)
	if _path.size() > 1:
		anchor = Vector2i(-1, -1)
		_check(_path)
		return
	_path = []
	if anchor.x < 0:
		anchor = pressed # first letter
	elif anchor == pressed:
		anchor = Vector2i(-1, -1) # tapping it again lets go
	else:
		var line := WordSearch.line_between(anchor, pressed)
		if line.is_empty():
			anchor = pressed # not in a straight line: start again from here
		else:
			anchor = Vector2i(-1, -1)
			_check(line)
			return
	_paint()


func _check(line: Array) -> void:
	_path = []
	var word := game.pick(line)
	_paint()
	if word == "":
		_chime(false)
		return
	_chime(true)
	_speak(game.label_of(word))
	_mark_found(chips[word])
	if game.round_done():
		_say("")
		_after(complete_delay, _show_round_complete)
	else:
		_cheer(game.found.size())


## Colors every letter: found words gold, the line being picked yellow, the first letter of
## a two-tap pick gold with a white ring.
func _paint() -> void:
	var gold_cells := {}
	for word: String in game.found:
		for cell: Vector2i in game.cells_of(word):
			gold_cells[cell] = true
	for r in cells.size():
		for c in cells[r].size():
			var at := Vector2i(r, c)
			var fill := CELL
			var ink := INK
			var ring := 0
			var ring_color := CORAL
			if at in _path:
				fill = SELECTING
				ring = 6
			elif at == anchor:
				fill = GOLD
				ink = Color.WHITE
				ring = 6
				ring_color = Color.WHITE
			elif gold_cells.has(at):
				fill = GOLD
				ink = CREAM
			var box := _box(fill, 20, ring, ring_color, 0)
			box.shadow_color = Color(0.42, 0.27, 0.16, 0.22)
			box.shadow_size = 2
			box.shadow_offset = Vector2(0, 4)
			var cell: Panel = cells[r][c]
			cell.add_theme_stylebox_override("panel", box)
			(cell.get_node("Letter") as Label).add_theme_color_override("font_color", ink)


func _on_board_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var cell := _cell_at(event.position)
			if cell.x >= 0:
				_down(cell)
		else:
			_up()
		board.accept_event()
	elif event is InputEventMouseMotion and _press.x >= 0:
		var cell := _cell_at(event.position)
		if cell.x >= 0:
			_drag(cell)
		board.accept_event()


## The letter under a point on the board, or (-1, -1).
func _cell_at(point: Vector2) -> Vector2i:
	if cells.is_empty():
		return Vector2i(-1, -1)
	var pitch: float = (cells[0][0] as Panel).size.x + GAP
	var c := int(point.x / pitch)
	var r := int(point.y / pitch)
	if r < 0 or c < 0 or r >= game.size or c >= game.size:
		return Vector2i(-1, -1)
	return Vector2i(r, c)


## The letters, the words to find, the hint, and Hear the words.
func _build_body(body: VBoxContainer) -> void:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _box(Color("#D9C49A"), 30, 0, GOLD, 10))
	body.add_child(frame)
	board = Control.new()
	board.mouse_filter = Control.MOUSE_FILTER_STOP
	board.gui_input.connect(_on_board_input)
	frame.add_child(board)
	letters = GridContainer.new()
	letters.add_theme_constant_override("h_separation", GAP)
	letters.add_theme_constant_override("v_separation", GAP)
	letters.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(letters)
	board.resized.connect(_fit)
	word_list = HFlowContainer.new()
	word_list.alignment = FlowContainer.ALIGNMENT_CENTER
	word_list.add_theme_constant_override("h_separation", 18)
	word_list.add_theme_constant_override("v_separation", 18)
	body.add_child(word_list)
	body.add_child(_label(HINT, 38, ARK_DARK, BODY_FONT))
	hear_button = _soft_button("Hear the words")
	hear_button.pressed.connect(_hear_words)
	body.add_child(hear_button)


func _chip(text: String) -> Label:
	var chip := _label(text, WORDS_SIZE, ARK_DARK, BOLD_FONT)
	chip.autowrap_mode = TextServer.AUTOWRAP_OFF
	var box := _box(CREAM, 40, 0, CARD_EDGE, 0)
	box.content_margin_left = 34
	box.content_margin_right = 34
	box.content_margin_top = 12
	box.content_margin_bottom = 14
	box.shadow_color = Color(0.42, 0.27, 0.16, 0.14)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, 3)
	chip.add_theme_stylebox_override("normal", box)
	return chip


## A found word in the list: green, faded, and crossed out.
func _mark_found(chip: Label) -> void:
	var box := (chip.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
	box.bg_color = FOUND_CHIP
	chip.add_theme_stylebox_override("normal", box)
	chip.add_theme_color_override("font_color", FOUND_INK)
	chip.modulate.a = 0.6
	var strike := ColorRect.new()
	strike.color = FOUND_INK
	strike.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strike.anchor_left = 0.0
	strike.anchor_right = 1.0
	strike.anchor_top = 0.5
	strike.anchor_bottom = 0.5
	strike.offset_left = 26
	strike.offset_right = -26
	strike.offset_top = -2
	strike.offset_bottom = 3
	chip.add_child(strike)


## Square letters filling the panel's width; the letter size follows the square.
func _fit() -> void:
	if board == null or cells.is_empty():
		return
	var width := board.size.x
	if width <= 0.0:
		return # not laid out yet; resized calls this again
	var side := floorf((width - GAP * (game.size - 1)) / game.size)
	for row: Array in cells:
		for cell: Panel in row:
			cell.custom_minimum_size = Vector2(side, side)
			(cell.get_node("Letter") as Label).add_theme_font_size_override("font_size", int(side * 0.56))
	board.custom_minimum_size.y = side * game.size + GAP * (game.size - 1)
