class_name StoryScene
extends VBoxContainer
## A story scene that plays after a game's last round, as in the web prototype
## (docs/prototype/):
## - rainbow(), after Story Sequence (runRecedeToRainbow and runRainbowFinale): the flood
##   goes down, the ark rests on Mount Ararat, Noah sends out the dove, the family and the
##   animals come down from the ark, and God sets the rainbow in the clouds.
## - stampede(), after Memory Match (runFinale): the animals come to the ark two by two,
##   the family goes in, the door shuts, and the rain begins.
## - building(), after Word Search (runBuildScene): Noah and his sons build the ark while
##   others bring wood, pitch and rope.
##
## Each scene is the prototype's own animation, recorded into a video by
## tools/record_finale.js. Each part of the story shows (and is read aloud) under the
## picture, with its verse. The videos carry the prototype's own sounds (rain, thunder,
## hoofbeats, chimes). Noah calls his sons in his own voice. When a part is being read
## aloud, the picture (and its sounds) waits at the next part until the reading is done,
## so the words always go with what's on screen and never talk over each other. While
## a part is read, the scene's own sounds (the storm, the rain) turn down so the words
## stand out, and come back up after.

signal done ## the player tapped "Back to Hub"
signal ended ## the video played to its end

const TITLE_FONT := preload("res://assets/fonts/Cinzel-700.ttf")
const BODY_FONT := preload("res://assets/fonts/Quicksand-600.ttf")
const BOLD_FONT := preload("res://assets/fonts/Quicksand-700.ttf")

## When each part of the story starts, in seconds into the video (from the recording).
const RAINBOW_STORY := [
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
const BUILDING_STORY := [
	{"at": 0.0, "text": "Noah and his three sons build the ark, while others bring wood, pitch, and rope.",
		"verse": "Genesis 6:14. God tells Noah to build the ark."},
]
const STAMPEDE_STORY := [
	{"at": 0.0, "text": "The animals walked up to the ark, two by two.",
		"verse": "Genesis 7:9. The animals came to Noah two by two."},
	{"at": 9.04, "text": "\u201cShem, Japheth, Ham! Find your wives, gather your things, and enter the ark before the rain comes!\u201d",
		"verse": "Genesis 6:18, 21. You shall go into the ark, you and your sons and your wife and your sons' wives. Take every kind of food."},
	{"at": 32.75, "text": "Then the Lord shut the door behind them.",
		"verse": "Genesis 7:16. The Lord shut him in."},
	{"at": 34.33, "text": "The rain fell hard, and the ark rose upon the waters.",
		"verse": "Genesis 7:17-18. The waters increased and lifted the ark."},
]

const INK := Color("#3A2E22")
const ARK_DARK := Color("#4A3220")
const CREAM := Color("#FBF2DC")
const CARD_EDGE := Color("#C7AD7C")
const GOLD := Color("#C9962E")

var video_stream: VideoStream
var end_texture: Texture2D ## the video's last frame, which stays up after it ends
var story: Array = [] ## the parts, like RAINBOW_STORY

var picture: AspectRatioContainer
var video: VideoStreamPlayer
var end_frame: TextureRect
var caption: Label
var verse: Label
var back_button: Button
var part := -1 ## which part of the story is showing
const QUIET_DB := -16.0 ## the scene's sounds while a part is read
var max_hold := 10.0 ## the longest the picture waits for a reading to finish, in seconds
var _voice := ""
var _held := 0.0 ## how long the picture has waited so far
var _reading := false ## a part was read aloud, and may still be going


static func rainbow() -> StoryScene:
	var scene := StoryScene.new()
	scene.video_stream = load("res://assets/video/rainbow_finale.ogv")
	scene.end_texture = load("res://assets/video/rainbow_finale_end.png")
	scene.story = RAINBOW_STORY
	return scene


static func building() -> StoryScene:
	var scene := StoryScene.new()
	scene.video_stream = load("res://assets/video/ark_building.ogv")
	scene.end_texture = load("res://assets/video/ark_building_end.png")
	scene.story = BUILDING_STORY
	return scene


static func stampede() -> StoryScene:
	var scene := StoryScene.new()
	scene.video_stream = load("res://assets/video/stampede.ogv")
	scene.end_texture = load("res://assets/video/stampede_end.png")
	scene.story = STAMPEDE_STORY
	return scene


func _ready() -> void:
	add_theme_constant_override("separation", 26)
	picture = AspectRatioContainer.new()
	picture.ratio = float(end_texture.get_width()) / end_texture.get_height()
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
	end_frame.texture = end_texture
	end_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	end_frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.add_child(end_frame)
	video = VideoStreamPlayer.new()
	video.stream = video_stream
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
	# The picture is as tall as its width calls for (a box doesn't size itself to a ratio).
	resized.connect(func() -> void:
		picture.custom_minimum_size.y = size.x / picture.ratio)
	var voices := DisplayServer.tts_get_voices_for_language("en")
	if not voices.is_empty():
		_voice = voices[0]


## Starts the scene from the beginning.
func play() -> void:
	part = -1
	video.volume_db = 0.0
	video.visible = true
	video.stream_position = 0.0
	video.play()
	_show_part(0)


func stop() -> void:
	video.stop()
	video.paused = false
	_reading = false
	if _voice != "":
		DisplayServer.tts_stop()


func _process(delta: float) -> void:
	if not visible or not video.is_playing():
		return
	var target := QUIET_DB if _still_reading() else 0.0
	video.volume_db = move_toward(video.volume_db, target, delta * 40.0) # eases down and up
	if video.paused: # waiting for the reading to finish
		_held += delta
		if not _still_reading() or _held >= max_hold:
			video.paused = false
			_show_part(_part_at(video.stream_position))
		return
	var now := _part_at(video.stream_position)
	if now == part:
		return
	if _still_reading():
		video.paused = true
		_held = 0.0
		return
	_show_part(now)


## Shows the part of the story for this moment of the video.
func show_at(seconds: float) -> void:
	var now := _part_at(seconds)
	if now != part:
		_show_part(now)


func _part_at(seconds: float) -> int:
	var now := 0
	for i in story.size():
		if seconds >= story[i]["at"]:
			now = i
	return now


func _still_reading() -> bool:
	_reading = _reading and DisplayServer.tts_is_speaking()
	return _reading


func _show_part(index: int) -> void:
	part = index
	caption.text = story[index]["text"]
	verse.text = story[index]["verse"]
	var text: String = caption.text
	if text.begins_with("\u201c") and NoahVoice.say(text.trim_prefix("\u201c").trim_suffix("\u201d")) > 0.0:
		_reading = true # Noah calls this himself
	elif _voice != "" and Settings.current.read_aloud:
		DisplayServer.tts_speak(text, _voice, Settings.current.tts_volume(), 1.0, Settings.current.rate(), 0, true)
		_reading = true


## When the video ends, its last picture stays (the family under the rainbow, or the ark in the rain).
func _on_video_finished() -> void:
	video.visible = false
	ended.emit()
	if part != story.size() - 1: # not read twice
		_show_part(story.size() - 1)


func _box(fill: Color, radius: int, border: int, border_color: Color, margin: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border)
	box.border_color = border_color
	box.set_content_margin_all(margin)
	box.anti_aliasing = true
	return box
