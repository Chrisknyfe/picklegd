# GdUnit generated TestSuite
class_name BenchmarkTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

const __source = 'res://addons/picklegd/pickler.gd'

const ITERATIONS = 1000

var pickler := Pickler.new()
var bigdata := BigClassChrisknyfe.new()

func test_pickler_benchmark() -> void:
	pickler.register_custom_class(CustomClassOne)
	pickler.register_custom_class(CustomClassTwo)
	pickler.register_custom_class(BigClassChrisknyfe)
	
	for i in range(ITERATIONS):
		var p = pickler.pickle(bigdata)
		var u = pickler.unpickle(p)
