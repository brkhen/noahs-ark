class_name StoryGameScreen
extends VBoxContainer
## What the story games share, laid out like the web prototype's (docs/prototype/): the
## round and "No rush" pills with Noah and his speech bubble beside them, then a warm
## gold-edged panel holding the game, with a card over it for "Round Complete!",
## "Get Ready!" and "Leave this round?". Also Noah's chimes and reading aloud.
##
## A game extends this and fills in _build_body(), _start_round(), _round_count(),
## _round_index() and has_progress().

signal leave ## the player chose to go back to the hub (after confirming, mid-round)
signal finished ## the player finished the last round and tapped the last card's button

const TITLE_FONT := preload("res://assets/fonts/Cinzel-700.ttf")
const BODY_FONT := preload("res://assets/fonts/Quicksand-600.ttf")
const BOLD_FONT := preload("res://assets/fonts/Quicksand-700.ttf")
const PROMPT_FONT := preload("res://assets/fonts/Baloo2-700.ttf")
const NOAH := preload("res://assets/art/hub/noah_avatar.png")

## The prototype's words of praise; Noah cheers the first success, then every third.
const PRAISE := ["Wonderful!", "Well done!", "You found it!", "Great job!", "Excellent!", "Keep going!", "Just right!"]

const INK := Color("#3A2E22")
const ARK_DARK := Color("#4A3220")
const CREAM := Color("#FBF2DC")
const CARD_TOP := Color("#FFFCF4")
const CARD_EDGE := Color("#C7AD7C")
const GOLD := Color("#C9962E")
const GOLD_DEEP := Color("#8A6318")

const WORDS_SIZE := 44 ## Noah's words, and words on cards

## Pauses, in seconds. Tests set them to 0.
var complete_delay := 1.2 ## after the round's last success, before "Round Complete!"
var get_ready_seconds := 2.5 ## the "Get Ready!" card between rounds
var bubble_seconds := 2.6 ## how long Noah's words stay up

var round_label: Label
var noah_bubble: PanelContainer
var noah_words: Label
var noah_portrait: Control ## his face beside the bubble; it wiggles when he cheers
var overlay: PanelContainer
var overlay_title: Label
var overlay_text: Label
var overlay_button: Button
var overlay_cancel: Button
var _overlay_action := "" ## what overlay_button does: "continue", "finish", or "leave"
var _sound: AudioStreamPlayer
var _bubble_timer: SceneTreeTimer
var _voice := ""
var _tones := {} ## name -> a sound made once by make_tone()
var _sound_until := 0 ## Time.get_ticks_msec() when the chime now playing ends
var _spoken := 0 ## counts lines, so a line waiting for a chime can be dropped


func _ready() -> void:
	add_theme_constant_override("separation", 24)
	_build_top_row()
	_build_panel()
	_sound = AudioStreamPlayer.new()
	add_child(_sound)
	var voices := DisplayServer.tts_get_voices_for_language("en")
	if not voices.is_empty():
		_voice = voices[0]


## Starts the game again from round 1.
func start() -> void:
	_start_round(0)


## True when leaving now would lose a round in progress.
func has_progress() -> bool:
	return false


## Back was tapped. Leaves right away, unless that would lose progress: then asks first.
func request_leave() -> void:
	if not has_progress():
		_stop_speaking()
		leave.emit()
		return
	_show_overlay("Leave this round?", "Your progress on it will be lost.", "Leave", "leave", true)


## Fills the panel with the game.
func _build_body(_body: VBoxContainer) -> void:
	pass


func _start_round(_index: int) -> void:
	pass


func _round_count() -> int:
	return 1


func _round_index() -> int:
	return 0


## Call at the start of each round.
func _begin_round_ui() -> void:
	round_label.text = "Round %d of %d" % [_round_index() + 1, _round_count()]
	_hide_overlay()
	_say("")


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
			var next := _round_index() + 1
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
	_speak("%s %s" % [title, text], action == "leave") # "Leave?" speaks at once; the others wait their turn


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


## Noah cheers the first success, then every third, like the prototype.
func _cheer(successes: int) -> void:
	if successes == 1 or successes % 3 == 0:
		_say(PRAISE.pick_random())
		NoahVoice.cheer(noah_portrait)


## Runs action after a pause, or right away when the pause is 0 (tests).
func _after(seconds: float, action: Callable) -> void:
	if seconds <= 0.0 or not is_inside_tree():
		action.call()
	else:
		get_tree().create_timer(seconds).timeout.connect(action)


## Reads text aloud when "Read to me" is on; force reads it anyway (a Hear button was tapped).
## A chime that's playing finishes first, so the voice never talks over it.
func _speak(text: String, interrupt := true, force := false) -> void:
	if not (Settings.current.read_aloud or force) or _voice == "" or text == "":
		return
	if interrupt:
		_spoken += 1 # a line that cuts in drops any still waiting
	var wait := (_sound_until - Time.get_ticks_msec()) / 1000.0
	if wait <= 0.0 or not is_inside_tree():
		DisplayServer.tts_speak(text, _voice, Settings.current.tts_volume(), 1.0, Settings.current.rate(), 0, interrupt)
		return
	var line := _spoken
	get_tree().create_timer(wait).timeout.connect(func() -> void:
		if line == _spoken and is_visible_in_tree():
			DisplayServer.tts_speak(text, _voice, Settings.current.tts_volume(), 1.0, Settings.current.rate(), 0, interrupt))


func _stop_speaking() -> void:
	_spoken += 1 # a line still waiting for its chime is dropped too
	if _voice != "":
		DisplayServer.tts_stop()


## A short chime: rising notes when right, two low notes when not (like the prototype's).
func _chime(correct: bool) -> void:
	if correct:
		_play_tone("right", [523.0, 659.0, 784.0])
	else:
		_play_tone("wrong", [330.0, 294.0])


## Plays notes one after another (each ringing on), made once and kept.
func _play_tone(tone_name: String, notes: Array, gap := 0.08, ring := 0.32, fade := 14.0) -> void:
	if not _tones.has(tone_name):
		_tones[tone_name] = make_tone(notes, gap, ring, fade)
	_sound.stream = _tones[tone_name]
	if _sound.is_inside_tree():
		_sound.play()
		_sound_until = Time.get_ticks_msec() + int(((_tones[tone_name] as AudioStreamWAV).get_length() - 0.1) * 1000.0)


## Notes one after another, each ringing on, as a sound to play.
static func make_tone(notes: Array, gap := 0.08, ring := 0.32, fade := 14.0) -> AudioStreamWAV:
	var rate := 22050
	var step := int(rate * gap)
	var ring_samples := int(rate * ring)
	var length := step * (notes.size() - 1) + ring_samples
	var samples := PackedFloat32Array()
	samples.resize(length)
	for n in notes.size():
		for i in ring_samples:
			var t := float(i) / rate
			var env := minf(t / 0.02, 1.0) * exp(-t * fade)
			samples[n * step + i] += sin(TAU * notes[n] * t) * env * 0.22
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
	noah_words = _label("", WORDS_SIZE, INK, BOLD_FONT)
	noah_words.autowrap_mode = TextServer.AUTOWRAP_OFF
	noah_bubble.add_child(noah_words)
	var avatar_frame := PanelContainer.new()
	avatar_frame.add_theme_stylebox_override("panel", _box(CREAM, 90, 8, ARK_DARK, 0))
	avatar_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(avatar_frame)
	noah_portrait = avatar_frame
	var avatar := TextureRect.new()
	avatar.texture = NOAH
	avatar.custom_minimum_size = Vector2(150, 150)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_frame.add_child(avatar)
	_say("")


## The warm panel with the game in it, and the overlay on top.
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
	_build_body(body)
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


## A cream card that is one big button, with a deeper edge along the bottom.
func _card_button() -> Button:
	var card := Button.new()
	card.focus_mode = Control.FOCUS_NONE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	return card


## A cream pill button with a gold edge, like "Hear the choices".
func _soft_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 120)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_override("font", BOLD_FONT)
	button.add_theme_font_size_override("font_size", WORDS_SIZE)
	var normal := _box(CREAM, 60, 6, GOLD, 0)
	normal.content_margin_left = 60
	normal.content_margin_right = 60
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = CREAM.darkened(0.06)
	for state in ["normal", "hover", "focus"]:
		button.add_theme_stylebox_override(state, normal)
	button.add_theme_stylebox_override("pressed", pressed)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, ARK_DARK)
	return button


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
