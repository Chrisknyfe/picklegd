extends Resource
class_name CustomClassTwo

var baz: float = 4.0
var qux: String = "four point oh"
var volatile_int: int = 3

func __getstate__():
	var state = {
		"baz": baz,
		"qux": qux
	}
	volatile_int = -1
	return state
	
func __setstate__(state: Dictionary):
	baz = state["baz"]
	qux = state["qux"]
	volatile_int = 99
