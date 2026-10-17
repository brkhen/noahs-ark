class_name MiniGames
extends RefCounted
## The three story games from the web prototype (docs/prototype/), in the order the hub shows them.
## Each one gets its own milestone (see docs/MILESTONE-1.md).

const LIST := [
	{
		"id": "word_search",
		"title": "Word Search",
		"blurb": "Find gopher wood, tools, and the ark's family hidden in the letters.",
		"how": "Tap the first and last letter of a word, or drag across it.",
		"color": Color("#C9962E"),
	},
	{
		"id": "memory_match",
		"title": "Memory Match",
		"blurb": "Flip cards to pair up the animals boarding the ark.",
		"how": "Tap two cards to flip them. Find every matching pair.",
		"color": Color("#B5542E"),
	},
	{
		"id": "story_sequence",
		"title": "Story Sequence",
		"blurb": "Tap the story's events in the order they happened.",
		"how": "Tap the events in the order they happened.",
		"color": Color("#5E9C43"),
	},
]


static func find(id: String) -> Dictionary:
	for game: Dictionary in LIST:
		if game["id"] == id:
			return game
	return {}
