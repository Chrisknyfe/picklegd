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
	
	$Label.text = "Pickle size (bytes): " + str(len(pickled_data))


func _on_button_pressed() -> void:
	var form = TestForm.new()
	form.message = $textbox.text
	form.num_sheep = $HScrollBar.value
	form.is_reticulated = $CheckButton.button_pressed
	form.albedo = $ColorPickerButton.color
	var p = pickler.pickle(form)
	$Label.text = "Pickle size (bytes): " + str(len(p))
	send_pickle.rpc(p)


func _on_double_button_pressed():
	# double it!
	var text = $textbox.text
	$textbox.text = text + ' ' + text
	_on_button_pressed()


func _on_clear_button_pressed():
	$textbox.text = ""
	_on_button_pressed()
