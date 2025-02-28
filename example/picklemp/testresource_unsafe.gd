class_name TestResourceUnsafe
extends Resource

@export var message: String = ""
@export var is_reticulated: bool = false
@export var num_sheep: int = 2
@export var albedo: Color = Color.BLUE

func _init():
	print("TestResourceUnsafe _init() func called! HAH.")
