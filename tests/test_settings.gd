extends TestCase
## "Who's playing today?" and the settings kept on the phone: names, text size, reading aloud.

const MAIN_SCENE := "res://scenes/main.tscn"


func _open() -> Control:
	var main: Control = load(MAIN_SCENE).instantiate()
	tree.root.add_child(main)
	return main


func _close(main: Control) -> void:
	tree.root.remove_child(main)
	main.free()
	tree.root.content_scale_factor = 1.0


func test_a_new_player_is_asked_who_is_playing() -> void:
	var main := _open()
	assert_true(main.picker.visible, "the picker shows first")
	main.picker.pick("little")
	assert_false(main.picker.visible)
	assert_eq(Settings.current.profile, "little")
	assert_true(Settings.current.read_aloud, "a little one is read to")
	assert_eq(main.profile_button.text, "Who's playing: Little one")
	_close(main)
	main = _open()
	assert_false(main.picker.visible, "not asked again next time")
	assert_eq(Settings.current.profile, "little", "remembered")
	_close(main)


func test_grown_up_reads_only_when_asked_and_can_turn_it_on() -> void:
	var main := _open()
	main.picker.pick("grownup")
	assert_false(Settings.current.read_aloud)
	assert_eq(main.read_aloud_button.text, "Read to me: Off")
	main.read_aloud_button.pressed.emit()
	assert_true(Settings.current.read_aloud)
	assert_eq(main.read_aloud_button.text, "Read to me: On")
	_close(main)
	assert_true(Settings.load_saved().read_aloud, "kept")


func test_aa_goes_round_the_text_sizes_and_scales_the_screen() -> void:
	var main := _open()
	main.picker.pick("grownup")
	assert_eq(main.text_size_button.text, "Aa  Large")
	assert_eq(tree.root.content_scale_factor, 1.0)
	main.text_size_button.pressed.emit()
	assert_eq(main.text_size_button.text, "Aa  Extra large")
	assert_true(tree.root.content_scale_factor > 1.1, "everything drawn bigger")
	main.text_size_button.pressed.emit()
	assert_eq(main.text_size_button.text, "Aa  Normal")
	assert_true(tree.root.content_scale_factor < 1.0)
	_close(main)
	assert_eq(Settings.load_saved().text_size, "normal", "kept")


func test_names_go_into_noahs_welcome_and_are_kept() -> void:
	var main := _open()
	main.picker.pick("together")
	assert_eq(main.noah_says.text, "Welcome, friend! Tell me your name, then pick a game.")
	main.name_input.text = "Sam"
	main.name_input.text_changed.emit("Sam")
	assert_eq(main.noah_says.text, "Welcome, Sam! Pick a game, and let's help the animals reach the ark.")
	main.co_name_input.text = "Grandpa"
	main.co_name_input.text_changed.emit("Grandpa")
	assert_true(main.noah_says.text.begins_with("Welcome, Sam and Grandpa!"))
	_close(main)
	main = _open()
	assert_eq(main.name_input.text, "Sam", "name kept for next time")
	assert_eq(main.co_name_input.text, "Grandpa")
	_close(main)


func test_who_is_playing_button_brings_the_picker_back() -> void:
	var main := _open()
	main.picker.pick("grownup")
	main.profile_button.pressed.emit()
	assert_true(main.picker.visible)
	main.picker.pick("together")
	assert_eq(Settings.current.profile, "together")
	assert_true(Settings.current.read_aloud)
	_close(main)


## On the iPhone shape, the picker's three choices are big and on screen, and the hub's
## name boxes and buttons are big enough to tap.
func test_iphone_picker_and_hub_fit() -> void:
	var window := tree.root
	var old_size := window.size
	window.size = Vector2i(1320, 2868)
	var main := _open()
	main.safe_insets_override = Vector4(0, 150, 0, 80)
	main.relayout()
	await tree.process_frame
	await tree.process_frame
	var screen := main.get_viewport_rect()
	for kind: String in ["little", "grownup", "together"]:
		var r: Rect2 = main.picker.buttons[kind].get_global_rect()
		assert_true(screen.encloses(r), "%s on screen (%s)" % [kind, str(r)])
		assert_true(r.size.y >= 150.0, "%s big enough (%s)" % [kind, str(r)])
	main.picker.pick("grownup")
	await tree.process_frame
	for control: Control in [main.name_input, main.co_name_input, main.text_size_button, main.read_aloud_button, main.profile_button]:
		var r := control.get_global_rect()
		assert_true(r.size.y >= 90.0, "tall enough to tap (%s)" % str(r))
		assert_true(r.position.x >= 0.0 and r.end.x <= screen.size.x, "on screen (%s)" % str(r))
	_close(main)
	window.size = old_size
