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

## Get constructor arguments that will be used at unpickling time
## func __getnewargs__(obj: Object) -> Array
var __getnewargs__: Callable = Callable()

## Get picklable state of the object.
## func __getstate__(obj: Object) -> Dictionary
var __getstate__: Callable = Callable()

## Set state of the object after unpickling.
## func __setstate__(obj: Object, state: Dictionary) -> void
var __setstate__: Callable = Callable()
