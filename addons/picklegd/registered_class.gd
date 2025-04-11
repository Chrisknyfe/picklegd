class_name RegisteredClass
extends RegisteredBehavior
## A class type registered with a [Pickler].
## Contains everything needed to reconstruct an object of this type

var custom_class_def: Script = null

var constructor: Callable = Callable()
var newargs_len: int = 0

var class_has_getnewargs: bool = false
var class_has_getstate: bool = false
var class_has_setstate: bool = false
var getnewargs: Callable = Callable()
var getstate: Callable = Callable()
var setstate: Callable = Callable()

var allowed_properties: Dictionary = {}
