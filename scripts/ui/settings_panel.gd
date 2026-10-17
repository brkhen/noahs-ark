class_name SettingsPanel
extends VBoxContainer
## The hub's Settings, as in the web prototype (docs/prototype/, settings-panel): who's
## playing, volume (with a test sound), Read to me, Noah's voice, voice speed, and text
## size. A choice is a row of big buttons with the chosen one in gold. Everything is kept
## on the phone (Settings). The prototype's timers, simpler screens and camera moves
## aren't here: the app has no timers, and its screens and scenes are already the gentle
## kind.

signal changed ## a setting changed; the hub shows it
signal profile_picked(kind: String)

const TITLE_FONT := preload("res://assets/fonts/Cinzel-700.ttf")
const BODY_FONT := preload("res://assets/fonts/Quicksand-600.ttf")
const BOLD_FONT := preload("res://assets/fonts/Quicksand-700.ttf")

const INK := Color("#3A2E22")
const ARK_DARK := Color("#4A3220")
const CREAM := Color("#FBF2DC")
const CARD_EDGE := Color("#C7AD7C")
const GOLD := Color("#C9962E")
const GOLD_DEEP := Color("#8A6318")

var choices: Dictionary = {} ## setting name -> {value -> its Button}
var volume_slider: HSlider
var volume_readout: Label
var test_button: Button
var _sound: AudioStreamPlayer


func _ready() -> void:
	add_theme_constant_override("separation", 22)
	_heading("Who's playing")
	_choice("profile", [["little", "Little one"], ["grownup", "Grown-up"], ["together", "Together"]])
	_heading("Sound and voice")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	add_child(row)
	var volume_label := _label("Volume", 40, ARK_DARK, BOLD_FONT)
	volume_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(volume_label)
	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.step = 10
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	volume_slider.custom_minimum_size.y = 90
	volume_slider.focus_mode = Control.FOCUS_NONE
	var track := _box(Color("#E6D3AE"), 14, 0, GOLD, 0)
	track.content_margin_top = 14
	track.content_margin_bottom = 14
	volume_slider.add_theme_stylebox_override("slider", track)
	var filled := _box(GOLD, 14, 0, GOLD, 0)
	filled.content_margin_top = 14
	filled.content_margin_bottom = 14
	volume_slider.add_theme_stylebox_override("grabber_area", filled)
	volume_slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	var knob := _knob()
	volume_slider.add_theme_icon_override("grabber", knob)
	volume_slider.add_theme_icon_override("grabber_highlight", knob)
	volume_slider.value_changed.connect(_on_volume)
	row.add_child(volume_slider)
	volume_readout = _label("100%", 40, INK, BOLD_FONT)
	volume_readout.custom_minimum_size.x = 130
	row.add_child(volume_readout)
	test_button = _button("Test sound")
	test_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	test_button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	test_button.custom_minimum_size.x = 380
	test_button.pressed.connect(test_sound)
	add_child(test_button)
	_name("Read to me")
	_choice("read_aloud", [[true, "On"], [false, "Off"]])
	_name("Noah's voice")
	_choice("voice_on", [[true, "On"], [false, "Off"]])
	_name("Voice speed")
	_choice("speech_rate", [["slow", "Slow"], ["normal", "Normal"]])
	_heading("Reading")
	_name("Text size")
	_choice("text_size", [["normal", "Normal"], ["large", "Large"], ["xlarge", "Extra large"]])
	_sound = AudioStreamPlayer.new()
	_sound.stream = StoryGameScreen.make_tone([523.0, 659.0, 784.0])
	add_child(_sound)
	refresh()


## Shows the saved settings.
func refresh() -> void:
	var settings := Settings.current
	for setting: String in choices:
		for value: Variant in choices[setting]:
			_paint(choices[setting][value], settings.get(setting) == value)
	volume_slider.set_value_no_signal(round(settings.volume * 100.0))
	volume_readout.text = "%d%%" % int(round(settings.volume * 100.0))


## Plays the chime and says a few words, at the volume chosen.
func test_sound() -> void:
	if _sound.is_inside_tree():
		_sound.play()
	var voices := DisplayServer.tts_get_voices_for_language("en")
	if not voices.is_empty():
		DisplayServer.tts_speak("This is how loud the voice is.", voices[0], Settings.current.tts_volume(),
			1.0, Settings.current.rate(), 0, true)


## Taps one of the choices, as a finger would. For tests.
func pick(setting: String, value: Variant) -> void:
	(choices[setting][value] as Button).pressed.emit()


func _on_pick(setting: String, value: Variant) -> void:
	var settings := Settings.current
	if setting == "profile":
		profile_picked.emit(value) # sets text size and reading too
	else:
		settings.set(setting, value)
		settings.save()
	refresh()
	changed.emit()


func _on_volume(value: float) -> void:
	Settings.current.volume = value / 100.0
	Settings.current.save()
	refresh()
	changed.emit()


## The name of one setting, above its choices.
func _name(text: String) -> void:
	var label := _label(text, 40, ARK_DARK, BOLD_FONT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(label)


func _heading(text: String) -> void:
	var label := _label(text, 50, ARK_DARK, TITLE_FONT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(label)


## A row of big buttons, one for each choice; the chosen one is gold.
func _choice(setting: String, options: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	add_child(row)
	choices[setting] = {}
	for option: Array in options:
		var button := _button(option[1])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_pick.bind(setting, option[0]))
		row.add_child(button)
		choices[setting][option[0]] = button


func _paint(button: Button, chosen: bool) -> void:
	var fill := GOLD if chosen else Color(1.0, 0.97, 0.9)
	var normal := _box(fill, 50, 5, GOLD_DEEP if chosen else GOLD, 0)
	normal.content_margin_left = 24
	normal.content_margin_right = 24
	for state in ["normal", "hover", "focus", "pressed"]:
		button.add_theme_stylebox_override(state, normal)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, Color.WHITE if chosen else ARK_DARK)


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 100)
	button.add_theme_font_override("font", BOLD_FONT)
	button.add_theme_font_size_override("font_size", 38)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_paint(button, false)
	return button


## The slider's round handle, big enough for a finger.
func _knob() -> ImageTexture:
	var side := 64
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	var middle := Vector2(side, side) / 2.0
	for y in side:
		for x in side:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(middle)
			var color := ARK_DARK if d > side / 2.0 - 6.0 else CREAM
			color.a = clampf(side / 2.0 - d, 0.0, 1.0)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


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
