class_name HallScreen
extends PanelContainer
## The Hall of the Ark, as in the web prototype (docs/prototype/, hallPanel): Noah and his
## sons, met by finding their names in Word Search (tap a face to learn about them), then
## every word, animal and story event found across every visit. What isn't found yet
## shows as "???".

const TITLE_FONT := preload("res://assets/fonts/Cinzel-700.ttf")
const BODY_FONT := preload("res://assets/fonts/Quicksand-600.ttf")
const BOLD_FONT := preload("res://assets/fonts/Quicksand-700.ttf")

## The prototype's FAMILY_FOLK.
const FAMILY := [
	{"id": "noah", "name": "Noah", "how": "Find NOAH in the Word Search.",
		"blurb": "Noah was a good man who walked close to God. He built the ark just as God told him.",
		"ref": "Genesis 6:9, 22"},
	{"id": "shem", "name": "Shem", "how": "Find SHEM in the Word Search.",
		"blurb": "Shem was one of Noah's three sons. He went into the ark with his wife.", "ref": "Genesis 7:13"},
	{"id": "ham", "name": "Ham", "how": "Find HAM in the Word Search.",
		"blurb": "Ham was one of Noah's three sons. He went into the ark with his wife.", "ref": "Genesis 7:13"},
	{"id": "japheth", "name": "Japheth", "how": "Find JAPHETH in the Word Search.",
		"blurb": "Japheth was one of Noah's three sons. He went into the ark with his wife.", "ref": "Genesis 7:13"},
]
const PORTRAITS := {
	"noah": preload("res://assets/art/hub/family_noah.png"),
	"shem": preload("res://assets/art/hub/family_shem.png"),
	"ham": preload("res://assets/art/hub/family_ham.png"),
	"japheth": preload("res://assets/art/hub/family_japheth.png"),
}
const LOCKED := Color(0, 0, 0, 0.28) ## a face not met yet: just its shadow

const INK := Color("#3A2E22")
const ARK_DARK := Color("#4A3220")
const PANEL := Color("#FDF7E8")
const CREAM := Color("#FBF2DC")
const GOLD := Color("#C9962E")
const MUTED := Color("#6B5640")

var tiles: Dictionary = {} ## person id -> its Button
var info: PanelContainer ## about the face tapped
var info_title: Label
var info_text: Label
var info_ref: Label
var word_chips: HFlowContainer
var animal_chips: HFlowContainer
var event_chips: HFlowContainer


static func family_of(id: String) -> Dictionary:
	for person: Dictionary in FAMILY:
		if person["id"] == id:
			return person
	return {}


## A face, round, in its frame. Locked shows only its shadow.
static func portrait(id: String, side: float, locked: bool) -> Control:
	var frame := PanelContainer.new()
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.set_corner_radius_all(int(side))
	ring.set_border_width_all(6)
	ring.border_color = ARK_DARK
	ring.anti_aliasing = true
	frame.add_theme_stylebox_override("panel", ring)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face := TextureRect.new()
	face.texture = PORTRAITS[id]
	face.custom_minimum_size = Vector2(side, side)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if locked:
		face.self_modulate = LOCKED
	frame.add_child(face)
	return frame


func _ready() -> void:
	add_theme_stylebox_override("panel", _box(PANEL, 48, 6, GOLD, 36))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 26)
	add_child(column)
	column.add_child(_label("Hall of the Ark", 66, ARK_DARK, TITLE_FONT))
	column.add_child(_label("Words, animals, and story events discovered across every visit.", 38, MUTED, BODY_FONT))
	column.add_child(_label("Meet Noah and his sons", 50, ARK_DARK, TITLE_FONT))
	column.add_child(_label("Find their names in the Word Search to meet them. Tap a face to learn about them.", 38, MUTED, BODY_FONT))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	column.add_child(grid)
	for person: Dictionary in FAMILY:
		var tile := Button.new()
		tile.focus_mode = Control.FOCUS_NONE
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.custom_minimum_size = Vector2(0, 250)
		var normal := _box(Color("#FFF8E6"), 30, 4, GOLD, 0)
		var pressed := normal.duplicate() as StyleBoxFlat
		pressed.bg_color = Color("#F2E4C3")
		for state in ["normal", "hover", "focus"]:
			tile.add_theme_stylebox_override(state, normal)
		tile.add_theme_stylebox_override("pressed", pressed)
		tile.pressed.connect(show_person.bind(person["id"]))
		grid.add_child(tile)
		tiles[person["id"]] = tile
	info = PanelContainer.new()
	info.add_theme_stylebox_override("panel", _box(CREAM, 36, 4, GOLD, 30))
	info.visible = false
	column.add_child(info)
	var about := VBoxContainer.new()
	about.add_theme_constant_override("separation", 14)
	info.add_child(about)
	info_title = _label("", 52, ARK_DARK, TITLE_FONT)
	about.add_child(info_title)
	info_text = _label("", 42, INK, BODY_FONT)
	about.add_child(info_text)
	info_ref = _label("", 36, CREAM, BOLD_FONT)
	info_ref.autowrap_mode = TextServer.AUTOWRAP_OFF
	var ref := _box(ARK_DARK, 24, 0, ARK_DARK, 10)
	ref.content_margin_left = 26
	ref.content_margin_right = 26
	info_ref.add_theme_stylebox_override("normal", ref)
	info_ref.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	about.add_child(info_ref)
	column.add_child(_label("Words", 46, ARK_DARK, TITLE_FONT))
	word_chips = _chip_row()
	column.add_child(word_chips)
	column.add_child(_label("Animals", 46, ARK_DARK, TITLE_FONT))
	animal_chips = _chip_row()
	column.add_child(animal_chips)
	column.add_child(_label("Story events", 46, ARK_DARK, TITLE_FONT))
	event_chips = _chip_row()
	column.add_child(event_chips)
	refresh()


## Shows what's been found so far.
func refresh() -> void:
	var settings := Settings.current
	for person: Dictionary in FAMILY:
		var tile: Button = tiles[person["id"]]
		for child in tile.get_children():
			tile.remove_child(child)
			child.queue_free()
		var met: bool = person["id"] in settings.family_met
		var inside := VBoxContainer.new()
		inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inside.alignment = BoxContainer.ALIGNMENT_CENTER
		inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inside.add_child(portrait(person["id"], 150, not met))
		var name_label := _label(person["name"] if met else "???", 36, ARK_DARK, BOLD_FONT)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inside.add_child(name_label)
		tile.add_child(inside)
	info.visible = false
	_fill(word_chips, WordSearch.ROUNDS.reduce(func(all: Array, r: Dictionary) -> Array: return all + r["words"], []).map(
		func(w: Array) -> Array: return [w[1], w[0] in settings.words_found]))
	_fill(animal_chips, MemoryMatch.ANIMALS.map(
		func(a: String) -> Array: return [a.capitalize(), a in settings.animals_found]))
	var events := []
	var seen := {}
	for round_events: Array in StorySequence.ROUNDS:
		for event: Dictionary in round_events:
			if not seen.has(event["id"]):
				seen[event["id"]] = true
				events.append([event["label"], event["id"] in settings.events_found])
	_fill(event_chips, events)


## About one of the family: who they are once met, or how to meet them.
func show_person(id: String) -> void:
	var person := family_of(id)
	var met: bool = id in Settings.current.family_met
	info_title.text = person["name"] if met else "Who could this be?"
	info_text.text = person["blurb"] if met else person["how"]
	info_ref.text = person["ref"]
	info_ref.visible = met
	info.visible = true


func _fill(row: HFlowContainer, items: Array) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for item: Array in items:
		row.add_child(_chip(item[0] if item[1] else "???", item[1]))


func _chip_row() -> HFlowContainer:
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", 14)
	row.add_theme_constant_override("v_separation", 14)
	return row


## Gold when found; a dashed-looking blank when not, as in the prototype's hall-chip.
func _chip(text: String, found: bool) -> Label:
	var chip := _label(text, 36, CREAM if found else Color("#A8957A"), BOLD_FONT)
	chip.autowrap_mode = TextServer.AUTOWRAP_OFF
	var box := _box(GOLD if found else Color("#EFE2CC"), 18, 3, Color("#A8781F") if found else Color("#D9C6A3"), 0)
	box.content_margin_left = 26
	box.content_margin_right = 26
	box.content_margin_top = 10
	box.content_margin_bottom = 12
	chip.add_theme_stylebox_override("normal", box)
	return chip


func _label(text: String, font_size: int, color: Color, font: Font) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


static func _box(fill: Color, radius: int, border: int, border_color: Color, margin: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border)
	box.border_color = border_color
	box.set_content_margin_all(margin)
	box.anti_aliasing = true
	return box
