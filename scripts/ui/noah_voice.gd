class_name NoahVoice
extends RefCounted
## Noah speaking in his own voice, like the prototype's speakNoahLine (docs/prototype/):
## a man's voice if the phone has one, a little lower and slower than the reader's.
## "Noah's voice" on the hub turns him quiet. Also how his portrait moves: a bob while he
## talks, a happy wiggle when he cheers (noahCheer), and a shake for "think again".

## Men's voices, best first: the iPhone's own (Daniel comes with every iPhone), then the
## prototype's pickMaleVoice names. Novelty voices like Fred are left out: on an iPhone
## they can stay silent.
const PREFERRED := ["Daniel", "Aaron", "Arthur", "Gordon", "Rishi", "David", "Male"]
const PITCH := 0.82
## If the phone says it has stopped speaking before this share of the line's time has
## passed, the line was never heard: the voice is silent on this phone. It's said again
## the way the reader says things (which works), and Noah keeps that voice from then on.
## (Checked with a timer, not the phone's speech events, which can crash on an iPhone.)
const SILENT_SHARE := 0.4

static var _voice: Variant = null ## the chosen voice's id, once looked up
static var _pitch := PITCH
static var _line := 0 ## counts lines, so only the latest one is checked


## Says text in Noah's voice. Returns about how long that takes, or 0.0 when he stays quiet.
static func say(text: String) -> float:
	if text == "" or not Settings.current.voice_on:
		return 0.0
	var id := voice_id()
	if id == "":
		return 0.0
	_line += 1
	var line := _line
	DisplayServer.tts_speak(text, id, Settings.current.tts_volume(), _pitch, Settings.current.rate(), 0, true)
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and DisplayServer.get_name() != "headless":
		tree.create_timer(seconds_for(text) * SILENT_SHARE).timeout.connect(func() -> void:
			if line == _line and not DisplayServer.tts_is_speaking():
				_fall_back(text))
	return seconds_for(text)


## His voice was silent: say it in the reader's voice, at the reader's pitch, and keep that.
static func _fall_back(text: String) -> void:
	var voices := DisplayServer.tts_get_voices_for_language("en")
	if voices.is_empty() or (voices[0] == _voice and _pitch == 1.0):
		return
	print("Noah's voice %s was silent; using %s" % [_voice, voices[0]])
	_voice = voices[0]
	_pitch = 1.0
	DisplayServer.tts_speak(text, _voice, Settings.current.tts_volume(), _pitch, Settings.current.rate(), 0, true)


## About how long text takes to say (the prototype allows 68 ms a letter).
static func seconds_for(text: String) -> float:
	return 0.4 + text.length() * 0.068


## His portrait bobs while he talks.
static func talk(portrait: Control, seconds: float) -> void:
	if not portrait.is_inside_tree():
		return
	_reset(portrait)
	var tween := portrait.create_tween().set_loops(maxi(1, int(ceil(seconds / 0.6))))
	tween.tween_property(portrait, "scale", Vector2(1.05, 0.97), 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(portrait, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SINE)
	portrait.set_meta("noah_tween", tween)


## A happy wiggle, as in the prototype's noahCheer: bigger and tipped one way, then the other.
static func cheer(portrait: Control) -> void:
	if not portrait.is_inside_tree():
		return
	_reset(portrait)
	var tween := portrait.create_tween().set_parallel()
	tween.tween_property(portrait, "scale", Vector2.ONE * 1.18, 0.21)
	tween.tween_property(portrait, "rotation_degrees", -7.0, 0.21)
	tween.chain().tween_property(portrait, "scale", Vector2.ONE * 1.1, 0.21)
	tween.tween_property(portrait, "rotation_degrees", 6.0, 0.21)
	tween.chain().tween_property(portrait, "scale", Vector2.ONE, 0.28)
	tween.tween_property(portrait, "rotation_degrees", 0.0, 0.28)
	portrait.set_meta("noah_tween", tween)


## A gentle shake of the head, twice.
static func oops(portrait: Control) -> void:
	if not portrait.is_inside_tree():
		return
	_reset(portrait)
	var tween := portrait.create_tween()
	for i in 2:
		tween.tween_property(portrait, "rotation_degrees", -6.0, 0.12)
		tween.tween_property(portrait, "rotation_degrees", 6.0, 0.13)
	tween.tween_property(portrait, "rotation_degrees", 0.0, 0.1)
	portrait.set_meta("noah_tween", tween)


static func _reset(portrait: Control) -> void:
	if portrait.has_meta("noah_tween"):
		var old: Tween = portrait.get_meta("noah_tween")
		if old.is_valid():
			old.kill()
	portrait.pivot_offset = portrait.size / 2.0
	portrait.scale = Vector2.ONE
	portrait.rotation = 0.0


static func voice_id() -> String:
	if _voice == null or _voice == "":
		_voice = _pick() # tried again until the phone lists its voices
	return _voice


static func _pick() -> String:
	var english := DisplayServer.tts_get_voices().filter(func(v: Dictionary) -> bool:
		return str(v.get("language", "")).begins_with("en"))
	# On an iPhone, only its standard voices (not the novelty or downloadable ones).
	var standard := english.filter(func(v: Dictionary) -> bool:
		var id := str(v["id"])
		return id.contains("com.apple.voice.") and not id.contains("super-compact"))
	if not standard.is_empty():
		english = standard
	for wanted: String in PREFERRED:
		for v: Dictionary in english:
			if str(v["name"]).contains(wanted):
				return v["id"]
	for v: Dictionary in english:
		var n := str(v["name"]).to_lower()
		if n.contains("male") and not n.contains("female"):
			return v["id"]
	var chosen: String = english[0]["id"] if not english.is_empty() else ""
	print("Noah's voice: ", chosen)
	return chosen
