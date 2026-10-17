extends TestCase
## Hub tests: the first screen loads with a big button for each story game, a button opens
## its game screen, Back returns to the hub, and everything stays inside the safe area.

const MAIN_SCENE := "res://scenes/main.tscn"
const IPHONE_PRO_MAX := Vector2i(1320, 2868) ## iPhone 18 Pro Max, portrait, in device pixels
const MIN_TAP := 120.0 ## canvas pixels; about 1 cm on the iPhone, well over Apple's 44 pt


func _open_main() -> Control:
	var main: Control = load(MAIN_SCENE).instantiate()
	tree.root.add_child(main)
	return main


func _close(main: Control) -> void:
	tree.root.remove_child(main)
	main.free()


func test_hub_shows_three_games() -> void:
	var main := _open_main()
	assert_eq(main.current_game, "")
	assert_true(main.hub.visible, "hub visible")
	assert_false(main.game_screen.visible, "game screen hidden")
	assert_eq(main.game_buttons.size(), 3)
	for id: String in ["word_search", "memory_match", "story_sequence"]:
		assert_true(main.game_buttons.has(id), "button for %s" % id)
	_close(main)


func test_tap_game_then_back() -> void:
	var main := _open_main()
	for game: Dictionary in MiniGames.LIST:
		(main.game_buttons[game["id"]] as Button).pressed.emit()
		assert_eq(main.current_game, game["id"])
		assert_true(main.game_screen.visible, "%s screen visible" % game["id"])
		assert_eq(main.game_title.text, game["title"])
		main.back_button.pressed.emit()
		assert_eq(main.current_game, "")
		assert_true(main.hub.visible, "back on the hub after %s" % game["id"])
	_close(main)


func test_unknown_game_stays_on_hub() -> void:
	var main := _open_main()
	main.open_game("not_a_game")
	assert_eq(main.current_game, "")
	assert_true(main.hub.visible)
	_close(main)


## On the iPhone shape, with its notch and home bar, every button is a big target
## and nothing reaches into the safe-area margins.
func test_iphone_layout_inside_safe_area() -> void:
	var window := tree.root
	var old_size := window.size
	window.size = IPHONE_PRO_MAX
	var main := _open_main()
	var screen := main.get_viewport_rect().size
	var insets := Vector4(0, 150, 0, 80) # top: Dynamic Island, bottom: home bar
	main.safe_insets_override = insets
	main.relayout()
	await tree.process_frame
	await tree.process_frame
	assert_true(screen.y > screen.x, "portrait canvas (%s)" % str(screen))
	var safe := Rect2(insets.x, insets.y, screen.x - insets.x - insets.z, screen.y - insets.y - insets.w)
	var buttons: Array = main.game_buttons.values()
	for button: Button in buttons:
		var r := button.get_global_rect()
		assert_true(safe.encloses(r), "%s inside safe area (%s)" % [button.text.get_slice("\n", 0), str(r)])
		assert_true(r.size.y >= MIN_TAP, "%s tall enough" % button.text.get_slice("\n", 0))
	main.open_game("word_search")
	await tree.process_frame
	var back: Rect2 = main.back_button.get_global_rect()
	assert_true(safe.encloses(back), "Back inside safe area (%s)" % str(back))
	assert_true(back.size.y >= MIN_TAP and back.size.x >= MIN_TAP, "Back big enough")
	_close(main)
	window.size = old_size
