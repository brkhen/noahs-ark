class_name RainbowFinale
extends VBoxContainer
## The scene after the last round of Story Sequence, as in the web prototype
## (docs/prototype/, runRecedeToRainbow and runRainbowFinale): the flood goes down, the ark
## rests on Mount Ararat, Noah sends out the dove, the family and the animals come down
## from the ark, and God sets the rainbow in the clouds.
##
## The scene is the prototype's own animation, recorded into a video by
## tools/record_finale.js. Each part of the story shows (and is read aloud) under the
## picture, with its verse.

signal done ## the player tapped "Back to Hub"

const VIDEO := preload("res://assets/video/rainbow_finale.ogv")
const END_FRAME := preload("res://assets/video/rainbow_finale_end.png")
const TITLE_FONT := preload("res://assets/fonts/Cinzel-700.ttf")
const BODY_FONT := preload("res://assets/fonts/Quicksand-600.ttf")
const BOLD_FONT := preload("res://assets/fonts/Quicksand-700.ttf")

## When each part of the story starts, in seconds into the video (from the recording).
const STORY := [
	{"at": 0.0, "text": "The ark had floated upon the waters for many days.",
		"verse": "Genesis 7:24. The waters flooded the earth for 150 days."},
	{"at": 3.04, "text": "The waters went down, and the ark came to rest on the mountains of Ararat.",
		"verse": "Genesis 8:4. The ark rested on the mountains of Ararat."},
	{"at": 6.25, "text": "Noah sent out a dove to see if the water had dried up.",
		"verse": "Genesis 8:6, 8. Noah sent out a dove from the ark."},
	{"at": 9.54, "text": "Noah, his family, and all the animals came out of the ark.",
		"verse": "Genesis 8:18-19. Noah went out, and his family, and every animal with them."},
	{"at": 18.38, "text": "God set a rainbow in the clouds as a sign of His promise.",
		"verse": "Genesis 9:13. I have set my rainbow in the clouds."},
]
const RAINBOW_AT := 17.67 ## when the rainbow starts to appear, for its chime

const INK := Color("#3A2E22")
const ARK_DARK := Color("#4A3220")
const CREAM := Color("#FBF2DC")
const CARD_EDGE := Color("#C7AD7C")
const GOLD := Color("#C9962E")

var picture: AspectRatioContainer
var video: VideoStreamPlayer
var end_frame: TextureRect
var caption: Label
var verse: Label
var back_button: Button
var part := -1 ## which part of STORY is showing
var _sound: AudioStreamPlayer
var _chimed := false
var _voice := ""


func _ready() -> void:
	add_theme_constant_override("separation", 26)
	picture = AspectRatioContainer.new()
	picture.ratio = float(END_FRAME.get_width()) / END_FRAME.get_height()
	picture.stretch_mode = AspectRatioContainer.STRETCH_WIDTH_CONTROLS_HEIGHT
	add_child(picture)
	var frame := PanelContainer.new()
	var clip := StyleBoxFlat.new()
	clip.bg_color = Color("#7DB9EC")
	clip.set_corner_radius_all(48)
	clip.anti_aliasing = true
	frame.add_theme_stylebox_override("panel", clip)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_ONLY # round the picture's corners
	picture.add_child(frame)
	end_frame = TextureRect.new()
	end_frame.texture = END_FRAME
	end_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	end_frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.add_child(end_frame)
	video = VideoStreamPlayer.new()
	video.stream = VIDEO
	video.expand = true
	video.finished.connect(_on_video_finished)
	frame.add_child(video)
	caption = Label.new()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_override("font", TITLE_FONT)
	caption.add_theme_font_size_override("font_size", 50)
	caption.add_theme_color_override("font_color", ARK_DARK)
	caption.add_theme_stylebox_override("normal", _box(CREAM, 36, 0, CARD_EDGE, 30))
	add_child(caption)
	verse = Label.new()
	verse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	verse.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	verse.add_theme_font_override("font", BODY_FONT)
	verse.add_theme_font_size_override("font_size", 38)
	verse.add_theme_color_override("font_color", CREAM)
	verse.add_theme_stylebox_override("normal", _box(ARK_DARK, 30, 0, ARK_DARK, 24))
	add_child(verse)
	back_button = Button.new()
	back_button.text = "Back to Hub"
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.custom_minimum_size = Vector2(440, 130)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_override("font", BOLD_FONT)
	back_button.add_theme_font_size_override("font_size", 48)
	var normal := _box(Color("#F3E3C0"), 66, 0, CARD_EDGE, 0)
	normal.border_width_bottom = 10
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.border_width_bottom = 4
	for state in ["normal", "hover", "focus"]:
		back_button.add_theme_stylebox_override(state, normal)
	back_button.add_theme_stylebox_override("pressed", pressed)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		back_button.add_theme_color_override(key, ARK_DARK)
	back_button.pressed.connect(func() -> void:
		stop()
		done.emit())
	add_child(back_button)
	_sound = AudioStreamPlayer.new()
	add_child(_sound)
	# The picture is as tall as its width calls for (a box doesn't size itself to a ratio).
	resized.connect(func() -> void:
		picture.custom_minimum_size.y = size.x / picture.ratio)
	var voices := DisplayServer.tts_get_voices_for_language("en")
	if not voices.is_empty():
		_voice = voices[0]


## Starts the scene from the beginning.
func play() -> void:
	part = -1
	_chimed = false
	video.visible = true
	video.stream_position = 0.0
	video.play()
	_show_part(0)


func stop() -> void:
	video.stop()
	if _voice != "":
		DisplayServer.tts_stop()


func _process(_delta: float) -> void:
	if not visible or not video.is_playing():
		return
	show_at(video.stream_position)


## Shows the part of the story for this moment of the video.
func show_at(seconds: float) -> void:
	var now := 0
	for i in STORY.size():
		if seconds >= STORY[i]["at"]:
			now = i
	if now != part:
		_show_part(now)
	if not _chimed and seconds >= RAINBOW_AT:
		_chimed = true
		_rainbow_chime()


func _show_part(index: int) -> void:
	part = index
	caption.text = STORY[index]["text"]
	verse.text = STORY[index]["verse"]
	if _voice != "":
		DisplayServer.tts_speak(caption.text, _voice, 50, 1.0, 0.9, 0, true)


## The video ends on the family under the rainbow; that picture stays.
func _on_video_finished() -> void:
	video.visible = false
	_show_part(STORY.size() - 1)


## Four rising notes as the rainbow appears, like the prototype's.
func _rainbow_chime() -> void:
	var rate := 22050
	var notes := [523.0, 659.0, 784.0, 1046.0]
	var step := int(rate * 0.18)
	var ring := int(rate * 0.65)
	var length := step * (notes.size() - 1) + ring
	var samples := PackedFloat32Array()
	samples.resize(length)
	for n in notes.size():
		for i in ring:
			var t := float(i) / rate
			samples[n * step + i] += sin(TAU * notes[n] * t) * minf(t / 0.05, 1.0) * exp(-t * 7.0) * 0.2
	var data := PackedByteArray()
	data.resize(length * 2)
	for i in length:
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	_sound.stream = wav
	_sound.play()


func _box(fill: Color, radius: int, border: int, border_color: Color, margin: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border)
	box.border_color = border_color
	box.set_content_margin_all(margin)
	box.anti_aliasing = true
	return box
