extends Control
## The app's first screen: the hub, laid out like the web prototype's (docs/prototype/).
## The painted ark scene and title at the top, Noah's welcome, then a card for each story
## game. Tapping anywhere on a card opens that game. The games are moved over from the
## prototype one at a time (docs/MILESTONE-1.md): Story Sequence is here; until the others
## arrive, their screens say how they will play.
##
## Portrait only (see docs/PROJECT-SETTINGS.md). Everything sits inside the safe area,
## clear of the notch, the Dynamic Island, and the home bar.

const TITLE_FONT := preload("res://assets/fonts/Cinzel-700.ttf")
const BODY_FONT := preload("res://assets/fonts/Quicksand-600.ttf")
const BOLD_FONT := preload("res://assets/fonts/Quicksand-700.ttf")
const BACKDROP := preload("res://assets/art/hub/backdrop.png")
const HERO := preload("res://assets/art/hub/hero.png")
const NOAH := preload("res://assets/art/hub/noah_avatar.png")
const BANNERS := {
	"word_search": preload("res://assets/art/hub/banner_word_search.png"),
	"memory_match": preload("res://assets/art/hub/banner_memory_match.png"),
	"story_sequence": preload("res://assets/art/hub/banner_story_sequence.png"),
}

const BODY_SIZE := 44 ## large print for young and older eyes
const SMALL_SIZE := 36
const CARD_TITLE_SIZE := 50
const BACK_SIZE := Vector2(260, 120)
const SIDE_MARGIN := 28.0
const MAX_COLUMN := 960.0 ## on a wide screen (a tablet), keep the column readable
const GAP := 28

## The prototype's colors.
const INK := Color("#3A2E22")
const CREAM := Color("#F5EBD7")
const PANEL := Color("#FDF7E8")
const CARD := Color("#F2E4C3")
const CARD_EDGE := Color("#C7AD7C")
const GOLD := Color("#C9962E")
const GOLD_DEEP := Color("#8A6318")
const TITLE_GOLD := Color("#FFD866")
const TITLE_EDGE := Color("#5A3A12")
const ARK_DARK := Color("#4A3220")
const MUTED := Color("#6B5640") ## darker than the prototype's #8A7256, for easier reading

## For tests: pretend the device has these safe-area insets (canvas pixels:
## left, top, right, bottom). Null means ask the device.
var safe_insets_override: Variant = null

var current_game := "" ## "" on the hub, otherwise the id of the open game
var backdrop: TextureRect
var page: MarginContainer ## holds the hub or a game screen, inside the safe area
var hub_scroll: ScrollContainer
var hub: VBoxContainer
var hub_bottom: Control ## room below the last card, so it can scroll clear of the home bar
var hero_title: Label
var game_scroll: ScrollContainer
var game_screen: VBoxContainer
var game_bottom: Control ## like hub_bottom, for the game screen
var placeholder: PanelContainer ## the "on its way" page for games not moved over yet
var story: StorySequenceScreen
var memory: MemoryMatchScreen
var words: WordSearchScreen
var finale: StoryScene ## the flood and rainbow scene after Story Sequence's last round
var stampede: StoryScene ## the animals boarding the ark, after Memory Match's last round
var building: StoryScene ## the ark being built, after Word Search's last round
var games: Dictionary = {} ## game id -> its screen, for the games moved over so far
var scenes: Dictionary = {} ## game id -> the story scene after its last round
var game_buttons: Dictionary = {} ## game id -> the Button that is its whole card
var back_button: Button
var game_title: Label
var game_how: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = _make_theme()
	var sky := ColorRect.new() # shows through below the backdrop on very tall screens
	sky.color = Color("#E3ECDD")
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	backdrop = TextureRect.new()
	backdrop.texture = BACKDROP
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	page = MarginContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	_build_hub()
	_build_game_screen()
	resized.connect(_layout)
	_layout()
	show_hub()


func show_hub() -> void:
	current_game = ""
	_hide_scenes()
	hub_scroll.visible = true
	game_scroll.visible = false
	game_screen.visible = false


func open_game(id: String) -> void:
	var game := MiniGames.find(id)
	if game.is_empty():
		return
	current_game = id
	game_title.text = game["title"]
	game_how.text = "%s\n\nThis game is on its way from the prototype." % game["how"]
	_hide_scenes()
	for key: String in games:
		games[key].visible = key == id
	placeholder.visible = not games.has(id)
	if games.has(id):
		games[id].start()
	hub_scroll.visible = false
	game_scroll.visible = true
	game_screen.visible = true
	game_scroll.scroll_vertical = 0


## After a game's last round, its story scene: after Story Sequence the flood goes down
## and the rainbow appears; after Memory Match the animals board the ark; after Word Search
## the ark is built.
func show_finale() -> void:
	if not scenes.has(current_game):
		show_hub()
		return
	games[current_game].visible = false
	var scene: StoryScene = scenes[current_game]
	scene.visible = true
	game_scroll.scroll_vertical = 0
	scene.play()


func _hide_scenes() -> void:
	for scene: StoryScene in scenes.values():
		scene.stop()
		scene.visible = false


## Back: a game in the middle of a round asks first.
func go_back() -> void:
	if scenes.has(current_game) and (scenes[current_game] as StoryScene).visible:
		show_hub()
	elif games.has(current_game):
		games[current_game].request_leave()
	else:
		show_hub()


## Android's back gesture and a desktop's Escape key both go back to the hub.
func _unhandled_input(event: InputEvent) -> void:
	if current_game != "" and event.is_action_pressed("ui_cancel"):
		go_back()
		get_viewport().set_input_as_handled()


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = BODY_FONT
	t.default_font_size = BODY_SIZE
	t.set_color("font_color", "Label", INK)
	return t


func _build_hub() -> void:
	hub_scroll = ScrollContainer.new()
	hub_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hub_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	hub_scroll.scroll_deadzone = 24 # a small drag scrolls; a tap still taps
	page.add_child(hub_scroll)
	hub = _column()
	hub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hub_scroll.add_child(hub)
	hub.add_child(_build_hero())
	hub.add_child(_build_noah_says())
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL, 48, 6, GOLD, 30))
	hub.add_child(panel)
	var cards := _column()
	panel.add_child(cards)
	for game: Dictionary in MiniGames.LIST:
		var card := _game_card(game)
		cards.add_child(card)
		game_buttons[game["id"]] = card
	hub_bottom = Control.new()
	hub.add_child(hub_bottom)


## The painted ark scene in a gold-edged frame, with the title across its sky.
func _build_hero() -> Control:
	var art := TextureRect.new()
	art.texture = HERO
	art.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL # as tall as its width calls for
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Darken the sky a little behind the title so it reads, like the prototype.
	var shade := TextureRect.new()
	var fade := GradientTexture2D.new()
	fade.fill_from = Vector2(0, 0)
	fade.fill_to = Vector2(0, 0.42)
	fade.gradient = Gradient.new()
	fade.gradient.set_color(0, Color(0.08, 0.17, 0.34, 0.4))
	fade.gradient.set_color(1, Color(0.08, 0.17, 0.34, 0.0))
	shade.texture = fade
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(shade)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	var border := Panel.new()
	var edge := StyleBoxFlat.new()
	edge.draw_center = false
	edge.set_corner_radius_all(54)
	edge.set_border_width_all(7)
	edge.border_color = ARK_DARK
	edge.shadow_color = Color(0.08, 0.12, 0.2, 0.35)
	edge.shadow_size = 18
	edge.shadow_offset = Vector2(0, 10)
	border.add_theme_stylebox_override("panel", edge)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(border)
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_title = Label.new()
	hero_title.text = "Noah's Ark: Story Games"
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_title.add_theme_font_override("font", TITLE_FONT)
	hero_title.add_theme_color_override("font_color", TITLE_GOLD)
	hero_title.add_theme_color_override("font_outline_color", TITLE_EDGE)
	hero_title.add_theme_constant_override("outline_size", 12)
	hero_title.add_theme_color_override("font_shadow_color", Color(0.05, 0.08, 0.15, 0.55))
	hero_title.add_theme_constant_override("shadow_offset_y", 5)
	art.add_child(hero_title)
	hero_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hero_title.offset_top = 22
	art.resized.connect(func() -> void:
		# Fit the title on one line across the picture.
		hero_title.add_theme_font_size_override("font_size", int(clampf(art.size.x / 15.5, 30.0, 76.0))))
	return art


## Noah's portrait and his welcome in a speech bubble.
func _build_noah_says() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var avatar := TextureRect.new()
	avatar.texture = NOAH
	avatar.custom_minimum_size = Vector2(170, 170)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(avatar)
	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.add_theme_stylebox_override("panel", _box(Color(1.0, 0.98, 0.93, 0.95), 40, 0, ARK_DARK, 28))
	row.add_child(bubble)
	var says := _label("Welcome, friend! Pick a game to play.", BODY_SIZE, INK, BOLD_FONT)
	says.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	bubble.add_child(says)
	return row


## One game's card: its little picture, its name, what it is, and a Play pill.
## The whole card is one big button, so a tap anywhere on it starts the game.
func _game_card(game: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 300)
	card.focus_mode = Control.FOCUS_NONE
	var normal := _box(CARD, 44, 0, CARD_EDGE, 26)
	normal.border_width_bottom = 10
	normal.shadow_color = Color(0.29, 0.2, 0.13, 0.22)
	normal.shadow_size = 12
	normal.shadow_offset = Vector2(0, 8)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = CARD.darkened(0.06)
	pressed.border_width_bottom = 4
	for state in ["normal", "hover", "focus", "disabled"]:
		card.add_theme_stylebox_override(state, normal)
	card.add_theme_stylebox_override("pressed", pressed)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 26
	row.offset_top = 26
	row.offset_right = -26
	row.offset_bottom = -32
	card.add_child(row)
	var banner := TextureRect.new()
	banner.texture = BANNERS[game["id"]]
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.custom_minimum_size = Vector2(330, 0)
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.size_flags_stretch_ratio = 0.9
	row.add_child(banner)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", 10)
	row.add_child(text)
	var title := _label(game["title"], CARD_TITLE_SIZE, ARK_DARK, TITLE_FONT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text.add_child(title)
	var blurb := _label(game["blurb"], SMALL_SIZE, MUTED)
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text.add_child(blurb)
	var play := _label("Play", BODY_SIZE, ARK_DARK, BOLD_FONT)
	play.autowrap_mode = TextServer.AUTOWRAP_OFF
	var pill := _box(GOLD, 60, 0, GOLD_DEEP, 0)
	pill.content_margin_left = 54
	pill.content_margin_right = 54
	pill.content_margin_top = 12
	pill.content_margin_bottom = 14
	pill.border_width_bottom = 7
	play.add_theme_stylebox_override("normal", pill)
	play.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	text.add_child(play)
	_ignore_mouse(row) # taps go to the card itself
	# The card grows to fit its text (bigger text sizes wrap to more lines).
	var fit := func() -> void:
		card.custom_minimum_size.y = maxf(300.0, row.get_combined_minimum_size().y + 58.0)
	row.minimum_size_changed.connect(fit)
	card.pressed.connect(open_game.bind(game["id"]))
	return card


func _build_game_screen() -> void:
	game_scroll = ScrollContainer.new()
	game_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	game_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	game_scroll.scroll_deadzone = 24
	page.add_child(game_scroll)
	game_screen = _column()
	game_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_scroll.add_child(game_screen)
	back_button = Button.new()
	back_button.text = "< Back"
	back_button.custom_minimum_size = BACK_SIZE
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back_button.add_theme_font_override("font", BOLD_FONT)
	back_button.add_theme_font_size_override("font_size", BODY_SIZE)
	var normal := _box(Color("#FBF2DC"), 60, 4, ARK_DARK, 20)
	normal.border_width_bottom = 9
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.border_width_bottom = 4
	for state in ["normal", "hover", "focus"]:
		back_button.add_theme_stylebox_override(state, normal)
	back_button.add_theme_stylebox_override("pressed", pressed)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		back_button.add_theme_color_override(key, ARK_DARK)
	back_button.pressed.connect(go_back)
	game_screen.add_child(back_button)
	placeholder = PanelContainer.new()
	placeholder.add_theme_stylebox_override("panel", _box(PANEL, 48, 6, GOLD, 40))
	game_screen.add_child(placeholder)
	var inside := _column()
	placeholder.add_child(inside)
	game_title = _label("", 72, ARK_DARK, TITLE_FONT)
	inside.add_child(game_title)
	game_how = _label("", BODY_SIZE, INK)
	inside.add_child(game_how)
	story = StorySequenceScreen.new()
	memory = MemoryMatchScreen.new()
	words = WordSearchScreen.new()
	finale = StoryScene.rainbow()
	stampede = StoryScene.stampede()
	building = StoryScene.building()
	games = {"story_sequence": story, "memory_match": memory, "word_search": words}
	scenes = {"story_sequence": finale, "memory_match": stampede, "word_search": building}
	for screen: StoryGameScreen in games.values():
		screen.visible = false
		screen.leave.connect(show_hub)
		screen.finished.connect(show_finale)
		game_screen.add_child(screen)
	for scene: StoryScene in scenes.values():
		scene.visible = false
		scene.done.connect(show_hub)
		game_screen.add_child(scene)
	game_bottom = Control.new()
	game_screen.add_child(game_bottom)


func _column() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", GAP)
	return box


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


func _ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)


## Keep the page inside the safe area, with a readable column on wide screens.
func _layout() -> void:
	if page == null:
		return
	var insets := _safe_insets()
	var screen := get_viewport_rect().size
	var usable := screen.x - insets.x - insets.z - SIDE_MARGIN * 2.0
	var extra := maxf(0.0, (usable - MAX_COLUMN) / 2.0)
	page.add_theme_constant_override("margin_left", int(insets.x + SIDE_MARGIN + extra))
	page.add_theme_constant_override("margin_right", int(insets.z + SIDE_MARGIN + extra))
	page.add_theme_constant_override("margin_top", int(insets.y + 20.0))
	# The hub scrolls right to the bottom edge (behind the home bar) instead of stopping
	# short of it; the space below the last card lets it scroll clear of the bar.
	page.add_theme_constant_override("margin_bottom", 0)
	hub_bottom.custom_minimum_size.y = insets.w + 20.0
	game_bottom.custom_minimum_size.y = insets.w + 20.0


## The safe area in canvas pixels: left, top, right, bottom.
func _safe_insets() -> Vector4:
	if safe_insets_override != null:
		return safe_insets_override
	if OS.has_feature("web"):
		return _web_safe_insets()
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		var window := DisplayServer.window_get_size()
		if window.x > 0 and window.y > 0 and safe.size.y > 0:
			var to_canvas := get_viewport_rect().size.y / float(window.y)
			return Vector4(safe.position.x, safe.position.y, window.x - safe.end.x, window.y - safe.end.y) * to_canvas
	return Vector4.ZERO


## In a phone browser the page fills the screen (under the notch and home bar too), so ask
## the browser for those margins (CSS env(safe-area-inset-*)) and turn them into canvas pixels.
func _web_safe_insets() -> Vector4:
	var js := "(function(){var d=document.getElementById('bd-safe');if(!d){d=document.createElement('div');d.id='bd-safe';" + \
			"d.style.cssText='position:fixed;left:0;top:0;width:0;height:0;visibility:hidden;padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)';" + \
			"document.body.appendChild(d);}var s=getComputedStyle(d);return [parseFloat(s.paddingLeft)||0,parseFloat(s.paddingTop)||0," + \
			"parseFloat(s.paddingRight)||0,parseFloat(s.paddingBottom)||0,window.innerHeight].join(',');})()"
	var raw: Variant = JavaScriptBridge.eval(js, true)
	if not raw is String:
		return Vector4.ZERO
	var parts := (raw as String).split(",")
	if parts.size() < 5 or float(parts[4]) <= 0.0:
		return Vector4.ZERO
	var to_canvas := get_viewport_rect().size.y / float(parts[4])
	return Vector4(float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3])) * to_canvas


## For tests: re-run the layout after changing safe_insets_override.
func relayout() -> void:
	_layout()
