@tool
extends EditorPlugin

var pickle_nojar = preload("res://addons/picklemp/pickle_nojar.svg")
var picklejar_pickle_fancy = preload("res://addons/picklemp/picklejar_pickle_fancy.svg")


func _enter_tree():
	add_custom_type(
		"BasePickler",
		"Refcounted",
		preload("res://addons/picklemp/base_pickler.gd"),
		picklejar_pickle_fancy
	)
	add_custom_type(
		"Pickler",
		"BasePickler",
		preload("res://addons/picklemp/pickler.gd"),
		picklejar_pickle_fancy
	)
	add_custom_type(
		"Registry",
		"Refcounted",
		preload("res://addons/picklemp/registry.gd"),
		preload("res://addons/picklemp/picklejar_empty_2.svg")
	)
	add_custom_type(
		"RegisteredBehavior",
		"Resource",
		preload("res://addons/picklemp/registered_behavior.gd"),
		pickle_nojar
	)
	add_custom_type(
		"RegisteredClass",
		"RegisteredBehavior",
		preload("res://addons/picklemp/registered_class.gd"),
		pickle_nojar
	)


func _exit_tree():
	remove_custom_type("BasePickler")
	remove_custom_type("Pickler")
	remove_custom_type("Registry")
	remove_custom_type("RegisteredBehavior")
	remove_custom_type("RegisteredClass")
