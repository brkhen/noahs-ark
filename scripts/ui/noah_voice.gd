class_name NoahVoice
extends RefCounted
## Noah speaking in his own voice, like the prototype's speakNoahLine (docs/prototype/):
## a man's voice if the phone has one, a little lower and slower than the reader's.
## "Noah's voice" on the hub turns him quiet. Also how his portrait moves: a bob while he
## talks, a happy wiggle when he cheers (noahCheer), and a shake for "think again".

## Men's voices, best first, as the prototype's pickMaleVoice looks for them (plus iPhone ones).
const PREFERRED := ["Daniel", "David", "Alex", "Fred", "Aaron", "Arthur", "Gordon", "Rishi", "Male"]
const PITCH := 0.82
const RATE := 0.9 ## the prototype's slow pace, which every profile starts with

static var _voice: Variant = null ## the chosen voice's id, once looked up


## Says text in Noah's voice. Returns about how long that takes, or 0.0 when he stays quiet.
static func say(text: String) -> float:
	if text == "" or not Settings.current.voice_on:
		return 0.0
	var id := voice_id()
	if id == "":
		return 0.0
	DisplayServer.tts_speak(text, id, 50, PITCH, RATE, 0, true)
	return seconds_for(text)


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
	if _voice == null:
		_voice = _pick()
	return _voice


static func _pick() -> String:
	var english := DisplayServer.tts_get_voices().filter(func(v: Dictionary) -> bool:
		return str(v.get("language", "")).begins_with("en"))
	for wanted: String in PREFERRED:
		for v: Dictionary in english:
			if str(v["name"]).contains(wanted):
				return v["id"]
	for v: Dictionary in english:
		var n := str(v["name"]).to_lower()
		if n.contains("male") and not n.contains("female"):
			return v["id"]
	return english[0]["id"] if not english.is_empty() else ""
