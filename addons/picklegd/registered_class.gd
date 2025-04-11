class_name RegisteredClass
extends RegisteredBehavior
## A class type registered with a [Pickler].
## Contains everything needed to reconstruct an object of this type

var constructor: Callable = Callable()
var newargs_len: int = 0

var getnewargs: Callable = Callable()
var getstate: Callable = Callable()
var setstate: Callable = Callable()

var allowed_properties: Dictionary = {}

var serialize_defaults: bool = true
var default_object: Object = null
