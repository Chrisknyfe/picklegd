@tool
extends EditorPlugin

var pickle_nojar = preload("res://addons/picklegd/pickle_nojar.svg")
var picklejar_pickle_fancy = preload("res://addons/picklegd/picklejar_pickle_fancy.svg")


func _enter_tree():
	add_custom_type(
		"Registry",
		"Refcounted",
		preload("res://addons/picklegd/registry.gd"),
		preload("res://addons/picklegd/picklejar_empty_2.svg")
	)
	add_custom_type(
		"RegisteredBehavior",
		"Resource",
		preload("res://addons/picklegd/registered_behavior.gd"),
		pickle_nojar
	)
	add_custom_type(
		"RegisteredClass",
		"RegisteredBehavior",
		preload("res://addons/picklegd/registered_class.gd"),
		pickle_nojar
	)
	add_custom_type(
		"Pickler",
		"RefCounted",
		preload("res://addons/picklegd/pickler.gd"),
		picklejar_pickle_fancy
	)


func _exit_tree():
	remove_custom_type("Pickler")
	remove_custom_type("Registry")
	remove_custom_type("RegisteredBehavior")
	remove_custom_type("RegisteredClass")
