class_name MiniGames
extends RefCounted
## The three story games from the web prototype (docs/prototype/), in the order the hub shows them.
## Each one gets its own milestone (see docs/MILESTONE-1.md).

const LIST := [
	{
		"id": "word_search",
		"title": "Word Search",
		"blurb": "Find the words from the story hidden in the letters.",
		"how": "Tap the first and last letter of a word, or drag across it.",
		"color": Color("#C9962E"),
	},
	{
		"id": "memory_match",
		"title": "Memory Match",
		"blurb": "Flip the cards and find the animals that go two by two.",
		"how": "Tap two cards to flip them. Find every matching pair.",
		"color": Color("#B5542E"),
	},
	{
		"id": "story_sequence",
		"title": "Story Sequence",
		"blurb": "Put the story of Noah's Ark back in order.",
		"how": "Tap the events in the order they happened.",
		"color": Color("#5E9C43"),
	},
]


static func find(id: String) -> Dictionary:
	for game: Dictionary in LIST:
		if game["id"] == id:
			return game
	return {}
