extends Control

const DEFAULT_PORT = 28960
const MAX_CLIENTS = 50
const IPADDR = "127.0.0.1"

var num_clients = 0

func _ready() -> void:
	var args = Array(OS.get_cmdline_args())
	print(args)
	if args.has("listen"):
		print("start a listen server")
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)

		var server = ENetMultiplayerPeer.new()
		server.create_server(DEFAULT_PORT, MAX_CLIENTS)
		multiplayer.set_multiplayer_peer(server)
		$Label.text = "Server is listening"
		$TextureRect.modulate = Color.BLUE
		
	elif args.has("join"):
		print("create a client")
		multiplayer.connected_to_server.connect(self._connected_to_server)
		multiplayer.server_disconnected.connect(self._server_disconnected)
		multiplayer.connection_failed.connect(self._connection_failed)
		var client = ENetMultiplayerPeer.new()
		client.create_client(IPADDR, DEFAULT_PORT)
		multiplayer.set_multiplayer_peer(client)
		$Label.text = "created a client!"
		$TextureRect.modulate = Color.ORANGE
	else:
		print("To run the client or server, pass \"listen\" or \"join\" as an argument.")


		

func _connected_to_server():
	print("Successfully connected to server")
	$Label.text = "client connected!"


func _server_disconnected():
	print("Disconnected from server")
	$Label.text = "client disconnected."


func _connection_failed():
	print("Connection to server failed!")
	$Label.text = "client connection failed."

func _peer_disconnected(id):
	print("Peer " + str(id) + " has disconnected")
	num_clients -= 1
	$Label.text = "server: number of clients: %d" % num_clients

func _peer_connected(id):
	print("Peer " + str(id) + " has connected")
	num_clients += 1
	$Label.text = "server: number of clients: %d" % num_clients
