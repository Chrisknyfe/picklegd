@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type(
		"PicklerRegistry",
		"Node",
		preload("res://addons/picklemp/pickler_registry.gd"),
		preload("res://addons/picklemp/picklejar_search.svg")
	)
	
	add_custom_type(
		"Pickler",
		"Node",
		preload("res://addons/picklemp/pickler.gd"),
		preload("res://addons/picklemp/picklejar_resource.svg")
	)


func _exit_tree():
	remove_custom_type("PicklerRegistry")
	remove_custom_type("Pickler")
