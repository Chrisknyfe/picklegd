class_name RegisteredClass
extends RegisteredBehavior
## A class type registered with a [Pickler].

## This points to a custom class script that can be instantiated.
var custom_class_def: Object


## Instantiate an object of this class type. Only global custom classes
## and Godot built-in classes can be instantiated.
func instantiate():
	if custom_class_def != null:
		return custom_class_def.new()
	if ClassDB.class_exists(name):
		return ClassDB.instantiate(name)
	return null
