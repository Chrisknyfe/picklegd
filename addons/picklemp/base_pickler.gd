## A system for serializing and deserializing arbitrary GDScript data.
##
## This is a system for "pickling" GDScript objects to byte arrays, using native
## var_to_bytes plus some code inspection magic. It's meant to make it easy for
## you to send complex data structures (such as large custom classes) over
## the network to multiplayer peers, or to create your own save system.
##
## BasePickler is a base class which allows all class types to be pickled by
## default. This may be insecure.
## @experimental
class_name BasePickler
extends RefCounted

"""A data serializer that can process Objects without executing arbitrary code"""

const PROP_WHITELIST: PropertyUsageFlags = (
	PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_ALWAYS_DUPLICATE
)
const PROP_BLACKLIST: PropertyUsageFlags = (
	PROPERTY_USAGE_INTERNAL
	| PROPERTY_USAGE_NO_INSTANCE_STATE
	| PROPERTY_USAGE_NEVER_DUPLICATE
	| PROPERTY_USAGE_RESOURCE_NOT_PERSISTENT
)

## Generate warnings when a class is unrecognized during pickling & unpickling.
@export var warn_on_missing_class = true


## Pickle the arbitary GDScript data to a string.
func pickle_str(obj) -> String:
	return var_to_str(pre_pickle(obj))


## Unpickle the string to arbitrary GDScript data.
func unpickle_str(s: String):
	return post_unpickle(str_to_var(s))


## Pickle the arbitary GDScript data to a PackedByteArray.
func pickle(obj) -> PackedByteArray:
	return var_to_bytes(pre_pickle(obj))


## Unpickle the PackedByteArray to arbitrary GDScript data.
func unpickle(buffer: PackedByteArray):
	return post_unpickle(bytes_to_var(buffer))


## Get an ID for this object's class. Defaults to returning the obj's class name
func get_object_class_id(obj: Object):
	# return null if you don't want this object pickled
	var scr = obj.get_script()
	if scr != null:
		return scr.get_global_name()
	return obj.get_class()


## Create an instance of this class from its ID. Defaults to treating the id as a class name.
func instantiate_from_class_id(id):
	var str_id = str(id)
	# return null if you don't want to create an object of this type
	if ClassDB.class_exists(str_id):
		return ClassDB.instantiate(str_id)
	for global_class in ProjectSettings.get_global_class_list():
		if global_class["class"] == str_id:
			var scr = load(global_class["path"]) as Script
			return scr.new()
	return null


## Get properties that are safe to pickle for this class.
## Properties such as the Object's "script" should be filtered out.
func get_pickleable_properties(obj: Object):
	var good_props = []
	print("props for class ", get_object_class_id(obj))
	for prop in obj.get_property_list():
		if prop.usage & PROP_WHITELIST and not prop.usage & PROP_BLACKLIST:
			print("keep prop ", prop.name, " :: ", prop.usage)
			good_props.append(prop)
		else:
			print("---- prop ", prop.name, " :: ", prop.usage)
	return good_props


## Preprocess arbitrary GDScript data, converting classes to appropriate dictionaries.
## Used by `pickle()` and `pickle_json()`.
func pre_pickle(obj):
	"""Recursively pickle all the objects in this arbitrary object hierarchy"""
	if obj == null:
		return null
	var retval = null
	match typeof(obj):
		# Rejected types
		TYPE_CALLABLE | TYPE_SIGNAL | TYPE_MAX | TYPE_RID:
			retval = null
		# Collection Types - recursion!
		TYPE_DICTIONARY:
			var out = {}
			var d: Dictionary = obj as Dictionary
			var fail_to_process = false
			for key in d:
				out[key] = pre_pickle(d[key])
			retval = out
		TYPE_ARRAY:
			var out = []
			var a: Array = obj as Array
			for element in a:
				out.append(pre_pickle(element))
			retval = out
		# Objects - only registered objects get pickled
		TYPE_OBJECT:
			var obj_class_id = get_object_class_id(obj)

			if obj_class_id == null:
				if warn_on_missing_class:
					push_warning("Cannot find a class name for object: ", obj)
				retval = null
			else:
				var dict = {}
				if obj.has_method("__getstate__"):
					# gdlint:ignore = private-method-call
					dict = obj.__getstate__()
				else:
					#print("obj property list: ", obj.get_property_list())
					#print("script property list: ", obj.get_script().get_script_property_list())
					for prop in get_pickleable_properties(obj):
						dict[prop.name] = pre_pickle(obj.get(prop.name))
				dict["__class__"] = obj_class_id
				retval = dict
		# most builtin types are just passed through
		_:
			retval = obj
	return retval


## Post-process recently unpickled arbitrary GDScript data, instantiating custom
## classes and native classes from the appropriate dictionaries representing them.
## Used by `unpickle()` and `unpickle_json()`
func post_unpickle(obj):
	"""recursively unpickle all objects in this arbitrary object hierarchy."""
	var retval = null
	match typeof(obj):
		# Rejected types
		TYPE_CALLABLE | TYPE_SIGNAL | TYPE_MAX | TYPE_RID | TYPE_OBJECT:
			retval = null
		# Collection Types - recursion!
		TYPE_DICTIONARY:
			var dict: Dictionary = obj as Dictionary
			if "__class__" in dict:
				var out = instantiate_from_class_id(dict["__class__"])
				if out == null:
					if warn_on_missing_class:
						push_warning("Cannot instantiate from class ID: ", dict["__class__"])
					return null
				dict.erase("__class__")
				if out.has_method("__setstate__"):
					# for users of __setstate__, just unpickle whatever they want,
					# even if it's a bad idea.
					for key in dict:
						dict[key] = post_unpickle(dict[key])
					# gdlint:ignore = private-method-call
					out.__setstate__(dict)
				else:
					# for Objects, only recursively unpickle allowed properties.
					for prop in get_pickleable_properties(out):
						if dict.has(prop.name):
							out.set(prop.name, post_unpickle(dict[prop.name]))
				retval = out
			else:
				# for plain Dictionaries, unpickle recursively
				for key in dict:
					dict[key] = post_unpickle(dict[key])
				retval = dict
		TYPE_ARRAY:
			var out = []
			var a: Array = obj as Array
			for element in a:
				out.append(post_unpickle(element))
			retval = out
		# most builtin types are just passed through
		_:
			retval = obj
	return retval
