extends Node
class_name PicklerRegistry

@export var picklers: Dictionary = {}

func register(class_obj, pickler):
	"""Register a pickler for a specific class"""
	picklers[class_obj] = pickler

func pickle(obj):
	"""Recursively pickle all the objects in this arbitrary object hierarchy, then JSON serialize."""
	pass
	
func unpickle(obj):
	"""JSON parse, then recursively unpickle all objects in this arbitrary object hierarchy."""
	pass
