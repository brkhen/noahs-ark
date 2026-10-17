extends TestCase
## Memory Match: the rules on their own, then the screen played through with taps.

const MAIN_SCENE := "res://scenes/main.tscn"


func _open_memory() -> Control:
	var main: Control = load(MAIN_SCENE).instantiate()
	tree.root.add_child(main)
	main.memory.complete_delay = 0.0
	main.memory.get_ready_seconds = 0.0
	main.memory.miss_seconds = 0.0
	main.open_game("memory_match")
	return main


func _close(main: Control) -> void:
	tree.root.remove_child(main)
	main.free()


func _play_round(screen: MemoryMatchScreen) -> void:
	for animal: String in MemoryMatch.ANIMALS.slice(0, screen.game.pairs()):
		for i: int in screen.cards_of(animal):
			screen.tap_card(i)


func test_rounds_grow_and_every_animal_has_a_picture() -> void:
	var game := MemoryMatch.new()
	for r in 3:
		game.start(r)
		assert_eq(game.deck.size(), MemoryMatch.PAIRS[r] * 2)
		for animal: String in game.deck:
			assert_eq(game.deck.count(animal), 2, "%s comes in a pair" % animal)
			assert_true(MemoryMatchScreen.ART.has(animal), "picture for %s" % animal)
	assert_eq(MemoryMatch.PAIRS, [4, 5, 6])


func test_rules_pairs_stay_up_misses_turn_back() -> void:
	var game := MemoryMatch.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	game.start(0, rng)
	var lions := []
	var doves := []
	for i in game.deck.size():
		if game.deck[i] == "lion":
			lions.append(i)
		elif game.deck[i] == "dove":
			doves.append(i)
	assert_eq(game.flip(lions[0]), "first")
	assert_eq(game.flip(lions[0]), "ignored", "same card twice")
	assert_eq(game.flip(doves[0]), "miss")
	assert_eq(game.flip(lions[1]), "ignored", "wait for the miss to turn back")
	assert_eq(game.settle(), [lions[0], doves[0]])
	assert_false(game.is_face_up(lions[0]))
	assert_eq(game.flip(lions[0]), "first")
	assert_eq(game.flip(lions[1]), "match")
	assert_true(game.is_face_up(lions[0]) and game.is_face_up(lions[1]))
	assert_eq(game.flip(lions[1]), "ignored", "a found pair stays put")
	assert_true(game.has_progress())
	assert_eq(game.matches, 1)


func test_card_opens_the_game() -> void:
	var main := _open_memory()
	var screen: MemoryMatchScreen = main.memory
	assert_true(screen.visible, "Memory Match screen shows")
	assert_false(main.placeholder.visible, "no 'on its way' page")
	assert_false(main.story.visible)
	assert_eq(screen.round_label.text, "Round 1 of 3")
	assert_eq(screen.cards.size(), 8)
	for card in screen.cards:
		assert_true(card.get_node("Back").visible and not card.get_node("Front").visible, "cards start face down")
	_close(main)


func test_match_and_miss_on_screen() -> void:
	var main := _open_memory()
	var screen: MemoryMatchScreen = main.memory
	var doves := screen.cards_of("dove")
	var lions := screen.cards_of("lion")
	screen.tap_card(doves[0])
	assert_true(screen.cards[doves[0]].get_node("Front").visible, "turned over")
	screen.tap_card(lions[0])
	assert_false(screen.cards[doves[0]].get_node("Front").visible, "a miss turns back over")
	assert_false(screen.cards[lions[0]].get_node("Front").visible)
	screen.tap_card(doves[0])
	screen.tap_card(doves[1])
	assert_true(screen.cards[doves[0]].get_node("Front").visible and screen.cards[doves[1]].get_node("Front").visible, "a pair stays up")
	assert_true(screen.cards[doves[0]].disabled)
	assert_true(screen.noah_words.text in StoryGameScreen.PRAISE, "Noah cheers the first pair")
	_close(main)


func test_play_all_three_rounds_then_the_animals_board() -> void:
	var main := _open_memory()
	var screen: MemoryMatchScreen = main.memory
	for r in 3:
		assert_eq(screen.game.round_index, r)
		assert_eq(screen.cards.size(), MemoryMatch.PAIRS[r] * 2)
		_play_round(screen)
		assert_true(screen.overlay.visible, "round %d complete card" % (r + 1))
		assert_eq(screen.overlay_title.text, "All Rounds Complete!" if r == 2 else "Round Complete!")
		screen.overlay_button.pressed.emit()
	assert_true(main.congrats.visible, "Noah says well done first")
	assert_true(main.congrats.skip_button.visible, "and asks a new player their name")
	main.congrats.skip_button.pressed.emit()
	assert_true(main.stampede.visible, "the animals' scene follows the last round")
	assert_false(screen.visible)
	assert_false(main.finale.visible, "not the rainbow scene")
	main.back_button.pressed.emit()
	assert_eq(main.current_game, "", "Back leaves the scene")
	assert_false(main.stampede.visible)
	_close(main)


func test_back_mid_round_asks_first() -> void:
	var main := _open_memory()
	var screen: MemoryMatchScreen = main.memory
	for i: int in screen.cards_of("dove"):
		screen.tap_card(i)
	main.back_button.pressed.emit()
	assert_eq(main.current_game, "memory_match", "still playing")
	assert_eq(screen.overlay_title.text, "Leave this round?")
	screen.overlay_button.pressed.emit()
	assert_eq(main.current_game, "", "Leave goes to the hub")
	_close(main)


## On the iPhone shape, the biggest round's cards are big, square, and above the home bar.
func test_iphone_round_three_fits() -> void:
	var window := tree.root
	var old_size := window.size
	window.size = Vector2i(1320, 2868)
	var main := _open_memory()
	var insets := Vector4(0, 150, 0, 80)
	main.safe_insets_override = insets
	main.relayout()
	var screen: MemoryMatchScreen = main.memory
	screen._start_round(2)
	await tree.process_frame
	await tree.process_frame
	var bottom := main.get_viewport_rect().size.y - insets.w
	for card in screen.cards:
		var r := card.get_global_rect()
		assert_true(r.size.x >= 180.0, "card big enough (%s)" % str(r))
		assert_true(absf(r.size.x - r.size.y) < 2.0, "card is square (%s)" % str(r))
		assert_true(r.end.y <= bottom, "card above the home bar (%s)" % str(r))
	_close(main)
	window.size = old_size
