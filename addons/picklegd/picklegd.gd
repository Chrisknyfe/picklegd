@tool
extends EditorPlugin

var pickle_nojar = preload("res://addons/picklegd/pickle_nojar.svg")
var picklejar_pickle_fancy = preload("res://addons/picklegd/picklejar_pickle_fancy.svg")
var picklejar_empty = preload("res://addons/picklegd/picklejar_empty_2.svg")


func _enter_tree():
	add_custom_type(
		"PicklableClass",
		"RefCounted",
		preload("res://addons/picklegd/picklable_class.gd"),
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
	remove_custom_type("PicklableClass")
