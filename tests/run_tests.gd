extends SceneTree
## Runs every test file and prints a pass/fail summary.
## Run from Terminal:
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path ~/NoahsArk -s res://tests/run_tests.gd

const TEST_FILES := [
	"res://tests/test_main_scene.gd",
	"res://tests/test_story_sequence.gd",
	"res://tests/test_memory_match.gd",
	"res://tests/test_word_search.gd",
	"res://tests/test_settings.gd",
	"res://tests/test_noah.gd",
]


## Counts engine/script errors, so a test that crashes counts as failed.
class ErrorCounter extends Logger:
	var count := 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		count += 1

	func _log_message(_message: String, _error: bool) -> void:
		pass


var _ran := false


## Tests run on the first frame (not in _initialize) so scenes added to the tree get _ready() called.
func _process(_delta: float) -> bool:
	if not _ran:
		_ran = true
		_run_all()
	return false


func _run_all() -> void:
	# Tests keep their settings apart from a real player's, and each starts from none saved.
	Settings.path = "user://test_settings.cfg"
	var errors := ErrorCounter.new()
	OS.add_logger(errors)
	var total := 0
	var passed := 0
	# Optional: NA_TEST_FILTER=part_of_a_file_name (or several, comma-separated) runs just those files.
	var only := OS.get_environment("NA_TEST_FILTER")
	for path: String in TEST_FILES:
		if only != "" and not Array(only.split(",")).any(func(part: String) -> bool: return path.contains(part)):
			continue
		if not ResourceLoader.exists(path):
			print("  SKIP  %s (file not found)" % path.get_file())
			continue
		var script: GDScript = load(path)
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
			var case: TestCase = script.new()
			case.tree = self
			case.current_test = name
			var errors_before := errors.count
			await case.call(name) # tests may wait for frames (layout, input)
			total += 1
			if errors.count > errors_before:
				case.failures.append("%s: script error (see log above)" % name)
			if case.failures.is_empty():
				passed += 1
				print("  PASS  %s :: %s" % [path.get_file(), name])
			else:
				for f in case.failures:
					print("  FAIL  %s :: %s" % [path.get_file(), f])
	print("")
	print("%d of %d tests passed" % [passed, total])
	OS.remove_logger(errors)
	quit(0 if passed == total else 1)
