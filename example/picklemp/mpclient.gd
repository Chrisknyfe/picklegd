extends Control

const DEFAULT_PORT = 28960
const IPADDR = "127.0.0.1"

func _ready() -> void:
	multiplayer.connected_to_server.connect(self._connected_to_server)
	multiplayer.server_disconnected.connect(self._server_disconnected)
	multiplayer.connection_failed.connect(self._connection_failed)
	
	var client = ENetMultiplayerPeer.new()
	client.create_client(IPADDR, DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(client)


func _connected_to_server():
	print("Successfully connected to server")
	$Label.text = "connected!"


func _server_disconnected():
	print("Disconnected from server")
	$Label.text = "disconnected."


func _connection_failed():
	print("Connection to server failed!")
	$Label.text = "connection failed."
