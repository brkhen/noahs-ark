class_name StorySequence
extends RefCounted
## Story Sequence's rules, without any screen: three rounds of story events, each longer
## than the last, to be tapped in the order they happened. Same rounds as the prototype
## (docs/prototype/story-games.html, SEQ_ROUNDS).

## Each event: a unique id, the picture it shows, and its words.
const ROUNDS := [
	[
		{"id": "build", "art": "build", "label": "God tells Noah to build the ark"},
		{"id": "board1", "art": "board", "label": "The animals enter the ark"},
		{"id": "rain1", "art": "rain", "label": "The rain begins to fall"},
		{"id": "land1", "art": "land", "label": "The ark comes to rest on dry land"},
	],
	[
		{"id": "build", "art": "build", "label": "God tells Noah to build the ark"},
		{"id": "board2", "art": "board", "label": "Noah's family and the animals board"},
		{"id": "shut", "art": "shut", "label": "The Lord shuts the door"},
		{"id": "rain2", "art": "rain", "label": "Rain falls for forty days and nights"},
		{"id": "land2", "art": "land", "label": "The ark rests on Mount Ararat"},
	],
	[
		{"id": "build", "art": "build", "label": "God tells Noah to build the ark"},
		{"id": "board3", "art": "board", "label": "Noah's family and the animals board"},
		{"id": "shut3", "art": "shut", "label": "The Lord shuts the door"},
		{"id": "rain3", "art": "rain", "label": "Rain falls forty days and nights"},
		{"id": "dove", "art": "dove", "label": "Noah sends out a dove"},
		{"id": "rainbow", "art": "rainbow", "label": "A rainbow appears, God's promise"},
	],
]

var round_index := 0
var placed := 0 ## how many of this round's events are in the timeline so far


func start(index: int = 0) -> void:
	round_index = clampi(index, 0, ROUNDS.size() - 1)
	placed = 0


func events() -> Array:
	return ROUNDS[round_index]


## This round's events in a random order, for the cards.
func shuffled_events(rng: RandomNumberGenerator = null) -> Array:
	var list := events().duplicate()
	if rng == null:
		list.shuffle()
	else:
		for i in range(list.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var keep: Variant = list[i]
			list[i] = list[j]
			list[j] = keep
	return list


## The player tapped an event. True if it is the one that comes next (and it is placed).
func tap(id: String) -> bool:
	if round_done() or events()[placed]["id"] != id:
		return false
	placed += 1
	return true


func round_done() -> bool:
	return placed >= events().size()


func is_last_round() -> bool:
	return round_index == ROUNDS.size() - 1


## Mid-round, with something placed: leaving now would lose it.
func has_progress() -> bool:
	return placed > 0 and not round_done()


func next_round() -> void:
	start(round_index + 1)
