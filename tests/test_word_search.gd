extends TestCase
## Word Search: the rules on their own, then the screen played through with taps and slides.

const MAIN_SCENE := "res://scenes/main.tscn"


func _open_words() -> Control:
	var main: Control = load(MAIN_SCENE).instantiate()
	tree.root.add_child(main)
	main.words.complete_delay = 0.0
	main.words.get_ready_seconds = 0.0
	main.open_game("word_search")
	return main


func _close(main: Control) -> void:
	tree.root.remove_child(main)
	main.free()


func _ends(game: WordSearch, word: String) -> Array:
	var cells := game.cells_of(word)
	return [cells[0], cells[cells.size() - 1]]


func _play_round(screen: WordSearchScreen) -> void:
	for p: Dictionary in screen.game.placements:
		var ends := _ends(screen.game, p["word"])
		screen.tap_cell(ends[0])
		screen.tap_cell(ends[1])


func test_every_word_is_hidden_in_every_round() -> void:
	var game := WordSearch.new()
	for r in 3:
		for attempt in 20:
			game.start(r)
			assert_eq(game.grid.size(), [7, 8, 9][r])
			assert_eq(game.placements.size(), 6, "all six words fit")
			for p: Dictionary in game.placements:
				var spelled := ""
				for cell: Vector2i in p["cells"]:
					spelled += game.grid[cell.x][cell.y]
				assert_eq(spelled, p["word"])
				assert_false(WordSearch.line_between(p["cells"][0], p["cells"][-1]).is_empty(), "in a straight line")


func test_rules_pick_a_word_either_way() -> void:
	var game := WordSearch.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	game.start(0, rng)
	var noah := game.cells_of("NOAH")
	assert_eq(game.pick(noah.slice(0, 3)), "", "part of a word")
	var backward := noah.duplicate()
	backward.reverse()
	assert_eq(game.pick(backward), "NOAH", "end to start counts too")
	assert_eq(game.pick(noah), "", "already found")
	assert_true(game.has_progress())
	assert_eq(WordSearch.line_between(Vector2i(0, 0), Vector2i(2, 1)), [], "not a straight line")
	assert_eq(WordSearch.line_between(Vector2i(2, 2), Vector2i(0, 0)), [Vector2i(2, 2), Vector2i(1, 1), Vector2i(0, 0)])


func test_card_opens_the_game() -> void:
	var main := _open_words()
	var screen: WordSearchScreen = main.words
	assert_true(screen.visible, "Word Search screen shows")
	assert_false(main.placeholder.visible, "no 'on its way' page")
	assert_eq(screen.round_label.text, "Round 1 of 3")
	assert_eq(screen.cells.size(), 7)
	assert_eq(screen.chips.size(), 6)
	_close(main)


func test_two_taps_slide_and_misses() -> void:
	var main := _open_words()
	var screen: WordSearchScreen = main.words
	var ends := _ends(screen.game, "DOVE")
	screen.tap_cell(ends[0])
	assert_eq(screen.anchor, ends[0], "first letter waits for the last")
	screen.tap_cell(ends[0])
	assert_eq(screen.anchor, Vector2i(-1, -1), "tapping it again lets go")
	screen.tap_cell(ends[0])
	screen.tap_cell(ends[1])
	assert_true("DOVE" in screen.game.found, "first and last letter find it")
	assert_true(screen.noah_words.text in StoryGameScreen.PRAISE, "Noah cheers the first word")
	var ark := _ends(screen.game, "ARK")
	screen.slide(ark[1], ark[0])
	assert_true("ARK" in screen.game.found, "a slide finds it, either way")
	var noah := screen.game.cells_of("NOAH")
	screen.slide(noah[0], noah[2])
	assert_false("NOAH" in screen.game.found, "half a word isn't it")
	_close(main)


func test_play_all_three_rounds_then_the_ark_is_built() -> void:
	var main := _open_words()
	var screen: WordSearchScreen = main.words
	for r in 3:
		assert_eq(screen.game.round_index, r)
		_play_round(screen)
		assert_true(screen.overlay.visible, "round %d complete card" % (r + 1))
		assert_eq(screen.overlay_title.text, "All Words Found!" if r == 2 else "Round Complete!")
		screen.overlay_button.pressed.emit()
	assert_true(main.building.visible, "the building scene follows the last round")
	assert_false(screen.visible)
	main.back_button.pressed.emit()
	assert_eq(main.current_game, "", "Back leaves the scene")
	_close(main)


func test_back_mid_round_asks_first() -> void:
	var main := _open_words()
	var screen: WordSearchScreen = main.words
	var ends := _ends(screen.game, "HAM")
	screen.tap_cell(ends[0])
	screen.tap_cell(ends[1])
	main.back_button.pressed.emit()
	assert_eq(main.current_game, "word_search", "still playing")
	assert_eq(screen.overlay_title.text, "Leave this round?")
	screen.overlay_button.pressed.emit()
	assert_eq(main.current_game, "", "Leave goes to the hub")
	_close(main)


## On the iPhone shape, round 3's letters are big, square, and the board fits the width.
func test_iphone_round_three_fits() -> void:
	var window := tree.root
	var old_size := window.size
	window.size = Vector2i(1320, 2868)
	var main := _open_words()
	main.safe_insets_override = Vector4(0, 150, 0, 80)
	main.relayout()
	var screen: WordSearchScreen = main.words
	screen._start_round(2)
	await tree.process_frame
	await tree.process_frame
	for row: Array in screen.cells:
		for cell: Panel in row:
			var r := cell.get_global_rect()
			assert_true(r.size.x >= 85.0, "letter big enough to tap (%s)" % str(r))
			assert_true(absf(r.size.x - r.size.y) < 2.0, "letter is square (%s)" % str(r))
			assert_true(r.end.x <= 1320.0, "on screen (%s)" % str(r))
	var last: Panel = screen.cells[8][8]
	assert_eq(screen._cell_at(last.get_global_rect().get_center() - screen.board.global_position), Vector2i(8, 8), "a tap finds its letter")
	_close(main)
	window.size = old_size
