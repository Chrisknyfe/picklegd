class_name RegisteredClass
extends RegisteredBehavior
## A class type registered with a [Pickler].

## This points to a custom class script that can be instantiated.
var custom_class_def: Object

var __getstate__: Callable = Callable()
var __setstate__: Callable = Callable()
var __getnewargs__: Callable = Callable()

func has_getstate():
	return not __getstate__.is_null()
	
func has_setstate():
	return not __setstate__.is_null()
	
func has_getnewargs():
	return not __getnewargs__.is_null()
