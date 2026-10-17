class_name Settings
extends RefCounted
## Who's playing and how they like it, kept on the phone between visits (user://), like
## the prototype's saved state (docs/prototype/story-games.html, state and PROFILES).
## Picking who's playing sets up the rest; each setting can still be changed after.

## What each choice on "Who's playing today?" sets up.
const PROFILES := {
	"little": {"read_aloud": true, "voice_on": true, "text_size": "large"},
	"grownup": {"read_aloud": false, "voice_on": true, "text_size": "large"},
	"together": {"read_aloud": true, "voice_on": true, "text_size": "large"},
}
const PROFILE_NAMES := {"little": "Little one", "grownup": "Grown-up", "together": "Together"}
const TEXT_SIZES := ["normal", "large", "xlarge"] ## the Aa button goes round these
const TEXT_SIZE_NAMES := {"normal": "Normal", "large": "Large", "xlarge": "Extra large"}
## How much bigger everything is drawn at each text size. Large is the size the screens
## were laid out at, as in the prototype, where phones start at Large.
const TEXT_SCALE := {"normal": 0.9, "large": 1.0, "xlarge": 1.15}
const GAMES := ["word_search", "memory_match", "story_sequence"]
## Voice speed: how fast the reader and Noah speak (DisplayServer.tts_speak's rate).
const RATES := {"slow": 0.9, "normal": 1.05}
## Words that introduce a person in the Hall of the Ark, as in the prototype's WS_FAMILY.
const FAMILY_WORDS := {"NOAH": "noah", "SHEM": "shem", "HAM": "ham", "JAPHETH": "japheth"}

static var path := "user://settings.cfg" ## tests point this somewhere else
static var current := Settings.new()

var profile := "" ## "", "little", "grownup" or "together"; "" until someone picks
var player_name := ""
var co_play_name := "" ## who's playing with them, if anyone
var text_size := "large"
var read_aloud := false ## read the words on screen aloud
var voice_on := true ## Noah speaks in his own voice (NoahVoice)
var completed: Array = [] ## the games played to the end, by id
var volume := 1.0 ## 0 to 1, for every sound and voice
var speech_rate := "slow" ## "slow" or "normal" (RATES)
var rainbow_seen := false ## the rainbow scene has played: the promise on the hub is unlocked
## Found across every visit, for the Hall of the Ark.
var words_found: Array = [] ## Word Search words, like "NOAH"
var animals_found: Array = [] ## Memory Match animals, like "lion"
var events_found: Array = [] ## Story Sequence event ids, like "build"
var family_met: Array = [] ## "noah", "shem", "ham", "japheth"


## Loads the saved settings into current (or fresh ones, the first time).
static func load_saved() -> Settings:
	current = Settings.new()
	var file := ConfigFile.new()
	if file.load(path) == OK:
		current.profile = file.get_value("player", "profile", "")
		current.player_name = file.get_value("player", "name", "")
		current.co_play_name = file.get_value("player", "co_play_name", "")
		current.text_size = file.get_value("player", "text_size", "large")
		current.read_aloud = file.get_value("player", "read_aloud", false)
		current.voice_on = file.get_value("player", "voice_on", true)
		current.completed = file.get_value("player", "completed", [])
		current.volume = clampf(file.get_value("player", "volume", 1.0), 0.0, 1.0)
		current.speech_rate = file.get_value("player", "speech_rate", "slow")
		current.rainbow_seen = file.get_value("player", "rainbow_seen", false)
		current.words_found = file.get_value("hall", "words", [])
		current.animals_found = file.get_value("hall", "animals", [])
		current.events_found = file.get_value("hall", "events", [])
		current.family_met = file.get_value("hall", "family", [])
	if not RATES.has(current.speech_rate):
		current.speech_rate = "slow"
	if not current.text_size in TEXT_SIZES:
		current.text_size = "large"
	return current


func save() -> void:
	var file := ConfigFile.new()
	file.set_value("player", "profile", profile)
	file.set_value("player", "name", player_name)
	file.set_value("player", "co_play_name", co_play_name)
	file.set_value("player", "text_size", text_size)
	file.set_value("player", "read_aloud", read_aloud)
	file.set_value("player", "voice_on", voice_on)
	file.set_value("player", "completed", completed)
	file.set_value("player", "volume", volume)
	file.set_value("player", "speech_rate", speech_rate)
	file.set_value("player", "rainbow_seen", rainbow_seen)
	file.set_value("hall", "words", words_found)
	file.set_value("hall", "animals", animals_found)
	file.set_value("hall", "events", events_found)
	file.set_value("hall", "family", family_met)
	file.save(path)


func profile_chosen() -> bool:
	return PROFILES.has(profile)


func choose_profile(kind: String) -> void:
	if not PROFILES.has(kind):
		return
	profile = kind
	text_size = PROFILES[kind]["text_size"]
	read_aloud = PROFILES[kind]["read_aloud"]
	voice_on = PROFILES[kind]["voice_on"]
	save()


## The Aa button: Normal, Large, Extra large, and round again.
func next_text_size() -> void:
	text_size = TEXT_SIZES[(TEXT_SIZES.find(text_size) + 1) % TEXT_SIZES.size()]
	save()


func text_scale() -> float:
	return TEXT_SCALE[text_size]


## "Sam", "Sam and Grandpa", or "" when no names are given.
func names() -> String:
	return " and ".join([player_name.strip_edges(), co_play_name.strip_edges()].filter(func(n: String) -> bool: return n != ""))


## Start over: forgets everything (progress, names and choices), as on a first visit.
static func start_over() -> Settings:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	current = Settings.new()
	return current


## The rate to pass to DisplayServer.tts_speak.
func rate() -> float:
	return RATES[speech_rate]


## The volume to pass to DisplayServer.tts_speak (0 to 100). Half is the phone's usual level.
func tts_volume() -> int:
	return int(round(50.0 * volume))


## A word found in Word Search. Returns the person it introduces ("shem"), if met for the
## first time; otherwise "".
func find_word(word: String) -> String:
	var met := ""
	if not word in words_found:
		words_found.append(word)
	var person: String = FAMILY_WORDS.get(word, "")
	if person != "" and not person in family_met:
		family_met.append(person)
		met = person
	save()
	return met


func find_animal(animal: String) -> void:
	if not animal in animals_found:
		animals_found.append(animal)
		save()


func find_event(id: String) -> void:
	if not id in events_found:
		events_found.append(id)
		save()


func see_rainbow() -> void:
	if not rainbow_seen:
		rainbow_seen = true
		save()


## A game was played to the end.
func complete(game: String) -> void:
	if not game in completed:
		completed.append(game)
		save()


func finished_all() -> bool:
	return GAMES.all(func(g: String) -> bool: return g in completed)


## Noah's welcome on the hub.
func greeting() -> String:
	var who := names()
	if finished_all():
		return "You finished the whole story, %s! Well done!" % who if who != "" else "You finished the whole story! Well done!"
	if who != "":
		return "Welcome, %s! Pick a game, and let's help the animals reach the ark." % who
	return "Welcome, friend! Tell me your name, then pick a game."
