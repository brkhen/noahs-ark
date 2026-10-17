extends TestCase
## Story Sequence: the rules on their own, then the screen played through with taps.

const MAIN_SCENE := "res://scenes/main.tscn"


func _open_story() -> Control:
	var main: Control = load(MAIN_SCENE).instantiate()
	tree.root.add_child(main)
	main.story.complete_delay = 0.0
	main.story.get_ready_seconds = 0.0
	main.open_game("story_sequence")
	return main


func _close(main: Control) -> void:
	tree.root.remove_child(main)
	main.free()


func _play_round(story: StorySequenceScreen) -> void:
	for event: Dictionary in story.game.events():
		story.tap_card(event["id"])


func test_rounds_get_longer_and_every_event_has_a_picture() -> void:
	var sizes := []
	for round: Array in StorySequence.ROUNDS:
		sizes.append(round.size())
		var ids := {}
		for event: Dictionary in round:
			assert_true(StorySequenceScreen.ART.has(event["art"]), "picture for %s" % event["id"])
			assert_false(ids.has(event["id"]), "%s only once in its round" % event["id"])
			ids[event["id"]] = true
	assert_eq(sizes, [4, 5, 6])


func test_rules_take_events_in_order_only() -> void:
	var game := StorySequence.new()
	game.start()
	assert_false(game.tap("rain1"), "rain is not first")
	assert_eq(game.placed, 0)
	assert_true(game.tap("build"))
	assert_true(game.has_progress())
	assert_false(game.tap("build"), "already placed")
	for id: String in ["board1", "rain1", "land1"]:
		assert_true(game.tap(id))
	assert_true(game.round_done())
	assert_false(game.has_progress(), "a finished round has nothing to lose")
	assert_false(game.is_last_round())
	game.next_round()
	assert_eq(game.round_index, 1)
	assert_eq(game.placed, 0)


func test_shuffle_keeps_every_event() -> void:
	var game := StorySequence.new()
	game.start(2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ids := game.shuffled_events(rng).map(func(e: Dictionary) -> String: return e["id"])
	ids.sort()
	var expected := game.events().map(func(e: Dictionary) -> String: return e["id"])
	expected.sort()
	assert_eq(ids, expected)


func test_card_opens_the_game() -> void:
	var main := _open_story()
	var story: StorySequenceScreen = main.story
	assert_true(story.visible, "Story Sequence screen shows")
	assert_false(main.placeholder.visible, "no 'on its way' page")
	assert_eq(story.round_label.text, "Round 1 of 3")
	assert_eq(story.cards.size(), 4)
	assert_eq(story.slots.size(), 4)
	main.show_hub()
	main.open_game("word_search")
	assert_false(story.visible, "other games still show their page")
	assert_true(main.placeholder.visible)
	_close(main)


func test_right_tap_fills_slot_wrong_tap_says_think_again() -> void:
	var main := _open_story()
	var story: StorySequenceScreen = main.story
	story.tap_card("rain1")
	assert_eq(story.game.placed, 0)
	assert_eq(story.noah_words.text, StorySequenceScreen.OOPS)
	assert_false((story.cards["rain1"] as Button).disabled, "a wrong card stays to try later")
	story.tap_card("build")
	assert_eq(story.game.placed, 1)
	assert_true((story.cards["build"] as Button).disabled, "placed card is used up")
	assert_eq(story.slots[0].get_child_count(), 1, "first slot shows the picture")
	assert_eq(story.slots[1].get_child_count(), 0)
	assert_true(story.noah_words.text in StorySequenceScreen.PRAISE, "Noah cheers the first one")
	_close(main)


func test_play_all_three_rounds_then_back_to_hub() -> void:
	var main := _open_story()
	var story: StorySequenceScreen = main.story
	for r in 3:
		assert_eq(story.game.round_index, r)
		assert_eq(story.cards.size(), StorySequence.ROUNDS[r].size())
		_play_round(story)
		assert_true(story.overlay.visible, "round %d complete card" % (r + 1))
		var last := r == 2
		assert_eq(story.overlay_title.text, "The Whole Story!" if last else "Round Complete!")
		story.overlay_button.pressed.emit()
	assert_true(main.finale.visible, "the rainbow scene follows the last round")
	assert_false(story.visible)
	assert_eq(main.finale.caption.text, RainbowFinale.STORY[0]["text"])
	main.finale.back_button.pressed.emit()
	assert_eq(main.current_game, "", "Back to Hub from the rainbow scene")
	assert_true(main.hub_scroll.visible)
	assert_false(main.finale.visible)
	_close(main)


func test_rainbow_scene_tells_the_story_in_order() -> void:
	var main := _open_story()
	main.show_finale()
	var finale: RainbowFinale = main.finale
	var last := -1.0
	for i in RainbowFinale.STORY.size():
		var part: Dictionary = RainbowFinale.STORY[i]
		assert_true(part["at"] > last, "parts in order")
		last = part["at"]
		finale.show_at(part["at"] + 0.1)
		assert_eq(finale.caption.text, part["text"])
		assert_true((finale.verse.text as String).begins_with("Genesis"), "verse for part %d" % i)
	assert_true(RainbowFinale.STORY[-1]["at"] < finale.video.get_stream_length() or finale.video.get_stream_length() == 0.0,
			"the last part starts before the video ends")
	main.back_button.pressed.emit()
	assert_eq(main.current_game, "", "Back leaves the scene too")
	_close(main)


func test_back_mid_round_asks_first() -> void:
	var main := _open_story()
	var story: StorySequenceScreen = main.story
	story.tap_card("build")
	main.back_button.pressed.emit()
	assert_eq(main.current_game, "story_sequence", "still playing")
	assert_true(story.overlay.visible, "asks before leaving")
	assert_eq(story.overlay_title.text, "Leave this round?")
	story.overlay_cancel.pressed.emit()
	assert_false(story.overlay.visible)
	assert_eq(story.game.placed, 1, "keep playing keeps the progress")
	main.back_button.pressed.emit()
	story.overlay_button.pressed.emit()
	assert_eq(main.current_game, "", "Leave goes to the hub")
	main.open_game("story_sequence")
	assert_eq(story.game.placed, 0, "coming back starts fresh")
	assert_eq(story.game.round_index, 0)
	_close(main)


## On the iPhone shape, every card and slot is a big target and round 3 fits without
## running under the home bar.
func test_iphone_round_three_fits() -> void:
	var window := tree.root
	var old_size := window.size
	window.size = Vector2i(1320, 2868)
	var main := _open_story()
	var insets := Vector4(0, 150, 0, 80)
	main.safe_insets_override = insets
	main.relayout()
	var story: StorySequenceScreen = main.story
	story.game.start(2)
	story._start_round(2)
	await tree.process_frame
	await tree.process_frame
	var screen := main.get_viewport_rect().size
	var bottom := screen.y - insets.w
	for id: String in story.cards:
		var r := (story.cards[id] as Button).get_global_rect()
		assert_true(r.size.y >= 120.0 and r.size.x >= 120.0, "%s card big enough (%s)" % [id, str(r)])
		assert_true(r.end.y <= bottom, "%s card above the home bar (%s)" % [id, str(r)])
	for slot in story.slots:
		assert_true(slot.size.x >= 100.0, "slot big enough to see (%s)" % str(slot.size))
	_close(main)
	window.size = old_size
