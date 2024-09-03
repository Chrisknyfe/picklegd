extends Resource
class_name CustomClassTwo

var baz: float = 4.0
var qux: String = "x"
var volatile_int: int = 3

func __getstate__():
	var state = {
		"1": baz,
		"2": qux
	}
	volatile_int = -1
	return state
	
func __setstate__(state: Dictionary):
	baz = state["1"]
	qux = state["2"]
	volatile_int = 99
