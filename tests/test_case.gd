class_name TestCase
extends RefCounted
## Base for test files. Any method whose name starts with "test_" is run by tests/run_tests.gd.

var failures: Array[String] = []
var current_test := ""
var tree: SceneTree ## set by the runner, for tests that need real scenes


func assert_eq(actual: Variant, expected: Variant, note: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		_fail("expected %s, got %s" % [str(expected), str(actual)], note)


func assert_true(condition: bool, note: String = "") -> void:
	if not condition:
		_fail("expected true", note)


func assert_false(condition: bool, note: String = "") -> void:
	if condition:
		_fail("expected false", note)


func _fail(what: String, note: String) -> void:
	var line := "%s: %s" % [current_test, what]
	if note != "":
		line += " (%s)" % note
	failures.append(line)
