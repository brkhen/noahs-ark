class_name MemoryMatchScreen
extends StoryGameScreen
## Memory Match, laid out like the web prototype's (docs/prototype/): a grid of cards with
## the ark on their backs, four across. Tap two to turn them over; a pair of animals stays
## face up and Noah says their name, two different ones turn back over. Three rounds
## (4, 5, then 6 pairs). No timer.

const BACK := preload("res://assets/art/memory_match/card_back.png")
const ART := {
	"dove": preload("res://assets/art/memory_match/animal_dove.png"),
	"lion": preload("res://assets/art/memory_match/animal_lion.png"),
	"giraffe": preload("res://assets/art/memory_match/animal_giraffe.png"),
	"elephant": preload("res://assets/art/memory_match/animal_elephant.png"),
	"zebra": preload("res://assets/art/memory_match/animal_zebra.png"),
	"monkey": preload("res://assets/art/memory_match/animal_monkey.png"),
}
const MATCHED := Color("#F4E7C9") ## a found pair's cards, a little warmer
const COLUMNS := 4
const GAP := 22

## Pauses, in seconds. Tests set them to 0.
var miss_seconds := 0.9 ## how long two different animals stay up before turning back

var game := MemoryMatch.new()
var cards: Array[Button] = [] ## in deck order
var grid: GridContainer


func _ready() -> void:
	super()
	resized.connect(_fit)


func has_progress() -> bool:
	return game.has_progress()


## Taps card i, as a finger would. For tests.
func tap_card(i: int) -> void:
	cards[i].pressed.emit()


## The indexes of the two cards with this animal. For tests.
func cards_of(animal: String) -> Array:
	var found := []
	for i in game.deck.size():
		if game.deck[i] == animal:
			found.append(i)
	return found


func _round_count() -> int:
	return MemoryMatch.PAIRS.size()


func _round_index() -> int:
	return game.round_index


func _start_round(index: int) -> void:
	game.start(index)
	_begin_round_ui()
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	cards.clear()
	for i in game.deck.size():
		var card := _card(i)
		grid.add_child(card)
		cards.append(card)
	_fit()


func _on_card(i: int) -> void:
	if overlay.visible:
		return
	var result := game.flip(i)
	if result == "ignored":
		return
	_turn(i, true)
	match result:
		"match":
			var pair := [i, game.matched[game.matched.size() - 2]]
			for k: int in pair:
				_show_matched(k)
			_chime(true)
			Settings.current.find_animal(game.deck[i]) # for the Hall of the Ark
			_speak(_plural(game.deck[i]))
			if game.round_done():
				_say("")
				_after(complete_delay, _show_round_complete)
			else:
				_cheer(game.matches)
		"miss":
			_after(0.2 if miss_seconds > 0.0 else 0.0, _chime.bind(false))
			_after(miss_seconds, _turn_back)


func _turn_back() -> void:
	for k: int in game.settle():
		_turn(k, false)


func _show_round_complete() -> void:
	if game.is_last_round():
		_show_overlay("All Rounds Complete!", "Every animal found their pair. Let's get them to the ark!", "See them run!", "finish")
	else:
		_show_overlay("Round Complete!", "Great memory! On to a bigger round.", "Continue", "continue")


## "Lions!", "Doves!": what Noah says when a pair is found.
func _plural(animal: String) -> String:
	return animal.capitalize() + "s!"


func _build_body(body: VBoxContainer) -> void:
	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.resized.connect(_fit)
	body.add_child(grid)


## One card: the ark on its back, the animal on its front. The whole card is the button.
func _card(i: int) -> Button:
	var card := Button.new()
	card.focus_mode = Control.FOCUS_NONE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var clear := StyleBoxEmpty.new()
	for state in ["normal", "hover", "focus", "pressed", "disabled"]:
		card.add_theme_stylebox_override(state, clear)
	var back := TextureRect.new()
	back.name = "Back"
	back.texture = BACK
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_SCALE
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(back)
	var front := Panel.new()
	front.name = "Front"
	var face := _box(CARD_TOP, 36, 0, CARD_EDGE, 0)
	face.border_width_bottom = 8
	face.shadow_color = Color(0.42, 0.27, 0.16, 0.28)
	face.shadow_size = 8
	face.shadow_offset = Vector2(0, 4)
	front.add_theme_stylebox_override("panel", face)
	front.set_anchors_preset(Control.PRESET_FULL_RECT)
	front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.visible = false
	card.add_child(front)
	var animal := TextureRect.new()
	animal.texture = ART[game.deck[i]]
	animal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	animal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	animal.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top"]:
		animal.set("offset_" + side, 18)
	for side in ["right", "bottom"]:
		animal.set("offset_" + side, -18)
	animal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.add_child(animal)
	card.pressed.connect(_on_card.bind(i))
	return card


## Turns a card over with a quick flip (it narrows to an edge, then opens on its other face).
func _turn(i: int, face_up: bool) -> void:
	var card := cards[i]
	card.pivot_offset = card.size / 2.0
	var swap := func() -> void:
		card.get_node("Front").visible = face_up
		card.get_node("Back").visible = not face_up
	if not is_inside_tree() or miss_seconds <= 0.0:
		swap.call()
		return
	var tween := create_tween()
	tween.tween_property(card, "scale:x", 0.0, 0.12)
	tween.tween_callback(swap)
	tween.tween_property(card, "scale:x", 1.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_matched(i: int) -> void:
	var front: Panel = cards[i].get_node("Front")
	var face := (front.get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	face.bg_color = MATCHED
	front.add_theme_stylebox_override("panel", face)
	cards[i].disabled = true
	if is_inside_tree() and miss_seconds > 0.0:
		var card := cards[i]
		card.pivot_offset = card.size / 2.0
		var tween := create_tween()
		tween.tween_interval(0.3)
		tween.tween_property(card, "scale", Vector2(1.06, 1.06), 0.15)
		tween.tween_property(card, "scale", Vector2.ONE, 0.2)


## Square cards, four across the panel.
func _fit() -> void:
	if grid == null or cards.is_empty():
		return
	var width := grid.size.x if grid.size.x > 0.0 else size.x - 80.0
	if width <= 0.0:
		return # not laid out yet; resized calls this again
	var side := floorf((width - GAP * (COLUMNS - 1)) / COLUMNS)
	for card in cards:
		card.custom_minimum_size = Vector2(side, side)
