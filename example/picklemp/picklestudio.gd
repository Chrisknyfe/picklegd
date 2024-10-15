extends Control

@onready var pickler: Pickler = Pickler.new()

func _ready():
	pickler.register_custom_class(TestForm)

@rpc("any_peer") func send_pickle(pickled_data: PackedByteArray):
	var form = pickler.unpickle(pickled_data)
	$textbox.text = form.message


func _on_button_pressed() -> void:
	var form = TestForm.new()
	form.message = $textbox.text
	send_pickle.rpc(pickler.pickle(form))
