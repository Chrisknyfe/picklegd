# GdUnit generated TestSuite
class_name PicklerTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/picklemp/pickler.gd'


var _pickler:Pickler = Pickler.new()
var _some_gdscript_data = {
		"one": CustomClassOne.new(),
		"two": CustomClassTwo.new(),
		3: CustomClassTwo.new(),
		"json_things": ["str", 42, {"foo":"bar"}, [1,2,3], true, false, null],
		"native": Vector3(0,1,2),
		"nativeobj": SurfaceTool.new(),
	}
	
func before():
	_some_gdscript_data["one"].foo = 2.0
	#_some_gdscript_data["two"].qux = "r"


func before_test():
	_pickler.clear()


func test_register_custom_class() -> void:
	_pickler.register_custom_class(CustomClassOne)


func test_register_native_class() -> void:
	_pickler.register_native_class("SurfaceTool")


func test_pickle() -> void:
	_pickler.register_custom_class(CustomClassOne)
	_pickler.register_custom_class(CustomClassTwo)
	_pickler.register_native_class("SurfaceTool")
	print("tostring: ", _some_gdscript_data["one"].get_script())
	print("please print something")
	#var p = _pickler.pickle(_some_gdscript_data)
