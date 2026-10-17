extends TestCase
## The rest of the hub: Done badges, the rainbow promise, Settings, the Hall of the Ark,
## Start over, and For Parents & Teachers.

const MAIN_SCENE := "res://scenes/main.tscn"


func _open() -> Control:
	var main: Control = load(MAIN_SCENE).instantiate()
	tree.root.add_child(main)
	main.picker.pick("grownup")
	return main


func _close(main: Control) -> void:
	tree.root.remove_child(main)
	main.free()
	tree.root.content_scale_factor = 1.0
	AudioServer.set_bus_volume_db(0, 0.0)
	AudioServer.set_bus_mute(0, false)


func test_done_badges_show_finished_games() -> void:
	var main := _open()
	assert_false(main.game_badges["memory_match"].visible)
	main.open_game("memory_match")
	main.games["memory_match"].finished.emit()
	main.congrats.skip_button.pressed.emit()
	main.show_hub()
	assert_true(main.game_badges["memory_match"].visible, "Done after finishing")
	assert_false(main.game_badges["word_search"].visible)
	_close(main)


func test_the_promise_unlocks_after_the_rainbow() -> void:
	var main := _open()
	var grey: bool = (main.promise_art.material as ShaderMaterial).get_shader_parameter("grey")
	assert_true(grey, "grey until then")
	assert_eq(main.promise_label.text, "Finish Story Sequence to see the promise")
	main.finale.ended.emit()
	main.show_hub()
	grey = (main.promise_art.material as ShaderMaterial).get_shader_parameter("grey")
	assert_false(grey)
	assert_eq(main.promise_label.text, "The Promise: you saw the rainbow!")
	_close(main)
	assert_true(Settings.load_saved().rainbow_seen, "kept")


func test_settings_open_and_change_things() -> void:
	var main := _open()
	assert_false(main.settings_panel.visible, "closed to start")
	main.settings_button.pressed.emit()
	assert_true(main.settings_panel.visible)
	var panel: SettingsPanel = main.settings_panel
	panel.pick("text_size", "xlarge")
	assert_eq(Settings.current.text_size, "xlarge")
	assert_eq(main.text_size_button.text, "Aa  Extra large", "the Aa pill agrees")
	panel.pick("read_aloud", true)
	assert_true(Settings.current.read_aloud)
	panel.pick("voice_on", false)
	assert_false(Settings.current.voice_on)
	panel.pick("speech_rate", "normal")
	assert_eq(Settings.current.rate(), Settings.RATES["normal"])
	panel.volume_slider.value = 40
	assert_eq(Settings.current.volume, 0.4)
	assert_eq(panel.volume_readout.text, "40%")
	assert_eq(Settings.current.tts_volume(), 20)
	panel.pick("profile", "little")
	assert_eq(Settings.current.profile, "little")
	assert_eq(main.profile_button.text, "Who's playing: Little one")
	panel.test_button.pressed.emit()
	_close(main)
	var kept := Settings.load_saved()
	assert_eq(kept.volume, 0.4, "kept")
	assert_eq(kept.speech_rate, "normal")


## A finger sliding up from a card or button scrolls the page: nothing on the hub or in
## the Hall keeps its touches from the scroll box.
func test_everything_lets_the_page_scroll() -> void:
	var main := _open()
	await tree.process_frame
	var stoppers: Array = []
	var check := func(node: Node, again: Callable) -> void:
		if node is Control and (node as Control).mouse_filter == Control.MOUSE_FILTER_STOP:
			stoppers.append(node.get_path())
		for child in node.get_children():
			again.call(child, again)
	check.call(main.hub, check)
	check.call(main.hall, check)
	assert_eq(stoppers, [], "these keep a finger from scrolling")
	_close(main)


func test_hall_shows_what_has_been_found() -> void:
	var main := _open()
	assert_true(main.hall_button.text.contains("(0/4)"))
	main.hall_button.pressed.emit()
	assert_true(main.hall.visible)
	assert_eq(main.current_game, "hall")
	var hall: HallScreen = main.hall
	assert_eq((hall.word_chips.get_child(0) as Label).text, "???")
	hall.show_person("shem")
	assert_eq(hall.info_title.text, "Who could this be?")
	assert_eq(hall.info_text.text, "Find SHEM in the Word Search.")
	main.back_button.pressed.emit()
	assert_false(main.hall.visible)
	# Find a few things, then look again.
	Settings.current.find_word("NOAH")
	Settings.current.find_animal("lion")
	Settings.current.find_event("build")
	main.show_hub()
	assert_true(main.hall_button.text.contains("(1/4)"))
	main.open_hall()
	assert_eq((hall.word_chips.get_child(0) as Label).text, "Noah")
	assert_eq((hall.animal_chips.get_child(1) as Label).text, "Lion")
	assert_eq((hall.event_chips.get_child(0) as Label).text, "God tells Noah to build the ark")
	hall.show_person("noah")
	assert_eq(hall.info_title.text, "Noah")
	assert_true(hall.info_ref.visible)
	_close(main)


func test_finding_a_name_in_word_search_meets_them() -> void:
	var main := _open()
	main.words.complete_delay = 0.0
	main.open_game("word_search")
	var screen: WordSearchScreen = main.words
	var cells: Array = screen.game.cells_of("SHEM")
	screen.slide(cells[0], cells[-1])
	assert_true("SHEM" in Settings.current.words_found)
	assert_true("shem" in Settings.current.family_met)
	assert_true(main.toast.visible, "You met Shem!")
	_close(main)


func test_start_over_asks_then_forgets_everything() -> void:
	var main := _open()
	main.name_input.text = "Sam"
	main.name_input.text_changed.emit("Sam")
	Settings.current.complete("word_search")
	Settings.current.find_word("HAM")
	main.start_over_button.pressed.emit()
	assert_true(main.confirm.visible, "asks first")
	main.confirm_no.pressed.emit()
	assert_false(main.confirm.visible)
	assert_eq(Settings.current.player_name, "Sam", "nothing lost")
	main.start_over_button.pressed.emit()
	main.confirm_yes.pressed.emit()
	assert_eq(Settings.current.player_name, "")
	assert_true(Settings.current.completed.is_empty())
	assert_true(Settings.current.family_met.is_empty())
	assert_eq(main.name_input.text, "")
	assert_true(main.picker.visible, "who's playing, as on a first visit")
	_close(main)
	assert_false(Settings.load_saved().profile_chosen(), "gone from the phone too")


func test_parents_notes_open_and_close() -> void:
	var main := _open()
	assert_false(main.parents_notes.visible)
	main.parents_button.pressed.emit()
	assert_true(main.parents_notes.visible)
	assert_eq(main.parents_notes.get_child_count(), 3)
	main.parents_button.pressed.emit()
	assert_false(main.parents_notes.visible)
	_close(main)


func test_iphone_new_parts_fit_and_are_easy_to_tap() -> void:
	var window := tree.root
	var old_size := window.size
	window.size = Vector2i(1320, 2868)
	var main := _open()
	main.safe_insets_override = Vector4(0, 150, 0, 80)
	main.relayout()
	main.settings_button.pressed.emit()
	await tree.process_frame
	await tree.process_frame
	var width: float = main.get_viewport_rect().size.x
	var panel: SettingsPanel = main.settings_panel
	var controls: Array = [main.settings_button, main.hall_button, main.start_over_button, main.parents_button,
		panel.volume_slider, panel.test_button]
	for setting: String in panel.choices:
		controls.append_array(panel.choices[setting].values())
	for control: Control in controls:
		var r := control.get_global_rect()
		assert_true(r.size.y >= 90.0, "tall enough to tap (%s)" % str(r))
		assert_true(r.position.x >= 0.0 and r.end.x <= width + 0.5, "on screen (%s)" % str(r))
	main.open_hall()
	await tree.process_frame
	await tree.process_frame
	for tile: Button in main.hall.tiles.values():
		var r := tile.get_global_rect()
		assert_true(r.end.x <= width + 0.5 and r.size.y >= 200.0, "face tile fits (%s)" % str(r))
	_close(main)
	window.size = old_size
