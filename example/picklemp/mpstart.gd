extends Control

var server_scene: String = "res://example/picklemp/mpserver.tscn"
var client_scene: String = "res://example/picklemp/mpclient.tscn"

func _ready() -> void:
	var args = Array(OS.get_cmdline_args())
	print(args)
	var err = OK
	if args.has("listen"):
		print("switch over to server")
		err = get_tree().change_scene_to_file(server_scene)
	elif args.has("join"):
		print("switch over to client")
		err = get_tree().change_scene_to_file(client_scene)
	else:
		print("To run the client or server, pass \"listen\" or \"join\" as an argument.")
	if err != OK:
		push_error("mpstart -> scene load error: ", err)
		
