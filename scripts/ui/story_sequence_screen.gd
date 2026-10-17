class_name StorySequenceScreen
extends StoryGameScreen
## Story Sequence, laid out like the web prototype's (docs/prototype/): in the warm panel,
## the prompt, a button that reads the choices aloud, a row of timeline slots, and a big
## card for each event. Tapping the right event moves its picture into the next slot; a
## wrong one gives a gentle shake and Noah says to think again. Three rounds, each a longer
## story. No timer.

const ART := {
	"build": preload("res://assets/art/story_sequence/ev_build.png"),
	"board": preload("res://assets/art/story_sequence/ev_board.png"),
	"shut": preload("res://assets/art/story_sequence/ev_shut.png"),
	"rain": preload("res://assets/art/story_sequence/ev_rain.png"),
	"land": preload("res://assets/art/story_sequence/ev_land.png"),
	"dove": preload("res://assets/art/story_sequence/ev_dove.png"),
	"rainbow": preload("res://assets/art/story_sequence/ev_rainbow.png"),
}

const OOPS := "Hmm, think again!"

const CARD_SIZE := WORDS_SIZE ## card words
const CARD_PICTURE := 170.0
const SLOT_MAX := 140.0
const SLOT_GAP := 16

var game := StorySequence.new()
var cards: Dictionary = {} ## event id -> its card Button
var slots: Array[PanelContainer] = []
var hear_button: Button
var timeline: HBoxContainer
var card_grid: GridContainer


func _ready() -> void:
	super()
	resized.connect(_fit)


func has_progress() -> bool:
	return game.has_progress()


## Taps an event's card, as a finger would. For tests.
func tap_card(id: String) -> void:
	(cards[id] as Button).pressed.emit()


func _round_count() -> int:
	return StorySequence.ROUNDS.size()


func _round_index() -> int:
	return game.round_index


func _start_round(index: int) -> void:
	game.start(index)
	_begin_round_ui()
	for child in timeline.get_children():
		timeline.remove_child(child)
		child.queue_free()
	slots.clear()
	for i in game.events().size():
		var slot := PanelContainer.new()
		slot.add_theme_stylebox_override("panel", _slot_style(false))
		timeline.add_child(slot)
		slots.append(slot)
	for child in card_grid.get_children():
		card_grid.remove_child(child)
		child.queue_free()
	cards.clear()
	for event: Dictionary in game.shuffled_events():
		var card := _event_card(event)
		card_grid.add_child(card)
		cards[event["id"]] = card
	_fit()


func _on_card(card: Button, event: Dictionary) -> void:
	if card.disabled or overlay.visible:
		return
	if game.tap(event["id"]):
		card.disabled = true
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		create_tween().tween_property(card, "modulate:a", 0.0, 0.3)
		var slot := slots[game.placed - 1]
		slot.add_theme_stylebox_override("panel", _slot_style(true))
		slot.add_child(_picture(event["art"], 0.0))
		slot.pivot_offset = slot.size / 2.0
		slot.scale = Vector2(1.15, 1.15)
		create_tween().tween_property(slot, "scale", Vector2.ONE, 0.3)
		_chime(true)
		_speak(event["label"])
		if game.round_done():
			_say("")
			_after(complete_delay, _show_round_complete)
		else:
			_cheer(game.placed)
	else:
		_chime(false)
		_say(OOPS)
		var tween := create_tween()
		var home := card.position.x
		for dx: float in [-14.0, 14.0, -8.0, 0.0]:
			tween.tween_property(card, "position:x", home + dx, 0.08)


func _show_round_complete() -> void:
	if game.is_last_round():
		_show_overlay("The Whole Story!", "You placed every event in order, all the way to God's promise.", "See the promise", "finish")
	else:
		_show_overlay("Round Complete!", "Great memory! A longer story is next.", "Continue", "continue")


func _hear_choices() -> void:
	_stop_speaking()
	# Read the cards in the order they're laid out, skipping ones already placed.
	for card: Button in card_grid.get_children():
		if not card.disabled:
			_speak(card.get_meta("label"), false)


## The prompt, Hear the choices, the timeline, and the cards.
func _build_body(body: VBoxContainer) -> void:
	body.add_child(_label("Tap what happens next in the story...", 46, ARK_DARK, PROMPT_FONT))
	hear_button = _soft_button("Hear the choices")
	hear_button.pressed.connect(_hear_choices)
	body.add_child(hear_button)
	timeline = HBoxContainer.new()
	timeline.alignment = BoxContainer.ALIGNMENT_CENTER
	timeline.add_theme_constant_override("separation", SLOT_GAP)
	body.add_child(timeline)
	card_grid = GridContainer.new()
	card_grid.columns = 2
	card_grid.add_theme_constant_override("h_separation", 26)
	card_grid.add_theme_constant_override("v_separation", 26)
	body.add_child(card_grid)


## One event's card: its picture and its words. The whole card is the button.
func _event_card(event: Dictionary) -> Button:
	var card := _card_button()
	card.set_meta("label", event["label"])
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 20
	column.offset_top = 22
	column.offset_right = -20
	column.offset_bottom = -30
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(column)
	column.add_child(_picture(event["art"], CARD_PICTURE))
	column.add_child(_label(event["label"], CARD_SIZE, INK, BOLD_FONT))
	for child in column.get_children():
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fit := func() -> void:
		card.custom_minimum_size.y = column.get_combined_minimum_size().y + 52.0
	column.minimum_size_changed.connect(fit)
	card.pressed.connect(_on_card.bind(card, event))
	return card


func _picture(art: String, height: float) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = ART[art]
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(0, height)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return picture


func _slot_style(filled: bool) -> StyleBoxFlat:
	var box := _box(GOLD if filled else Color(1, 1, 1, 0.35), 26, 5, GOLD_DEEP if filled else CARD_EDGE, 8)
	if filled:
		box.shadow_color = Color(0, 0, 0, 0.2)
		box.shadow_size = 8
		box.shadow_offset = Vector2(0, 4)
	return box


## Slots share the row (up to 6 in round 3); cards go 2 across, 3 on a wide screen.
func _fit() -> void:
	if timeline == null or slots.is_empty():
		return
	var width := timeline.size.x if timeline.size.x > 0.0 else size.x - 80.0
	var side := minf(SLOT_MAX, (width - SLOT_GAP * (slots.size() - 1)) / slots.size())
	for slot in slots:
		slot.custom_minimum_size = Vector2(side, side)
	card_grid.columns = 3 if width > 1100.0 else 2
