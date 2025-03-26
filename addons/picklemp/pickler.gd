## A system for serializing and deserializing arbitrary GDScript data.
##
## This is a system for "pickling" GDScript objects to byte arrays, using native
## var_to_bytes plus some code inspection magic. It's meant to make it easy for
## you to send complex data structures (such as large custom classes) over
## the network to multiplayer peers, or to create your own save system.
## @experimental
class_name Pickler
extends BasePickler

"""A data serializer that keeps a Registry of all pickleable objects"""

var class_registry = Registry.new()


## Register a custom class that can be pickled with this pickler. Returns the
## RegisteredBehavior object representing this custom class.
func register_custom_class(c: Script):
	"""Register a custom class."""
	var rc = RegisteredClass.new()
	rc.name = c.get_global_name()
	rc.custom_class_def = c
	return class_registry.register(rc)


## Returns true if the custom class is registered with this pickler.
func has_custom_class(c: Script):
	return class_registry.has_by_name(c.get_global_name())


## Register a godot engine native class. Returns the
## RegisteredBehavior object representing this native class.
func register_native_class(cls_name: String):
	"""Register a native class. cls_name must match the name returned by instance.class_name()"""
	var rc = RegisteredClass.new()
	rc.name = cls_name
	rc.custom_class_def = null
	return class_registry.register(rc)


## Returns true if the native class is registered with this pickler.
func has_native_class(cls_name: String):
	return class_registry.has_by_name(cls_name)


## Get an ID for this object's class, if the class is registered
func get_object_class_id(obj: Object):
	var scr = obj.get_script()
	var obj_class_name = null
	if scr != null:
		obj_class_name = scr.get_global_name()
	else:
		obj_class_name = obj.get_class()
	if not class_registry.has_by_name(obj_class_name):
		push_warning("Object class type unregistered: ", obj_class_name)
		return null
	var reg: RegisteredBehavior = class_registry.get_by_name(obj_class_name)
	return reg.id


## Create an instance of this class from its ID, if the ID is registered.
func instantiate_from_class_id(id):
	if typeof(id) != TYPE_INT:
		return null
	if not class_registry.has_by_id(id):
		push_warning("Object class ID unregistered: ", id)
		return null
	var reg: RegisteredClass = class_registry.get_by_id(id)
	return reg.instantiate()
