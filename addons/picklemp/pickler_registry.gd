extends Registry
class_name PicklerRegistry

"""Registry of all pickleable objects"""

func register_class(c: Object, p: Object=null):
	var pt = PicklerType.new()
	pt.name = c.resource_path
	pt.class_def = c
	pt.class_pickler = p
	register(pt)
	
	
	

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
			print("pickling object of type: ", obj)
			var path = obj.get_script().resource_path
			# TODO: option to error, warn, or silent 
			var pt = get_by_name(path) # will throw error if this doesn't work 
			
			# the following will become the default pickler
			var out = {}
			out["__class__"] = pt.id
			print("name | class_name | type | hint | hint_string | usage")
			for prop in obj.get_property_list():
				if prop.usage & (PROPERTY_USAGE_SCRIPT_VARIABLE):
					print(prop.name, " | ", prop.class_name, " | ", prop.type, " | ", prop.hint, " | ", prop.hint_string, " | ", prop.usage)
					out[prop.name] = obj.get(prop.name)
				else:
					print(prop.name, " [SKIP]")
			print("now for the class itself...")
			for prop in pt.class_def.get_property_list():
				if prop.usage & (PROPERTY_USAGE_SCRIPT_VARIABLE):
					print(prop.name, " | ", prop.class_name, " | ", prop.type, " | ", prop.hint, " | ", prop.hint_string, " | ", prop.usage)
				else:
					print(prop.name, " [SKIP]")
			
			return out
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
			var d : Dictionary = obj as Dictionary
			if "__class__" in d:
				var pt : PicklerType = get_by_id(d["__class__"])
				var out = pt.class_def.new()
				for prop in out.get_property_list():
					if prop.usage & (PROPERTY_USAGE_SCRIPT_VARIABLE):
						out.set(prop.name, d[prop.name])
				return out
			else:
				var out = {}
				for key in d:
					out[key] = post_unpickle(d[key])
				return out
		TYPE_ARRAY:
			var out = []
			var a : Array = obj as Array
			for element in a:
				out.append(post_unpickle(element))
			return out
		# most objects are just passed through
		_:
			return obj
