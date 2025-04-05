# GdUnit generated TestSuite
class_name RegistryTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/picklemp/registry.gd'


var _reg := Registry.new()
var _some_behavior_names = [
	"moonbeam", 
	"fireball", 
	"icelance", 
	"windsheild", 
	"earthbend", 
	"startouch",
]

func behavior(new_name: String):
	var b = RegisteredBehavior.new()
	b.name = new_name
	return b

func before_test():
	_reg.clear()

## Registered behaviors are retrievable by name and numeric ID
func test_register_and_get() -> void:
	for n in _some_behavior_names:
		var b = _reg.register(behavior(n))
		assert_bool(_reg.has_by_name(n)).is_true()
		assert_bool(_reg.has_by_id(b.id)).is_true()
		var b2 = _reg.get_by_name(n)
		assert_object(b2).is_same(b)
		var b3 = _reg.get_by_id(b.id)
		assert_object(b3).is_same(b)

## Registered behaviors have unique IDs.
func test_unique_ids() -> void:
	for n in _some_behavior_names:
		_reg.register(behavior(n))
	for n in _some_behavior_names:
		var b = _reg.get_by_name(n)
		for n2 in _some_behavior_names:
			if n2 != n:
				var b2 = _reg.get_by_name(n2)
				assert_int(b2.id).is_not_equal(b.id)


func test_clear() -> void:
	for n in _some_behavior_names:
		_reg.register(behavior(n))
	_reg.clear()
	for n in _some_behavior_names:
		assert_bool(_reg.has_by_name(n)).is_false()


func test_associations() -> void:
	for n in _some_behavior_names:
		_reg.register(behavior(n))
	var assoc = _reg.get_associations()
	print(assoc)
	
	# A multiplayer client might register the same behaviors
	# in a different order
	var reversed = Array(_some_behavior_names)
	reversed.reverse()
	var _reg_client = Registry.new()
	
	# So let's load the associations first!
	_reg_client.add_name_to_id_associations(assoc)
	# then the client will register its behaviors...
	for n in reversed:
		_reg_client.register(behavior(n))
		
	# And now server and client registries should match!
	for n in _some_behavior_names:
		var bs = _reg.get_by_name(n)
		var bc = _reg_client.get_by_name(n)
		assert_str(bc.name).is_equal(bs.name)
		assert_int(bc.id).is_equal(bs.id)
	
	
