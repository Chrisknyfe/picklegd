@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type(
		"Pickler",
		"Node",
		preload("res://addons/picklemp/pickler.gd"),
		preload("res://addons/picklemp/picklejar_pickle.svg")
	)


func _exit_tree():
	remove_custom_type("Pickler")
