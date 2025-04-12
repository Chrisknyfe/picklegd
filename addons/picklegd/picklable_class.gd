class_name PicklableClass
extends RegisteredObject
## A class type registered with a [Pickler].
## Contains everything needed to reconstruct an object of this type

var constructor: Callable = Callable()
var newargs_len: int = 0

## func __getnewargs__(obj: Object) -> Array
var __getnewargs__: Callable = Callable()

## func __getstate__(obj: Object) -> Dictionary
var __getstate__: Callable = Callable()

## func __setstate__(obj: Object, state: Dictionary) -> void
var __setstate__: Callable = Callable()

var allowed_properties: Dictionary = {}

var serialize_defaults: bool = true
var default_object: Object = null
