extends Control

"""Test the pickler system"""

@onready var reg: PicklerRegistry = $PicklerRegistry

# Called when the node enters the scene tree for the first time.
func _ready():
	print(typeof(CustomClassOne))
	reg.register_class(CustomClassOne)
	reg.register_class(CustomClassTwo)
	
	
	var obj = {
		"one": CustomClassOne.new(),
		"two": CustomClassTwo.new()
	}
	obj["one"].foo = 2.0
	obj["two"].qux = "I turned myself into a pickle. I'm pickle Riiiick"
	var p = reg.pre_pickle(obj)
	
	var s = JSON.stringify(p, "    ")
	print(s)
	
	var u = reg.post_unpickle(p)
	print(u)
	
	#print('me: %s' % [ CustomClassOne ])
	##print('name: %s' % [ CustomClassOne.name ])
	#print('script path: %s' % [ CustomClassOne.resource_path ])
	#print('script filename: %s' % [ CustomClassOne.resource_path.get_file() ])
	#
	#print()
	#
	#var message = "This is a test message."
	#print_debug('%s "%s": %s' % [ self, name, message ])
