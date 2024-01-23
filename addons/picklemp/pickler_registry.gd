extends Node
class_name PicklerRegistry

"""Registry of all pickleable objects"""

@export var picklers: Dictionary = {}

func register(class_obj, pickler):
	"""Register a pickler for a specific class"""
	picklers[class_obj] = pickler

func pickle(obj):
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
				out[key] = pickle(d[key])
			return out
		TYPE_ARRAY:
			var out = []
			var a : Array = obj as Array
			for element in a:
				out.append(pickle(element))
			return out
		# TODO: objects
		TYPE_OBJECT:
			return {}
		# most objects are just passed through
		_:
			return obj
	pass
	
func unpickle(obj):
	"""recursively unpickle all objects in this arbitrary object hierarchy."""
	pass
