extends Control

@rpc("any_peer") func send_pickle(pickled_data):
	$textbox.text = pickled_data
	


func _on_button_pressed() -> void:
	send_pickle.rpc($textbox.text)
