class_name NoahCongrats
extends Control
## Noah pops up when a whole game is finished, before its story scene, as in the web
## prototype (docs/prototype/, noahCongrats): "Great job, Sam!", or, for someone who hasn't
## said their name yet, "Great job! Would you like to tell me your name?" with a box for it.
## He says it aloud (in his voice, or the reader's when his is off). Then the scene plays.

signal done ## on to the story scene
signal name_saved ## a name was typed here; the hub shows it too

const TITLE_FONT := preload("res://assets/fonts/Cinzel-700.ttf")
const BODY_FONT := preload("res://assets/fonts/Quicksand-600.ttf")
const BOLD_FONT := preload("res://assets/fonts/Quicksand-700.ttf")
const NOAH := preload("res://assets/art/hub/noah_avatar.png")

## The button that starts each game's scene.
const GO := {"word_search": "Watch them build!", "memory_match": "See them run!", "story_sequence": "See the promise"}

const INK := Color("#3A2E22")
const ARK_DARK := Color("#4A3220")
const PANEL := Color("#FDF7E8")
const CREAM := Color("#FBF2DC")
const CARD_EDGE := Color("#C7AD7C")
const GOLD := Color("#C9962E")
const GOLD_DEEP := Color("#8A6318")
const MUTED := Color("#6B5640")

## After "Nice to meet you", how long before the scene, in seconds. -1 waits for Noah to
## finish saying it. Tests set 0.
var reply_seconds := -1.0
var card: PanelContainer
var portrait: Control
var words: Label
var ask: VBoxContainer ## the name box, Save and No thanks
var name_input: LineEdit
var save_button: Button
var skip_button: Button
var go_button: Button
var _sound: AudioStreamPlayer
var _waiting := 0 ## counts holds, so only the latest one moves on


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP # nothing underneath can be tapped
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.16, 0.11, 0.07, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	# High on the screen, so the phone's keyboard doesn't cover the name box.
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	var above := Control.new()
	above.custom_minimum_size.y = 240
	above.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(above)
	card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add_theme_stylebox_override("panel", _box(PANEL, 52, 6, GOLD, 48))
	column.add_child(card)
	var inside := VBoxContainer.new()
	inside.add_theme_constant_override("separation", 30)
	card.add_child(inside)
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.add_theme_stylebox_override("panel", _box(Color("#F5E6C8"), 120, 8, ARK_DARK, 0))
	inside.add_child(frame)
	portrait = frame
	var face := TextureRect.new()
	face.texture = NOAH
	face.custom_minimum_size = Vector2(230, 230)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(face)
	words = _label("Great job!", 60, ARK_DARK, TITLE_FONT)
	inside.add_child(words)
	ask = VBoxContainer.new()
	ask.add_theme_constant_override("separation", 22)
	inside.add_child(ask)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	ask.add_child(row)
	name_input = LineEdit.new()
	name_input.placeholder_text = "Your name"
	name_input.max_length = 24
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_input.custom_minimum_size = Vector2(0, 120)
	name_input.add_theme_font_override("font", BOLD_FONT)
	name_input.add_theme_font_size_override("font_size", 46)
	name_input.add_theme_color_override("font_color", INK)
	name_input.add_theme_color_override("font_placeholder_color", MUTED)
	name_input.add_theme_color_override("caret_color", INK)
	var box := _box(Color.WHITE, 30, 4, CARD_EDGE, 0)
	box.content_margin_left = 28
	box.content_margin_right = 28
	var focus := box.duplicate() as StyleBoxFlat
	focus.border_color = GOLD
	name_input.add_theme_stylebox_override("normal", box)
	name_input.add_theme_stylebox_override("focus", focus)
	name_input.text_submitted.connect(func(text: String) -> void: continue_with(text))
	row.add_child(name_input)
	save_button = _button("Save", GOLD, GOLD_DEEP, Color.WHITE)
	save_button.custom_minimum_size = Vector2(220, 120)
	save_button.pressed.connect(func() -> void: continue_with(name_input.text))
	row.add_child(save_button)
	skip_button = _button("No thanks", CREAM, CARD_EDGE, ARK_DARK)
	skip_button.pressed.connect(func() -> void: continue_with(""))
	ask.add_child(skip_button)
	go_button = _button("Continue", GOLD, GOLD_DEEP, Color.WHITE)
	go_button.pressed.connect(func() -> void: continue_with(""))
	inside.add_child(go_button)
	_sound = AudioStreamPlayer.new()
	_sound.stream = StoryGameScreen.make_tone([523.0, 659.0, 784.0])
	add_child(_sound)
	resized.connect(_fit)
	_fit.call_deferred()


## Shows Noah's congratulations for a game just finished (its id, as in Settings.GAMES).
func open(game: String) -> void:
	var settings := Settings.current
	var has_name := settings.player_name.strip_edges() != ""
	words.text = "Great job, %s!" % settings.names() if has_name else "Great job! Would you like to tell me your name?"
	ask.visible = not has_name # only someone who hasn't said their name is asked
	go_button.text = GO.get(game, "Continue")
	go_button.visible = has_name
	name_input.text = ""
	_waiting += 1
	visible = true
	if _sound.is_inside_tree():
		_sound.play()
	_say(words.text)


## Save, No thanks, or the button to the scene. With a name, Noah says hello to it first.
func continue_with(typed: String) -> void:
	if not visible:
		return
	var clean := typed.strip_edges().left(24)
	if clean == "":
		_close()
		return
	Settings.current.player_name = clean
	Settings.current.save()
	name_saved.emit()
	name_input.release_focus()
	words.text = "Nice to meet you, %s!" % clean
	ask.visible = false
	var speaking := _say(words.text)
	var wait := reply_seconds
	if wait < 0.0:
		wait = speaking + 0.3 if speaking > 0.0 else 1.5
	_waiting += 1
	var hold := _waiting
	if wait <= 0.0 or not is_inside_tree():
		_close()
	else:
		get_tree().create_timer(wait).timeout.connect(func() -> void:
			if hold == _waiting:
				_close())


func _close() -> void:
	if not visible:
		return
	_waiting += 1
	visible = false
	done.emit()


## What Noah says is what is written: in his voice, or the reader's when his is off and
## Read to me is on. Returns about how long it takes, or 0.0 when nothing is said.
func _say(text: String) -> float:
	var seconds := NoahVoice.say(text)
	if seconds == 0.0 and Settings.current.read_aloud:
		var voices := DisplayServer.tts_get_voices_for_language("en")
		if not voices.is_empty():
			DisplayServer.tts_speak(text, voices[0], 50, 1.0, 0.9, 0, true)
			seconds = NoahVoice.seconds_for(text)
	if seconds > 0.0:
		NoahVoice.talk(portrait, seconds)
	return seconds


## The card fills the width, leaving a margin, up to a readable column on a tablet.
func _fit() -> void:
	card.custom_minimum_size.x = minf(size.x - 80.0, 900.0)


func _button(text: String, fill: Color, edge: Color, ink: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(420, 130)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_override("font", BOLD_FONT)
	button.add_theme_font_size_override("font_size", 48)
	var normal := _box(fill, 66, 0, edge, 0)
	normal.border_width_bottom = 10
	normal.content_margin_left = 40
	normal.content_margin_right = 40
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.border_width_bottom = 4
	for state in ["normal", "hover", "focus"]:
		button.add_theme_stylebox_override(state, normal)
	button.add_theme_stylebox_override("pressed", pressed)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, ink)
	return button


func _label(text: String, font_size: int, color: Color, font: Font) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
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
