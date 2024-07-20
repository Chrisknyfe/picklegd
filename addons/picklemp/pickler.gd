extends Registry
class_name Pickler

"""Registry of all pickleable objects"""

@export var preregistry: Array = []
@export var strict_dictionary_keys = true

class RegisteredClass extends RegisteredBehavior:
	var custom_class_def: Object

func register_custom_class(c: Script):
	"""Register a custom class."""
	var rc = RegisteredClass.new()
	rc.name = c.resource_path
	rc.custom_class_def = c
	register(rc)

func register_native_class(cls_name: String):
	"""Register a native class. cls_name must match the name returned by instance.class_name()"""
	var rc = RegisteredClass.new()
	rc.name = cls_name
	rc.custom_class_def = null
	register(rc)
	
func pickle(obj) -> PackedByteArray:
	return var_to_bytes(pre_pickle(obj))

func unpickle(buffer: PackedByteArray):
	return post_unpickle(bytes_to_var(buffer))

func pre_pickle(obj):
	"""Recursively pickle all the objects in this arbitrary object hierarchy"""
	match typeof(obj):
		# Rejected types
		TYPE_CALLABLE | TYPE_SIGNAL | TYPE_MAX | TYPE_RID:
			return null
		# Collection Types - recursion!
		TYPE_DICTIONARY:
			var out = {}
			var d : Dictionary = obj as Dictionary
			for key in d:
				# key must be a string
				if typeof(key) != TYPE_STRING and strict_dictionary_keys:
					push_error("dict key must be a string: " + str(key), " is a " + str(typeof(key)))
					return null
				out[key] = pre_pickle(d[key])
			return out
		TYPE_ARRAY:
			var out = []
			var a : Array = obj as Array
			for element in a:
				out.append(pre_pickle(element))
			return out
		# Objects - only registered objects get pickled
		TYPE_OBJECT:
			#print("pickling object of type: ", obj)
			
			var scr = obj.get_script()
			var key = ""
			if scr != null:
				key = scr.resource_path
			else:
				key = obj.get_class()
			
			# TODO: option to error, warn, or silent 
			var rc = get_by_name(key) # will throw error if this doesn't work 
			
			var dict = {}
			if obj.has_method("__getstate__"):
				dict = obj.__getstate__()
			else:
				#print("obj property list: ", obj.get_property_list())
				#print("script property list: ", obj.get_script().get_script_property_list())
				for prop in obj.get_property_list():
					if prop.usage & (PROPERTY_USAGE_SCRIPT_VARIABLE):
						dict[prop.name] = pre_pickle(obj.get(prop.name))
			dict["__class__"] = rc.id
			return dict
		# most objects are just passed through
		_:
			return obj
	
func post_unpickle(obj):
	"""recursively unpickle all objects in this arbitrary object hierarchy."""
	match typeof(obj):
		# Rejected types
		TYPE_CALLABLE | TYPE_SIGNAL | TYPE_MAX | TYPE_RID | TYPE_OBJECT:
			return null
		# Collection Types - recursion!
		TYPE_DICTIONARY:
			var dict : Dictionary = obj as Dictionary
			for key in dict:
				dict[key] = post_unpickle(dict[key])
				
			# enforce string-only dict keys
			if strict_dictionary_keys:
				for key in dict:
					if typeof(key) != TYPE_STRING:
						push_error("dict key must be a string: " + str(key), " is a " + str(typeof(key)))
						return null 
				
			if "__class__" in dict:
				var rc : RegisteredClass = get_by_id(dict["__class__"])
				dict.erase("__class__")
				var out = null 
				if rc.custom_class_def != null:
					out = rc.custom_class_def.new()
				else:
					out = ClassDB.instantiate(rc.name)
				if out.has_method("__setstate__"):
					out.__setstate__(dict)
				else:
					for prop in out.get_property_list():
						if prop.usage & (PROPERTY_USAGE_SCRIPT_VARIABLE):
							out.set(prop.name, dict[prop.name])
				return out
			else:
				return dict
		TYPE_ARRAY:
			var out = []
			var a : Array = obj as Array
			for element in a:
				out.append(post_unpickle(element))
			return out
		# most objects are just passed through
		_:
			return obj
