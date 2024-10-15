extends Control

const DEFAULT_PORT = 28960
const MAX_CLIENTS = 50

var num_clients = 0

func _ready() -> void:
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)

	var server = ENetMultiplayerPeer.new()
	server.create_server(DEFAULT_PORT, MAX_CLIENTS)
	multiplayer.set_multiplayer_peer(server)
	$Label.text = "Server is listening"
	

func _peer_disconnected(id):
	print("Peer " + str(id) + " has disconnected")
	num_clients -= 1
	$Label.text = "Number of clients: %d" % num_clients

func _peer_connected(id):
	print("Peer " + str(id) + " has connected")
	num_clients += 1
	$Label.text = "Number of clients: %d" % num_clients
