extends Control

@onready var pickler: Pickler = Pickler.new()

func _ready():
	pickler.register_custom_class(TestForm)

@rpc("any_peer") func send_pickle(pickled_data: PackedByteArray):
	var form = pickler.unpickle(pickled_data)
	$textbox.text = form.message
	$HScrollBar.value = form.num_sheep
	$CheckButton.button_pressed = form.is_reticulated
	$ColorPickerButton.color = form.albedo
	if typeof("asdf") == TYPE_STRING:
		pass


func _on_button_pressed() -> void:
	var form = TestForm.new()
	form.message = $textbox.text
	form.num_sheep = $HScrollBar.value
	form.is_reticulated = $CheckButton.button_pressed
	form.albedo = $ColorPickerButton.color
	send_pickle.rpc(pickler.pickle(form))
