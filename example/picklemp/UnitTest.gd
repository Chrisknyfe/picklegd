extends Control

"""Test the pickler system"""

@onready var pickler: Pickler = $Pickler

# Called when the node enters the scene tree for the first time.
func _ready():
	pickler.register_class(CustomClassOne)
	pickler.register_class(CustomClassTwo)
	
	
	var some_gdscript_data = {
		"one": CustomClassOne.new(),
		"two": CustomClassTwo.new()
	}
	some_gdscript_data["one"].foo = 2.0
	some_gdscript_data["two"].qux = "I turned myself into a pickle. I'm pickle Riiiick"
	
	var pickle = pickler.pre_pickle(some_gdscript_data)
	
	var s = JSON.stringify(pickle, "    ")
	print(s)
	
	# TODO:
	# - pickle_json
	# - pickle (bytes)
	# - gzip the bytes
	
	# people play games for mastery, connection, or expression
	# survival, villagers, techbuilds
	var unpickle = pickler.post_unpickle(pickle)
	print(unpickle)
	
	#print('me: %s' % [ CustomClassOne ])
	##print('name: %s' % [ CustomClassOne.name ])
	#print('script path: %s' % [ CustomClassOne.resource_path ])
	#print('script filename: %s' % [ CustomClassOne.resource_path.get_file() ])
	#
	#print()
	#
	#var message = "This is a test message."
	#print_debug('%s "%s": %s' % [ self, name, message ])
