# GdUnit generated TestSuite
class_name BasePicklerTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/picklegd/base_pickler.gd'


var _bp:BasePickler = BasePickler.new()

var _builtins = {
	"builtins": [
		# refer to @GlobalScope.Variant.Type enum in Godot 4.4
		null,
		true,
		2,
		3.0,
		"four",
		Vector2(5.0,5.0),
		Vector2i(6,6),
		Rect2(7.0, 7.0, 7.0, 7.0),
		Rect2i(8,8,8,8),
		Vector3(9.0,9.0,9.0),
		Vector3i(10,10,10),
		Transform2D(),
		Vector4(12.0,12.0,12.0,12.0),
		Vector4i(13,13,13,13),
		Plane(),
		Quaternion(),
		AABB(),
		Basis(),
		Transform3D(),
		Projection(),
		Color(0.5, 0.5, 0.5, 0.5),
		StringName("twenty_one"),
		NodePath(),
		#RID(), # type 23 rejected type because it's an internal ID
		Object.new(),
		#Callable(), # type 25 rejected type because it's code-over-the-wire
		#Signal(), # type 26 rejected type because it's code-over-the-wire
		Dictionary(),
		Array(),
		PackedByteArray([29,29,29,29]),
		PackedInt32Array([30,30,30,30]),
		PackedInt64Array([31,31,31,31]),
		PackedFloat32Array([32.0,32.0,32.0,32.0]),
		PackedFloat64Array([33.0,33.0,33.0,33.0]),
		PackedStringArray(["thirty", "four"]),
		PackedVector2Array([Vector2(35,35),Vector2(35,35)]),
		PackedVector3Array([Vector3(36,36,36),Vector3(36,36,36)]),
		PackedColorArray([Color(0.3,0.7,0.0),Color(0.3,0.7,0.0)]),
		PackedVector4Array([Vector4(38.0,38.0,38.0,38.0),Vector4(38.0,38.0,38.0,38.0)]),
	]
}
var _resources = {
	"resource": Resource.new(),
	"circle": CircleShape2D.new(),
	"image": Image.load_from_file("res://icon.svg"),
	#"material": load("res://test/picklegd/test_mat.tres")
}
var _customs = {
	"one": CustomClassOne.new(),
	#"two": CustomClassTwo.new(),
	#"3": CustomClassTwo.new(), # won't be equal
	"unsafe": TestFormUnsafe.new(),
}
var _misc = {
	"json_things": ["str", 42, {"foo":"bar"}, [1,2,3], true, false, null],
	"json_things_2": {"foo":"bar", "baz":123},
	"nativeobj": Node2D.new(),
}
	
class InlineObject extends Object:
	@export var foo: int = 1
	@export var bar: float = 2.0
	
func before():
	_customs["one"].foo = 2.0
	#_customs["two"].qux = "r"
	_resources["circle"].radius = 5.0

## recursive check for equality thru dictionaries and arrays.
func check_are_equal(left, right):
	assert_int(typeof(left)).is_equal(typeof(right))
	match typeof(left):
		TYPE_DICTIONARY:
			assert_dict(left).contains_same_keys(right.keys())
			for k in left.keys():
				check_are_equal(left[k], right[k])
		TYPE_ARRAY:
			assert_array(left).has_size(len(right))
			for i in range(len(left)):
				check_are_equal(left[i], right[i])
		TYPE_OBJECT:
			assert_str(left.get_class()).is_equal(right.get_class())
			assert_that(left).is_equal(right)
		_:
			assert_that(left).is_equal(right)
			

func roundtrip(dict: Dictionary):
	var p = _bp.pickle(dict)
	var u = _bp.unpickle(p)
	check_are_equal(dict, u)
	
	for key in u:
		if u[key] is Node:
			u[key].queue_free()
			
	var ps = _bp.pickle_str(dict)
	var us = _bp.unpickle_str(ps)
	check_are_equal(dict, us)
	
	for key in us:
		if us[key] is Node:
			us[key].queue_free()

func test_roundtrip_builtins() -> void:
	roundtrip(_builtins)


func test_roundtrip_resources() -> void:
	roundtrip(_resources)


func test_roundtrip_customs() -> void:
	roundtrip(_customs)
	
	
func test_roundtrip_misc() -> void:
	roundtrip(_misc)


func test_base_pickle_getstate_setstate():
	var two = CustomClassTwo.new()
	var p = _bp.pickle(two)
	assert_int(two.volatile_int).is_equal(-1)
	var u = _bp.unpickle(p)
	assert_int(u.volatile_int).is_equal(99)
	assert_object(two).is_not_equal(u)
	
	
func test_base_pickle_filtering():
	var j = {}
	
	j["bad_obj"] = {
		BasePickler.CLASS_KEY: 99
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

## A pickled script shouldn't have any source code. Sorry.
func test_base_pickle_a_script():
	# Can I pickle a GDScript?
	var s = _bp.pickle_str(TestFormUnsafe)
	var u = _bp.unpickle_str(s)
	assert_object(TestFormUnsafe).is_not_equal(u)
	var scr = GDScript.new()
	scr.source_code = \
"""
class_name Blah extends Refcounted

func _init():
	print("blah blah blah")

"""
	
	s = _bp.pickle_str(scr)
	print(s)
	u = _bp.unpickle_str(s)
	assert_object(scr).is_not_equal(u)

## You can't pickle an instance of an inline class. 
## It doesn't have a global name.
func test_base_pickle_inline_object():
	var s = _bp.pickle_str(InlineObject.new())
	assert_str(s).is_equal('null')
	
func test_newargs():
	var s = _bp.pickle_str(CustomClassNewargs.new("constructor_arg!"))
	print(s)
	var u = _bp.unpickle_str(s)
	print(u)
