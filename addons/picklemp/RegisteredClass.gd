## A class registered with the pickler.
class_name RegisteredClass
extends RegisteredBehavior

var custom_class_def: Object


func instantiate():
	if custom_class_def != null:
		return custom_class_def.new()
	if ClassDB.class_exists(name):
		return ClassDB.instantiate(name)
	return null
