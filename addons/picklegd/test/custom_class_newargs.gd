class_name CustomClassNewargs
extends RefCounted

var foo: String = "bluh"
var baz: float = 4.0
var qux: String = "x"


func _init(new_foo: String):
	foo = new_foo


# gdlint:ignore=function-name
func __getnewargs__() -> Array:
	return [foo]


# gdlint:ignore=function-name
func __getstate__() -> Dictionary:
	return {"1": baz, "2": qux}


# gdlint:ignore=function-name
func __setstate__(state: Dictionary):
	baz = state["1"]
	qux = state["2"]
