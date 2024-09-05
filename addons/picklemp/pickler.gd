## A system for serializing and deserializing arbitrary GDScript data.
##
## This is a system for "pickling" GDScript objects to byte arrays, using native
## var_to_bytes plus some code inspection magic. It's meant to make it easy for
## you to send complex data structures (such as large custom classes) over
## the network to multiplayer peers, or to create your own save system.
## @experimental
class_name Pickler
extends Registry

"""Registry of all pickleable objects"""

## Enable strict checking that all dictionary keys are strings.
## This check is required to pickle to JSON.
@export var strict_dictionary_keys = true

## Generate warnings when a class is unrecognized during pickling & unpickling.
@export var warn_on_missing_key = true


class RegisteredClass:
	extends RegisteredBehavior
	var custom_class_def: Object


## Register a custom class that can be pickled with this pickler. Returns the
## RegisteredBehavior object representing this custom class.
func register_custom_class(c: Script):
	"""Register a custom class."""
	var rc = RegisteredClass.new()
	rc.name = c.resource_path
	rc.custom_class_def = c
	return register(rc)


## Returns true if the custom class is registered with this pickler.
func has_custom_class(c: Script):
	return has_by_name(c.resource_path)


## Register a godot engine native class. Returns the
## RegisteredBehavior object representing this native class.
func register_native_class(cls_name: String):
	"""Register a native class. cls_name must match the name returned by instance.class_name()"""
	var rc = RegisteredClass.new()
	rc.name = cls_name
	rc.custom_class_def = null
	return register(rc)


## Returns true if the native class is registered with this pickler.
func has_native_class(cls_name: String):
	return has_by_name(cls_name)


## Pickle the arbitary GDScript data to a JSON string.
func pickle_json(obj) -> String:
	if strict_dictionary_keys:
		return JSON.stringify(pre_pickle(obj))
	push_error("Cannot pickle json without strict key checking")
	return ""


## Unpickle the JSON string to arbitrary GDScript data.
func unpickle_json(json: String):
	if strict_dictionary_keys:
		return post_unpickle(JSON.parse_string(json))
	push_error("Cannot unpickle json without strict key checking")
	return null


## Pickle the arbitary GDScript data to a PackedByteArray.
func pickle(obj) -> PackedByteArray:
	return var_to_bytes(pre_pickle(obj))


## Unpickle the PackedByteArray to arbitrary GDScript data.
func unpickle(buffer: PackedByteArray):
	return post_unpickle(bytes_to_var(buffer))


## Preprocess arbitrary GDScript data, converting classes to appropriate dictionaries.
## Used by `pickle()` and `pickle_json()`.
func pre_pickle(obj):
	"""Recursively pickle all the objects in this arbitrary object hierarchy"""
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
				# key must be a string
				if typeof(key) != TYPE_STRING and strict_dictionary_keys:
					push_error(
						"dict key must be a string: param " + str(key),
						" is of type " + str(typeof(key))
					)
					out = null  # invalidate entire dictionary
				else:
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
			#print("pickling object of type: ", obj)

			var scr = obj.get_script()
			var key = ""
			if scr != null:
				key = scr.resource_path
			else:
				key = obj.get_class()

			if not has_by_name(key):
				if warn_on_missing_key:
					push_warning("Missing object type in picked data: ", key)
				retval = null
			else:
				var rc = get_by_name(key)  # will throw error if this doesn't work

				var dict = {}
				if obj.has_method("__getstate__"):
					# gdlint:ignore = private-method-call
					dict = obj.__getstate__()
				else:
					#print("obj property list: ", obj.get_property_list())
					#print("script property list: ", obj.get_script().get_script_property_list())
					for prop in obj.get_property_list():
						if prop.usage & (PROPERTY_USAGE_SCRIPT_VARIABLE):
							dict[prop.name] = pre_pickle(obj.get(prop.name))
				dict["__class__"] = rc.id
				retval = dict
		# most objects are just passed through
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
			for key in dict:
				dict[key] = post_unpickle(dict[key])

			# enforce string-only dict keys
			var failed_strict = false
			if strict_dictionary_keys:
				for key in dict:
					if typeof(key) != TYPE_STRING:
						push_error(
							"dict key must be a string: " + str(key), " is a " + str(typeof(key))
						)
						failed_strict = true
			if failed_strict:
				retval = null
			elif "__class__" in dict:
				if not has_by_id(dict["__class__"]):
					if warn_on_missing_key:
						push_warning("Missing object type in unpickled data: ", dict["__class__"])
					return null
				var rc: RegisteredClass = get_by_id(dict["__class__"])
				dict.erase("__class__")
				var out = null
				if rc.custom_class_def != null:
					out = rc.custom_class_def.new()
				else:
					out = ClassDB.instantiate(rc.name)
				if out.has_method("__setstate__"):
					# gdlint:ignore = private-method-call
					out.__setstate__(dict)
				else:
					for prop in out.get_property_list():
						if prop.usage & (PROPERTY_USAGE_SCRIPT_VARIABLE):
							out.set(prop.name, dict[prop.name])
				retval = out
			else:
				retval = dict
		TYPE_ARRAY:
			var out = []
			var a: Array = obj as Array
			for element in a:
				out.append(post_unpickle(element))
			retval = out
		# most objects are just passed through
		_:
			retval = obj
	return retval
