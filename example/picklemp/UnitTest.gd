extends Control

"""Test the pickler system"""

@onready var reg: PicklerRegistry = $PicklerRegistry

# Called when the node enters the scene tree for the first time.
func _ready():
	reg.register(CustomClassOne, Pickler)
