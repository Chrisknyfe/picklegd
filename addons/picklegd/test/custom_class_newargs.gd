extends Resource
class_name CustomClassNewargs

var foo: String = "bluh"
var baz: float = 4.0
var qux: String = "x"

func _init(new_foo: String):
	foo = new_foo
	
func __getnewargs__() -> Array:
	return [foo]

func __getstate__() -> Dictionary:
	return {"1": baz, "2": qux}
	
func __setstate__(state: Dictionary):
	baz = state["1"]
	qux = state["2"]
