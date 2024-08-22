extends Control

"""delete me, unit testing covered by GDUnit4 now."""

func _ready():
	await get_tree().create_timer(1).timeout
	get_tree().quit()
