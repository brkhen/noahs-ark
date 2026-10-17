class_name ProfilePicker
extends Control
## "Who's playing today?", as in the web prototype (docs/prototype/, profileModal): the first
## thing a new player sees, over a dimmed hub. One tap on Little one, Grown-up or Together
## sets up text size and reading aloud (Settings.PROFILES). It comes back from the hub's
## "Who's playing" button.

signal chosen(kind: String)

const TITLE_FONT := preload("res://assets/fonts/Cinzel-700.ttf")
const BODY_FONT := preload("res://assets/fonts/Quicksand-600.ttf")
const BOLD_FONT := preload("res://assets/fonts/Quicksand-700.ttf")

const OPTIONS := [
	["little", "Little one", "Big pictures, a friendly voice that reads to you, and no rush."],
	["grownup", "Grown-up", "Easy-to-read text, a relaxed pace with no timers, and the words read only when you ask."],
	["together", "Together", "A grown-up and a little one, side by side, with everything read aloud."],
]
const SPOKEN := "Who is playing today? A little one. A grown-up. Or together. Tap the one that fits."

const INK := Color("#3A2E22")
const ARK_DARK := Color("#4A3220")
const PANEL := Color("#FDF7E8")
const CARD := Color("#F2E4C3")
const CARD_EDGE := Color("#C7AD7C")
const GOLD := Color("#C9962E")
const MUTED := Color("#6B5640")

var buttons: Dictionary = {} ## kind -> its Button
var hear_button: Button
var card: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP # the hub underneath can't be tapped
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.08, 0.04, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _box(PANEL, 52, 6, GOLD, 44))
	center.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 26)
	card.add_child(column)
	column.add_child(_label("Who's playing today?", 66, ARK_DARK, TITLE_FONT))
	column.add_child(_label("Pick one, and I'll set things up just right.", 42, INK, BODY_FONT))
	hear_button = Button.new()
	hear_button.text = "Hear this"
	hear_button.focus_mode = Control.FOCUS_NONE
	hear_button.custom_minimum_size = Vector2(0, 110)
	hear_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hear_button.add_theme_font_override("font", BOLD_FONT)
	hear_button.add_theme_font_size_override("font_size", 42)
	var hear := _box(Color("#FBF2DC"), 56, 6, GOLD, 0)
	hear.content_margin_left = 56
	hear.content_margin_right = 56
	for state in ["normal", "hover", "focus", "pressed"]:
		hear_button.add_theme_stylebox_override(state, hear)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		hear_button.add_theme_color_override(key, ARK_DARK)
	hear_button.pressed.connect(_hear)
	column.add_child(hear_button)
	for option: Array in OPTIONS:
		var button := _option(option[1], option[2])
		button.pressed.connect(_pick.bind(option[0]))
		column.add_child(button)
		buttons[option[0]] = button
	column.add_child(_label("You can change this any time with the \"Who's playing\" button.", 36, MUTED, BODY_FONT))
	resized.connect(_fit)
	_fit.call_deferred() # once this has its full size


## Taps one of the choices, as a finger would. For tests.
func pick(kind: String) -> void:
	(buttons[kind] as Button).pressed.emit()


func _pick(kind: String) -> void:
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
	chosen.emit(kind)


func _hear() -> void:
	var voices := DisplayServer.tts_get_voices_for_language("en")
	if not voices.is_empty():
		DisplayServer.tts_speak(SPOKEN, voices[0], Settings.current.tts_volume(), 1.0, Settings.current.rate(), 0, true)


## One choice: its name in bold and what it sets up, the whole card one button.
func _option(title: String, text: String) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	var normal := _box(CARD, 40, 0, CARD_EDGE, 0)
	normal.border_width_bottom = 10
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = CARD.darkened(0.06)
	pressed.border_width_bottom = 4
	for state in ["normal", "hover", "focus"]:
		button.add_theme_stylebox_override(state, normal)
	button.add_theme_stylebox_override("pressed", pressed)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 6)
	words.set_anchors_preset(Control.PRESET_FULL_RECT)
	words.offset_left = 36
	words.offset_top = 24
	words.offset_right = -36
	words.offset_bottom = -30
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(words)
	for line: Label in [_label(title, 50, ARK_DARK, BOLD_FONT), _label(text, 38, INK, BODY_FONT)]:
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.add_child(line)
	words.minimum_size_changed.connect(func() -> void:
		button.custom_minimum_size.y = words.get_combined_minimum_size().y + 54.0)
	return button


## The card fills the width, leaving a margin, up to a readable column on a tablet.
func _fit() -> void:
	card.custom_minimum_size.x = minf(size.x - 80.0, 960.0)


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
