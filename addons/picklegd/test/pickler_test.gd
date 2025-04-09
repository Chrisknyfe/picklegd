# GdUnit generated TestSuite
class_name PicklerTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/picklegd/pickler.gd'


var _pickler:Pickler = Pickler.new()
var _data = {
		"one": CustomClassOne.new(),
		"two": CustomClassTwo.new(),
		"3": CustomClassTwo.new(),
		"json_things": ["str", 42, {"foo":"bar"}, [1,2,3], true, false, null],
		"native": Vector3(0,1,2),
		"nativeobj": SurfaceTool.new(),
	}
	
func before():
	_data["one"].foo = 2.0
	_data["two"].qux = "r"


func before_test():
	_pickler.class_registry.clear()


func test_register_custom_class() -> void:
	_pickler.register_custom_class(CustomClassOne)
	assert_that(_pickler.has_custom_class(CustomClassOne))


func test_register_native_class() -> void:
	_pickler.register_native_class("SurfaceTool")
	assert_that(_pickler.has_native_class("SurfaceTool"))


func test_pickle_roudtrip() -> void:
	_pickler.register_custom_class(CustomClassOne)
	_pickler.register_custom_class(CustomClassTwo)
	_pickler.register_native_class("SurfaceTool")
	assert_that(_pickler.has_custom_class(CustomClassOne))
	assert_that(_pickler.has_custom_class(CustomClassTwo))
	assert_that(_pickler.has_native_class("SurfaceTool"))
	
	#print("tostring: ", _data["one"].get_script())
	#print("please print something")
	var p = _pickler.pickle(_data)
	var u = _pickler.unpickle(p)
	assert_dict(_data).contains_same_keys(u.keys())
	assert_object(_data["one"]).is_equal(u["one"])
	assert_object(_data["native"]).is_equal(u["native"])
	assert_object(_data["nativeobj"]).is_equal(u["nativeobj"])
	assert_array(_data["json_things"]).contains_same_exactly(u["json_things"])
	
func test_pickle_getstate_setstate():
	_pickler.register_custom_class(CustomClassTwo)
	assert_that(_pickler.has_custom_class(CustomClassTwo))
	var two = CustomClassTwo.new()
	var p = _pickler.pickle(two)
	assert_int(two.volatile_int).is_equal(-1)
	var u = _pickler.unpickle(p)
	assert_int(u.volatile_int).is_equal(99)
	
func test_pickle_str():
	_pickler.register_custom_class(CustomClassOne)
	_pickler.register_custom_class(CustomClassTwo)
	_pickler.register_native_class("SurfaceTool")
	var j = _pickler.pickle_str(_data)
	var u = _pickler.unpickle_str(j)
	
func test_pickle_filtering():
	var j = _pickler.pre_pickle(_data)
	assert_that(j["one"]).is_null()
	assert_that(j["two"]).is_null()
	assert_that(j["3"]).is_null()
	assert_array(j["json_things"]).contains_exactly(_data["json_things"])
	assert_that(j["native"]).is_equal(Vector3(0,1,2))
	assert_that(j["nativeobj"]).is_null()
	
	j["bad_obj"] = {
		BasePickler.CLASS_KEY: 99
	}
	
	var u = _pickler.post_unpickle(j)
	assert_that(u["bad_obj"]).is_null()

	#assert_error(_pickler.pre_pickle.bind(SurfaceTool.new()))\
	#.is_push_error('Missing object type in picked data: SurfaceTool')

# TODO: this should be a set of tests for a Registry
func test_pickle_load_associations() -> void:
	_pickler.register_custom_class(CustomClassOne)
	_pickler.register_custom_class(CustomClassTwo)
	_pickler.register_native_class("SurfaceTool")
	assert_that(_pickler.has_custom_class(CustomClassOne))
	assert_that(_pickler.has_custom_class(CustomClassTwo))
	assert_that(_pickler.has_native_class("SurfaceTool"))
	
	var p2: Pickler = Pickler.new()

	var assoc = _pickler.class_registry.get_associations()
	p2.class_registry.add_name_to_id_associations(assoc)
	p2.register_native_class("SurfaceTool")
	p2.register_custom_class(CustomClassTwo)
	p2.register_custom_class(CustomClassOne)
	assert_that(p2.has_custom_class(CustomClassOne))
	assert_that(p2.has_custom_class(CustomClassTwo))
	assert_that(p2.has_native_class("SurfaceTool"))

	for cls_name in _pickler.class_registry.by_name:
		var cls1 = _pickler.class_registry.get_by_name(cls_name)
		var cls2 = p2.class_registry.get_by_name(cls_name)
		assert_str(cls1.name).is_equal(cls2.name)
		assert_int(cls1.id).is_equal(cls2.id)


func test_newargs():
	_pickler.register_custom_class(CustomClassNewargs)
	var data := CustomClassNewargs.new("constructor_arg!")
	var s = _pickler.pickle_str(data)
	print(s)
	var u = _pickler.unpickle_str(s)
	print(u.foo)
	assert_object(u).is_equal(data)
	
func test_registered_getstate_setstate_newargs():
	var reg := _pickler.register_custom_class(CustomClassNewargs)
	reg.__getnewargs__ = func(obj): return ["lambda_newarg!"]
	reg.__getstate__ = func(obj): return {"baz": obj.baz}
	reg.__setstate__ = func(obj, state): obj.baz = state["baz"]
	var data = CustomClassNewargs.new("constructor_arg!")
	data.qux = "just a whatever string this won't show up in the output."
	var s = _pickler.pickle_str(data)
	print(s)
	var u = _pickler.unpickle_str(s)
	print(u.qux)
	assert_str(u.foo).is_not_equal(data.foo)
	assert_float(u.baz).is_equal(data.baz)
	assert_str(u.qux).is_not_equal(data.qux)

	
