class_name StorySequenceScreen
extends VBoxContainer
## Story Sequence, laid out like the web prototype's (docs/prototype/): the round and
## "No rush" pills with Noah beside them, then a warm panel with the prompt, a button that
## reads the choices aloud, a row of timeline slots, and a big card for each event.
## Tapping the right event moves its picture into the next slot; a wrong one gives a
## gentle shake and Noah says to think again. Three rounds, each a longer story. No timer.

signal leave ## the player chose to go back to the hub (after confirming, mid-round)
signal finished ## the player finished the last round and tapped Continue

const TITLE_FONT := preload("res://assets/fonts/Cinzel-700.ttf")
const BODY_FONT := preload("res://assets/fonts/Quicksand-600.ttf")
const BOLD_FONT := preload("res://assets/fonts/Quicksand-700.ttf")
const PROMPT_FONT := preload("res://assets/fonts/Baloo2-700.ttf")
const NOAH := preload("res://assets/art/hub/noah_avatar.png")
const ART := {
	"build": preload("res://assets/art/story_sequence/ev_build.png"),
	"board": preload("res://assets/art/story_sequence/ev_board.png"),
	"shut": preload("res://assets/art/story_sequence/ev_shut.png"),
	"rain": preload("res://assets/art/story_sequence/ev_rain.png"),
	"land": preload("res://assets/art/story_sequence/ev_land.png"),
	"dove": preload("res://assets/art/story_sequence/ev_dove.png"),
	"rainbow": preload("res://assets/art/story_sequence/ev_rainbow.png"),
}

## The prototype's words of praise; Noah cheers the first right answer, then every third.
const PRAISE := ["Wonderful!", "Well done!", "You found it!", "Great job!", "Excellent!", "Keep going!", "Just right!"]
const OOPS := "Hmm, think again!"

const INK := Color("#3A2E22")
const ARK_DARK := Color("#4A3220")
const CREAM := Color("#FBF2DC")
const CARD_TOP := Color("#FFFCF4")
const CARD_EDGE := Color("#C7AD7C")
const GOLD := Color("#C9962E")
const GOLD_DEEP := Color("#8A6318")

const CARD_SIZE := 44 ## card words
const CARD_PICTURE := 170.0
const SLOT_MAX := 140.0
const SLOT_GAP := 16

## Pauses, in seconds. Tests set them to 0.
var complete_delay := 1.2 ## after the last event is placed, before "Round Complete!"
var get_ready_seconds := 2.5 ## the "Get Ready!" card between rounds
var bubble_seconds := 2.6 ## how long Noah's words stay up

var game := StorySequence.new()
var cards: Dictionary = {} ## event id -> its card Button
var slots: Array[PanelContainer] = []
var round_label: Label
var noah_bubble: PanelContainer
var noah_words: Label
var hear_button: Button
var timeline: HBoxContainer
var card_grid: GridContainer
var overlay: PanelContainer
var overlay_title: Label
var overlay_text: Label
var overlay_button: Button
var overlay_cancel: Button
var _overlay_action := "" ## what overlay_button does: "continue", "finish", or "leave"
var _sound: AudioStreamPlayer
var _bubble_timer: SceneTreeTimer
var _voice := ""
var _chimes := {} ## true/false -> the right/wrong chime, made once


func _ready() -> void:
	add_theme_constant_override("separation", 24)
	_build_top_row()
	_build_panel()
	_sound = AudioStreamPlayer.new()
	add_child(_sound)
	var voices := DisplayServer.tts_get_voices_for_language("en")
	if not voices.is_empty():
		_voice = voices[0]
	resized.connect(_fit)


## Starts the game again from round 1.
func start() -> void:
	_start_round(0)


## True when leaving now would lose a round in progress.
func has_progress() -> bool:
	return game.has_progress()


## Back was tapped. Leaves right away, unless that would lose progress: then asks first.
func request_leave() -> void:
	if not has_progress():
		_stop_speaking()
		leave.emit()
		return
	_show_overlay("Leave this round?", "Your progress on it will be lost.", "Leave", "leave", true)


## Taps an event's card, as a finger would. For tests.
func tap_card(id: String) -> void:
	(cards[id] as Button).pressed.emit()


func _start_round(index: int) -> void:
	game.start(index)
	round_label.text = "Round %d of %d" % [game.round_index + 1, StorySequence.ROUNDS.size()]
	_hide_overlay()
	_say("")
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
		elif game.placed == 1 or game.placed % 3 == 0:
			_say(PRAISE.pick_random())
	else:
		_chime(false)
		_say(OOPS)
		var tween := create_tween()
		var home := card.position.x
		for dx: float in [-14.0, 14.0, -8.0, 0.0]:
			tween.tween_property(card, "position:x", home + dx, 0.08)


func _show_round_complete() -> void:
	if game.is_last_round():
		_show_overlay("The Whole Story!", "You placed every event in order, all the way to God's promise.", "Continue", "finish")
	else:
		_show_overlay("Round Complete!", "Great memory! A longer story is next.", "Continue", "continue")


func _on_overlay_button() -> void:
	match _overlay_action:
		"leave":
			_hide_overlay()
			_stop_speaking()
			leave.emit()
		"finish":
			_hide_overlay()
			finished.emit()
		"continue":
			var next := game.round_index + 1
			_show_overlay("Get Ready!", "Round %d is coming up..." % (next + 1), "", "")
			_after(get_ready_seconds, _start_round.bind(next))


func _show_overlay(title: String, text: String, button: String, action: String, can_cancel := false) -> void:
	_overlay_action = action
	overlay_title.text = title
	overlay_text.text = text
	overlay_button.text = button
	overlay_button.visible = button != ""
	overlay_cancel.visible = can_cancel
	overlay.visible = true
	_speak("%s %s" % [title, text])


func _hide_overlay() -> void:
	overlay.visible = false
	_overlay_action = ""


## Noah's speech bubble. Empty hides it (it keeps its place, so nothing jumps).
func _say(text: String) -> void:
	noah_words.text = text
	noah_bubble.modulate.a = 1.0 if text != "" else 0.0
	if text == "":
		return
	var timer := get_tree().create_timer(bubble_seconds) if is_inside_tree() else null
	_bubble_timer = timer
	if timer != null:
		timer.timeout.connect(func() -> void:
			if _bubble_timer == timer:
				noah_bubble.modulate.a = 0.0)


## Runs action after a pause, or right away when the pause is 0 (tests).
func _after(seconds: float, action: Callable) -> void:
	if seconds <= 0.0 or not is_inside_tree():
		action.call()
	else:
		get_tree().create_timer(seconds).timeout.connect(action)


func _hear_choices() -> void:
	_stop_speaking()
	# Read the cards in the order they're laid out, skipping ones already placed.
	for card: Button in card_grid.get_children():
		if not card.disabled:
			_speak(card.get_meta("label"), false)


func _speak(text: String, interrupt := true) -> void:
	if _voice != "" and text != "":
		DisplayServer.tts_speak(text, _voice, 50, 1.0, 0.9, 0, interrupt)


func _stop_speaking() -> void:
	if _voice != "":
		DisplayServer.tts_stop()


## A short chime: rising notes when right, two low notes when not (like the prototype's).
func _chime(correct: bool) -> void:
	if not _chimes.has(correct):
		_chimes[correct] = _make_chime(correct)
	_sound.stream = _chimes[correct]
	if _sound.is_inside_tree():
		_sound.play()


func _make_chime(correct: bool) -> AudioStreamWAV:
	var notes: Array = [523.0, 659.0, 784.0] if correct else [330.0, 294.0]
	var rate := 22050
	var step := int(rate * 0.08)
	var length := step * (notes.size() - 1) + int(rate * 0.32)
	var samples := PackedFloat32Array()
	samples.resize(length)
	for n in notes.size():
		var start := n * step
		for i in int(rate * 0.32):
			var t := float(i) / rate
			var env := minf(t / 0.02, 1.0) * exp(-t * 14.0)
			samples[start + i] += sin(TAU * notes[n] * t) * env * 0.22
	var data := PackedByteArray()
	data.resize(length * 2)
	for i in length:
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav


## Round pill on the left; Noah, with his speech bubble, on the right.
func _build_top_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	add_child(row)
	var pills := VBoxContainer.new()
	pills.add_theme_constant_override("separation", 14)
	pills.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pills)
	round_label = _pill("Round 1 of 3")
	pills.add_child(round_label)
	pills.add_child(_pill("No rush"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	noah_bubble = PanelContainer.new()
	noah_bubble.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	noah_bubble.add_theme_stylebox_override("panel", _box(CREAM, 40, 0, ARK_DARK, 24))
	row.add_child(noah_bubble)
	noah_words = _label("", CARD_SIZE, INK, BOLD_FONT)
	noah_words.autowrap_mode = TextServer.AUTOWRAP_OFF
	noah_bubble.add_child(noah_words)
	var avatar_frame := PanelContainer.new()
	var frame := _box(CREAM, 90, 8, ARK_DARK, 0)
	avatar_frame.add_theme_stylebox_override("panel", frame)
	avatar_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(avatar_frame)
	var avatar := TextureRect.new()
	avatar.texture = NOAH
	avatar.custom_minimum_size = Vector2(150, 150)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_frame.add_child(avatar)
	_say("")


## The warm panel: prompt, Hear the choices, timeline, cards, and the overlay on top.
func _build_panel() -> void:
	var outer := PanelContainer.new()
	outer.add_theme_stylebox_override("panel", _box(CREAM, 52, 0, GOLD, 10))
	add_child(outer)
	var inner := PanelContainer.new()
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color.WHITE
	fill.set_corner_radius_all(44)
	fill.anti_aliasing = true
	inner.add_theme_stylebox_override("panel", fill)
	inner.clip_children = CanvasItem.CLIP_CHILDREN_ONLY # rounds the gradient's corners
	outer.add_child(inner)
	var warm := TextureRect.new()
	var gradient := GradientTexture2D.new()
	gradient.fill_from = Vector2(0, 0)
	gradient.fill_to = Vector2(0, 1)
	gradient.gradient = Gradient.new()
	gradient.gradient.set_color(0, Color("#F3CD8C"))
	gradient.gradient.set_color(1, Color("#DC8E4E"))
	warm.texture = gradient
	warm.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	warm.stretch_mode = TextureRect.STRETCH_SCALE
	warm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(warm)
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 44)
	inner.add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 28)
	margin.add_child(body)
	var prompt := _label("Tap what happens next in the story...", 46, ARK_DARK, PROMPT_FONT)
	body.add_child(prompt)
	hear_button = Button.new()
	hear_button.text = "Hear the choices"
	hear_button.focus_mode = Control.FOCUS_NONE
	hear_button.custom_minimum_size = Vector2(0, 120)
	hear_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hear_button.add_theme_font_override("font", BOLD_FONT)
	hear_button.add_theme_font_size_override("font_size", CARD_SIZE)
	var hear := _box(CREAM, 60, 6, GOLD, 0)
	hear.content_margin_left = 60
	hear.content_margin_right = 60
	var hear_down := hear.duplicate() as StyleBoxFlat
	hear_down.bg_color = CREAM.darkened(0.06)
	for state in ["normal", "hover", "focus"]:
		hear_button.add_theme_stylebox_override(state, hear)
	hear_button.add_theme_stylebox_override("pressed", hear_down)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		hear_button.add_theme_color_override(key, ARK_DARK)
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
	var edge := Panel.new()
	var line := StyleBoxFlat.new()
	line.draw_center = false
	line.set_corner_radius_all(44)
	line.set_border_width_all(6)
	line.border_color = GOLD
	line.anti_aliasing = true
	edge.add_theme_stylebox_override("panel", line)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(edge)
	_build_overlay(inner)


## The card over the panel for "Round Complete!", "Get Ready!" and "Leave this round?".
func _build_overlay(parent: Control) -> void:
	overlay = PanelContainer.new()
	overlay.add_theme_stylebox_override("panel", _box(Color(0.99, 0.96, 0.89, 0.94), 44, 0, GOLD, 50))
	overlay.visible = false
	parent.add_child(overlay)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 36)
	overlay.add_child(column)
	overlay_title = _label("", 72, ARK_DARK, TITLE_FONT)
	column.add_child(overlay_title)
	overlay_text = _label("", 46, INK)
	column.add_child(overlay_text)
	overlay_button = _big_button("Continue", GOLD, GOLD_DEEP)
	overlay_button.pressed.connect(_on_overlay_button)
	column.add_child(overlay_button)
	overlay_cancel = _big_button("Keep playing", CREAM, CARD_EDGE)
	overlay_cancel.pressed.connect(_hide_overlay)
	column.add_child(overlay_cancel)


## One event's card: its picture and its words. The whole card is the button.
func _event_card(event: Dictionary) -> Button:
	var card := Button.new()
	card.focus_mode = Control.FOCUS_NONE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.set_meta("label", event["label"])
	var normal := _box(CARD_TOP, 40, 0, CARD_EDGE, 0)
	normal.border_width_bottom = 10
	normal.shadow_color = Color(0.29, 0.2, 0.13, 0.2)
	normal.shadow_size = 10
	normal.shadow_offset = Vector2(0, 6)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = CARD_TOP.darkened(0.05)
	pressed.border_width_bottom = 4
	for state in ["normal", "hover", "focus", "disabled"]:
		card.add_theme_stylebox_override(state, normal)
	card.add_theme_stylebox_override("pressed", pressed)
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


func _pill(text: String) -> Label:
	var pill := _label(text, 40, CREAM, PROMPT_FONT)
	pill.autowrap_mode = TextServer.AUTOWRAP_OFF
	var box := _box(ARK_DARK, 50, 0, ARK_DARK, 0)
	box.content_margin_left = 40
	box.content_margin_right = 40
	box.content_margin_top = 10
	box.content_margin_bottom = 12
	box.shadow_color = Color(0, 0, 0, 0.25)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, 4)
	pill.add_theme_stylebox_override("normal", box)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return pill


func _big_button(text: String, fill: Color, edge: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(420, 130)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_override("font", BOLD_FONT)
	button.add_theme_font_size_override("font_size", 48)
	var normal := _box(fill, 66, 0, edge, 0)
	normal.border_width_bottom = 10
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.border_width_bottom = 4
	for state in ["normal", "hover", "focus"]:
		button.add_theme_stylebox_override(state, normal)
	button.add_theme_stylebox_override("pressed", pressed)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, ARK_DARK)
	return button


func _label(text: String, font_size: int, color: Color, font: Font = null) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if font != null:
		label.add_theme_font_override("font", font)
	return label


func _box(fill: Color, radius: int, border: int, border_color: Color, margin: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border)
	box.border_color = border_color
	box.set_content_margin_all(margin)
	box.anti_aliasing = true
	return box
