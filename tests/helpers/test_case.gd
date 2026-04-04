class_name BubbleTestCase
extends RefCounted

var _failures: Array[String] = []


func run_tests() -> Dictionary:
	_failures.clear()
	var test_names: Array[String] = []
	for method_info in get_method_list():
		var method_name: String = String(method_info["name"])
		if method_name.begins_with("test_"):
			test_names.append(method_name)
	test_names.sort()

	var case_count: int = 0
	for test_name in test_names:
		case_count += 1
		var failures_before: int = _failures.size()
		if has_method("before_each"):
			call("before_each")
		call(test_name)
		if has_method("after_each"):
			call("after_each")
		if _failures.size() == failures_before:
			print("PASS ", get_script().resource_path, " :: ", test_name)

	return {
		"path": get_script().resource_path,
		"cases": case_count,
		"failures": _failures.duplicate(),
	}


func assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_record_failure(message)


func assert_false(condition: bool, message: String) -> void:
	assert_true(not condition, message)


func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_record_failure("%s | expected=%s actual=%s" % [message, _stringify(expected), _stringify(actual)])


func assert_has(collection: Variant, expected_value: Variant, message: String) -> void:
	var found: bool = false
	if collection is Array:
		found = expected_value in collection
	elif collection is Dictionary:
		found = collection.has(expected_value)
	assert_true(found, "%s | missing=%s" % [message, _stringify(expected_value)])


func assert_array_eq_unordered(actual: Array, expected: Array, message: String) -> void:
	var actual_copy: Array = actual.duplicate()
	var expected_copy: Array = expected.duplicate()
	actual_copy.sort()
	expected_copy.sort()
	assert_eq(actual_copy, expected_copy, message)


func _record_failure(message: String) -> void:
	var full_message: String = "%s :: %s" % [get_script().resource_path, message]
	_failures.append(full_message)
	push_error(full_message)


func _stringify(value: Variant) -> String:
	return JSON.stringify(value)
