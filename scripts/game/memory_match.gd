class_name MemoryMatch
extends RefCounted
## Memory Match's rules, without any screen: three rounds of face-down cards (4, then 5,
## then 6 pairs of animals boarding the ark). Turn two cards over; a pair stays face up,
## two different animals turn back over. Same rounds as the prototype
## (docs/prototype/story-games.html, LEVELS).

const ANIMALS := ["dove", "lion", "giraffe", "elephant", "zebra", "monkey"]
const PAIRS := [4, 5, 6] ## pairs in each round

var round_index := 0
var deck: Array = [] ## the animal on each card, in the order they're laid out
var matched: Array = [] ## card indexes that found their pair
var first := -1 ## the card turned over first this turn, or -1
var pending: Array = [] ## two different cards waiting to turn back over
var matches := 0


func start(index: int = 0, rng: RandomNumberGenerator = null) -> void:
	round_index = clampi(index, 0, PAIRS.size() - 1)
	deck.clear()
	for animal: String in ANIMALS.slice(0, PAIRS[round_index]):
		deck.append(animal)
		deck.append(animal)
	if rng == null:
		deck.shuffle()
	else:
		for i in range(deck.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var keep: Variant = deck[i]
			deck[i] = deck[j]
			deck[j] = keep
	matched.clear()
	first = -1
	pending.clear()
	matches = 0


func pairs() -> int:
	return PAIRS[round_index]


## The player tapped card i. Returns what happened:
## "ignored" (it's already face up, or two cards are still turning back),
## "first" (the turn's first card), "match" (a pair!), or "miss" (two different animals;
## call settle() to turn them back over).
func flip(i: int) -> String:
	if not pending.is_empty() or i in matched or i == first or i < 0 or i >= deck.size():
		return "ignored"
	if first == -1:
		first = i
		return "first"
	var other := first
	first = -1
	if deck[other] == deck[i]:
		matched.append(other)
		matched.append(i)
		matches += 1
		return "match"
	pending = [other, i]
	return "miss"


## Turns the missed pair back over. Returns the two card indexes.
func settle() -> Array:
	var cards := pending
	pending = []
	return cards


func is_face_up(i: int) -> bool:
	return i in matched or i == first or i in pending


func round_done() -> bool:
	return matches >= pairs()


func is_last_round() -> bool:
	return round_index == PAIRS.size() - 1


## Mid-round, with a pair found: leaving now would lose it.
func has_progress() -> bool:
	return matches > 0 and not round_done()


func next_round() -> void:
	start(round_index + 1)
