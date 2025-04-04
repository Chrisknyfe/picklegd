# GdUnit generated TestSuite
class_name BasePicklerTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/picklemp/base_pickler.gd'


var _bp:BasePickler = BasePickler.new()
# refer to @GlobalScope.Variant.Type enum in Godot 4.4
var _some_builtin_types = [
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

var _some_godot_resources = {
	"resource": Resource.new(),
	"circle": CircleShape2D.new(),
	"image": Image.load_from_file("res://icon.svg"),
	#"material": load("res://test/picklemp/test_mat.tres")
}
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
	_some_godot_resources["circle"].radius = 5.0


func test_base_pickle_roudtrip() -> void:
	
	var p = _bp.pickle(_data)
	var u = _bp.unpickle(p)
	assert_dict(_data).contains_same_keys(u.keys())
	assert_object(_data["one"]).is_equal(u["one"])
	assert_object(_data["native"]).is_equal(u["native"])
	assert_object(_data["nativeobj"]).is_equal(u["nativeobj"])
	assert_array(_data["json_things"]).contains_same_exactly(u["json_things"])
	u["node"].queue_free()
	
func test_base_pickle_roundtrip_builtins():
	var p = _bp.pickle(_some_builtin_types)
	var u = _bp.unpickle(p)
	for i in _some_builtin_types.size():
		assert_int(typeof(_some_builtin_types[i])).is_equal(typeof(u[i]))
		assert_that(_some_builtin_types[i]).is_equal(u[i])

func test_base_pickle_str_roundtrip_builtins():
	var p = _bp.pickle_str(_some_builtin_types)
	var u = _bp.unpickle_str(p)
	for i in _some_builtin_types.size():
		assert_int(typeof(_some_builtin_types[i])).is_equal(typeof(u[i]))
		assert_that(_some_builtin_types[i]).is_equal(u[i])


func test_base_pickle_godot_resources():
	var resources = _some_godot_resources
	var p = _bp.pickle_str(resources)
	var u = _bp.unpickle_str(p)
	print("godot resources: ",  p)
	for key in resources.keys():
		var r_obj = resources[key]
		var u_obj = u[key]
		assert_str(r_obj.get_class()).is_equal(u_obj.get_class())
		assert_that(r_obj).is_equal(u_obj)

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
