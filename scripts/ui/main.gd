extends Control
## The app's first screen: the hub, with one big button for each story game, and a
## simple screen for each game with a Back button. The games themselves are moved over
## from the web prototype one at a time (docs/MILESTONE-1.md); until then each game
## screen says how it will play.
##
## Portrait only (see docs/PROJECT-SETTINGS.md). Everything sits inside the safe area,
## clear of the notch, the Dynamic Island, and the home bar.

const TITLE_SIZE := 110
const BODY_SIZE := 46 ## large print for young and older eyes
const BUTTON_HEIGHT := 220.0 ## game buttons are big, easy targets
const BACK_SIZE := Vector2(260, 120)
const SIDE_MARGIN := 48.0
const MAX_COLUMN := 900.0 ## on a wide screen (a tablet), keep the column readable

const INK := Color("#3A2E22")
const CREAM := Color("#F5EBD7")
const GOLD := Color("#C9962E")
const ARK_DARK := Color("#4A3220")

## For tests: pretend the device has these safe-area insets (canvas pixels:
## left, top, right, bottom). Null means ask the device.
var safe_insets_override: Variant = null

var current_game := "" ## "" on the hub, otherwise the id of the open game
var backdrop: AlpineBackdrop
var page: MarginContainer ## holds the hub or a game screen, inside the safe area
var hub: VBoxContainer
var game_screen: VBoxContainer
var game_buttons: Dictionary = {} ## game id -> Button
var back_button: Button
var game_title: Label
var game_how: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop = AlpineBackdrop.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	hub.visible = true
	game_screen.visible = false


func open_game(id: String) -> void:
	var game := MiniGames.find(id)
	if game.is_empty():
		return
	current_game = id
	game_title.text = game["title"]
	game_how.text = "%s\n\nThis game is on its way from the prototype." % game["how"]
	hub.visible = false
	game_screen.visible = true


## Android's back gesture and a desktop's Escape key both go back to the hub.
func _unhandled_input(event: InputEvent) -> void:
	if current_game != "" and event.is_action_pressed("ui_cancel"):
		show_hub()
		get_viewport().set_input_as_handled()


func _build_hub() -> void:
	hub = _column()
	page.add_child(hub)
	var title := _label("Noah's Ark", TITLE_SIZE, CREAM)
	title.add_theme_color_override("font_outline_color", ARK_DARK)
	title.add_theme_constant_override("outline_size", 18)
	hub.add_child(title)
	var subtitle := _label("Story Games", BODY_SIZE + 8, INK)
	subtitle.add_theme_stylebox_override("normal", _pill(Color(1.0, 0.97, 0.9, 0.88)))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF # a short line; wrapping would squeeze it to one letter wide
	subtitle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hub.add_child(subtitle)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hub.add_child(spacer)
	for game: Dictionary in MiniGames.LIST:
		var button := _big_button("%s\n%s" % [game["title"], game["blurb"]], game["color"])
		button.pressed.connect(open_game.bind(game["id"]))
		hub.add_child(button)
		game_buttons[game["id"]] = button


func _build_game_screen() -> void:
	game_screen = _column()
	page.add_child(game_screen)
	back_button = Button.new()
	back_button.text = "< Back"
	back_button.custom_minimum_size = BACK_SIZE
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back_button.add_theme_font_size_override("font_size", BODY_SIZE)
	_style_button(back_button, CREAM, INK)
	back_button.pressed.connect(show_hub)
	game_screen.add_child(back_button)
	game_title = _label("", TITLE_SIZE - 20, CREAM)
	game_title.add_theme_color_override("font_outline_color", ARK_DARK)
	game_title.add_theme_constant_override("outline_size", 16)
	game_screen.add_child(game_title)
	game_how = _label("", BODY_SIZE, INK)
	game_how.add_theme_stylebox_override("normal", _pill(Color(1.0, 0.97, 0.9, 0.92)))
	game_screen.add_child(game_how)


func _column() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 32)
	return box


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _big_button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", BODY_SIZE)
	_style_button(button, color, CREAM)
	return button


func _style_button(button: Button, fill: Color, text_color: Color) -> void:
	for state in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = fill.darkened(0.15) if state == "pressed" else fill
		box.set_corner_radius_all(40)
		box.set_border_width_all(6)
		box.border_color = ARK_DARK
		box.shadow_color = Color(0, 0, 0, 0.25)
		box.shadow_size = 8
		box.shadow_offset = Vector2(0, 6)
		box.set_content_margin_all(24)
		button.add_theme_stylebox_override(state, box)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, text_color)


func _pill(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(36)
	box.set_content_margin_all(24)
	return box


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
	page.add_theme_constant_override("margin_top", int(insets.y + 32.0))
	page.add_theme_constant_override("margin_bottom", int(insets.w + 48.0))


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
