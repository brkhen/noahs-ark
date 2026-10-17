extends TestCase
## Noah's voice and congratulations: tap Noah to hear him, his "Great job!" after a game,
## and the Noah's voice button.

const MAIN_SCENE := "res://scenes/main.tscn"


func _open() -> Control:
	var main: Control = load(MAIN_SCENE).instantiate()
	tree.root.add_child(main)
	main.picker.pick("together")
	main.congrats.reply_seconds = 0.0
	return main


func _close(main: Control) -> void:
	tree.root.remove_child(main)
	main.free()
	tree.root.content_scale_factor = 1.0


## As if the last round's button was tapped.
func _finish(main: Control, id: String) -> void:
	main.open_game(id)
	main.games[id].finished.emit()


func test_tap_noah_on_the_hub() -> void:
	var main := _open()
	assert_true(main.noah_button.visible)
	main.noah_button.pressed.emit()
	assert_eq(main.noah_says.text, Settings.current.greeting(), "he says what's in his bubble")
	_close(main)


func test_noahs_voice_button_turns_him_off_and_on() -> void:
	var main := _open()
	assert_true(Settings.current.voice_on, "on to start")
	assert_eq(main.voice_button.text, "Noah's voice: On")
	main.voice_button.pressed.emit()
	assert_false(Settings.current.voice_on)
	assert_eq(main.voice_button.text, "Noah's voice: Off")
	assert_eq(NoahVoice.say("Hello"), 0.0, "quiet when off")
	_close(main)
	assert_false(Settings.load_saved().voice_on, "kept")


func test_a_new_player_is_asked_their_name_after_a_game() -> void:
	var main := _open()
	_finish(main, "word_search")
	assert_true(main.congrats.visible)
	assert_eq(main.congrats.words.text, "Great job! Would you like to tell me your name?")
	assert_false(main.congrats.go_button.visible)
	main.congrats.name_input.text = "  Sam "
	main.congrats.save_button.pressed.emit()
	assert_eq(Settings.current.player_name, "Sam")
	assert_eq(main.name_input.text, "Sam", "the hub's box has it too")
	assert_false(main.congrats.visible)
	assert_true(main.building.visible, "then the scene")
	assert_true("word_search" in Settings.current.completed)
	_close(main)


func test_a_named_player_hears_great_job() -> void:
	var main := _open()
	main.name_input.text = "Sam"
	main.name_input.text_changed.emit("Sam")
	main.co_name_input.text = "Grandpa"
	main.co_name_input.text_changed.emit("Grandpa")
	_finish(main, "memory_match")
	assert_eq(main.congrats.words.text, "Great job, Sam and Grandpa!")
	assert_false(main.congrats.ask.visible, "not asked again")
	assert_eq(main.congrats.go_button.text, "See them run!")
	main.congrats.go_button.pressed.emit()
	assert_true(main.stampede.visible)
	_close(main)


func test_finishing_every_story_changes_noahs_welcome() -> void:
	var main := _open()
	for id: String in Settings.GAMES:
		_finish(main, id)
		main.congrats.skip_button.pressed.emit()
		main.show_hub()
	assert_eq(main.noah_says.text, "You finished the whole story! Well done!")
	_close(main)
	main = _open()
	assert_true(Settings.current.finished_all(), "kept")
	_close(main)


func test_noah_wiggles_when_he_cheers() -> void:
	var main := _open()
	main.open_game("word_search")
	var screen: WordSearchScreen = main.words
	screen._cheer(1)
	assert_true(screen.noah_portrait.has_meta("noah_tween"), "his portrait moves")
	_close(main)


func test_iphone_congrats_fits_above_the_keyboard() -> void:
	var window := tree.root
	var old_size := window.size
	window.size = Vector2i(1320, 2868)
	var main := _open()
	main.safe_insets_override = Vector4(0, 150, 0, 80)
	main.relayout()
	await tree.process_frame
	await tree.process_frame
	assert_true(main.noah_button.size.y >= 170.0, "Noah's welcome keeps its size as a button (%s)" % str(main.noah_button.size))
	_finish(main, "story_sequence")
	await tree.process_frame
	await tree.process_frame
	var screen := main.get_viewport_rect()
	assert_true(screen.encloses(main.congrats.card.get_global_rect()), "card on screen")
	var box: Rect2 = main.congrats.name_input.get_global_rect()
	assert_true(box.end.y < screen.size.y * 0.55, "name box clear of the keyboard (%s)" % str(box))
	for control: Control in [main.congrats.name_input, main.congrats.save_button, main.congrats.skip_button]:
		var r := control.get_global_rect()
		assert_true(r.size.y >= 110.0, "tall enough to tap (%s)" % str(r))
		assert_true(screen.encloses(r), "on screen (%s)" % str(r))
	_close(main)
	window.size = old_size
