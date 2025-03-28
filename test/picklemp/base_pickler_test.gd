# GdUnit generated TestSuite
class_name BasePicklerTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/picklemp/base_pickler.gd'


var _bp:BasePickler = BasePickler.new()
var _data = {
		"one": CustomClassOne.new(),
		"two": CustomClassTwo.new(),
		"3": CustomClassTwo.new(),
		"json_things": ["str", 42, {"foo":"bar"}, [1,2,3], true, false, null],
		"native": Vector3(0,1,2),
		"nativeobj": SurfaceTool.new(),
		"node": Node2D.new(),
		"unsafe": TestFormUnsafe.new(),
	}
	
class InlineObject extends Object:
	@export var foo: int = 1
	@export var bar: float = 2.0
	
func before():
	_data["one"].foo = 2.0
	_data["two"].qux = "r"


func test_base_pickle_roudtrip() -> void:
	
	var p = _bp.pickle(_data)
	var u = _bp.unpickle(p)
	assert_dict(_data).contains_same_keys(u.keys())
	assert_object(_data["one"]).is_equal(u["one"])
	assert_object(_data["native"]).is_equal(u["native"])
	assert_object(_data["nativeobj"]).is_equal(u["nativeobj"])
	assert_array(_data["json_things"]).contains_same_exactly(u["json_things"])
	u["node"].queue_free()

func test_base_pickle_getstate_setstate():
	var two = CustomClassTwo.new()
	var p = _bp.pickle(two)
	assert_int(two.volatile_int).is_equal(-1)
	var u = _bp.unpickle(p)
	assert_int(u.volatile_int).is_equal(99)
	
	
func test_base_pickle_str():
	var s = _bp.pickle_str(_data)
	print(s)
	var u = _bp.unpickle_str(s)
	u["node"].queue_free()
	
	
func test_base_pickle_filtering():
	var j = {}
	
	j["bad_obj"] = {
		"__class__": 99
	}
	
	var u = _bp.post_unpickle(j)
	assert_that(u["bad_obj"]).is_null()
	
func test_base_pickle_inject_script_change():
	var t = TestForm.new()
	
	var s = _bp.pickle_str(t)
	s = s.replace("TestForm", "TestFormUnsafe")
	print(s)
	var u = _bp.unpickle_str(s)
	print(u)
	assert_str(u.get_script().get_global_name()).is_equal("TestFormUnsafe")
	
func test_base_pickle_a_script():
	# Can I pickle a GDScript?
	var s = _bp.pickle_str(TestFormUnsafe)
	print(s)
	var u = _bp.unpickle_str(s)
	print(u)

func test_base_pickle_inline_object():
	var s = _bp.pickle_str(InlineObject.new())
	assert_str(s).is_equal('null')
