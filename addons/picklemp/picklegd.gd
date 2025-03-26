@tool
extends EditorPlugin

var pickle_nojar = preload("res://addons/picklemp/pickle_nojar.svg")


func _enter_tree():
	add_custom_type(
		"Pickler",
		"Refcounted",
		preload("res://addons/picklemp/pickler.gd"),
		preload("res://addons/picklemp/picklejar_pickle_fancy.svg")
	)
	add_custom_type(
		"Registry",
		"Refcounted",
		preload("res://addons/picklemp/Registry.gd"),
		preload("res://addons/picklemp/picklejar_empty_2.svg")
	)
	add_custom_type(
		"RegisteredBehavior",
		"Resource",
		preload("res://addons/picklemp/RegisteredBehavior.gd"),
		pickle_nojar
	)
	add_custom_type(
		"RegisteredClass",
		"RegisteredBehavior",
		preload("res://addons/picklemp/RegisteredClass.gd"),
		pickle_nojar
	)


func _exit_tree():
	remove_custom_type("Pickler")
