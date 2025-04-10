# GdUnit generated TestSuite
class_name BenchmarkTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

const __source = 'res://addons/picklegd/pickler.gd'

const ITERATIONS = 1000

var pickler := Pickler.new()

func before():
	pickler.class_registry.clear()
	RefSerializer._types.clear()

func test_pickler_benchmark() -> void:
	pickler.register_custom_class(CustomClassOne)
	pickler.register_custom_class(CustomClassTwo)
	pickler.register_custom_class(BigClassChrisknyfe)
	
	var bigdata := BigClassChrisknyfe.new()
	var p = null
	var u = null
	for i in range(ITERATIONS):
		p = pickler.pickle(bigdata)
		u = pickler.unpickle(p)

func test_refserializer_benchmark() -> void:
	RefSerializer.register_type(&"CustomClassOne", CustomClassOne.new)
	RefSerializer.register_type(&"CustomClassTwo", CustomClassTwo.new)
	RefSerializer.register_type(&"BigClassChrisknyfe", BigClassChrisknyfe.new)
	
	var bigdata: BigClassChrisknyfe = RefSerializer.create_object(&"BigClassChrisknyfe")
	var s = null
	var u = null
	for i in range(ITERATIONS):
		s = RefSerializer.serialize_object(bigdata)
		u = RefSerializer.deserialize_object(s)
