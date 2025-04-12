class_name CustomClassTwo
extends RefCounted

var baz: float = 4.0
var qux: String = "x"
var volatile_int: int = 3


# gdlint:ignore=function-name
func __getstate__() -> Dictionary:
	var state = {"1": baz, "2": qux}
	volatile_int = -1
	return state


# gdlint:ignore=function-name
func __setstate__(state: Dictionary):
	baz = state["1"]
	qux = state["2"]
	volatile_int = 99
