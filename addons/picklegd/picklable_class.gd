class_name PicklableClass
extends RefCounted
## A class type registered with a [Pickler].
## Contains everything needed to reconstruct an object of this type

#gdlint:disable=class-variable-name

## Class constructor
var constructor: Callable = Callable()

## Number of constructor arguments
var newargs_len: int = 0

## Dictionary of property names that are allowed to be pickled.
var allowed_properties: Dictionary[StringName, bool] = {}

## A copy of this object containing its default values at
## construction time. Useful when Pickler.serialize_defaults is
## set to false.
var default_object: Object = null

## Custom serialization function which gets
## constructor arguments that will be used at unpickling time
## [br]
## func __getnewargs__(obj: Object) -> Array
var __getnewargs__: Callable = Callable()

## Custom serialization function which gets the
## picklable state of the object.
## [br]
## func __getstate__(obj: Object) -> Dictionary
var __getstate__: Callable = Callable()

## Custom serialization function which
## sets the state of the object after unpickling.
## [br]
## func __setstate__(obj: Object, state: Dictionary) -> void
var __setstate__: Callable = Callable()
