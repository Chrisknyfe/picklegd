extends Control

const ITERATIONS = 1000
const SUBOBJECTS = 10

@onready var pickler := Pickler.new()

func _ready():
	benchmark_pickler()
	benchmark_refserializer()

	# automatically quit
	await get_tree().create_timer(1).timeout
	get_tree().quit()

func benchmark_pickler() -> void:
	var start_ms = Time.get_ticks_msec()
	pickler.class_registry.clear()
	pickler.register_custom_class(CustomClassOne)
	pickler.register_custom_class(CustomClassTwo)
	pickler.register_custom_class(BigClassChrisknyfe)
	
	var bigdata := BigClassChrisknyfe.new()
	for i in range(SUBOBJECTS):
		bigdata.refcounteds.append(CustomClassOne.new())
		bigdata.refcounteds.append(CustomClassTwo.new())
	var p = null
	var u = null
	for i in range(ITERATIONS):
		p = pickler.pickle(bigdata)
		u = pickler.unpickle(p)
	var end_ms = Time.get_ticks_msec()
	print("PickleGD\t\t", len(p), " bytes ", end_ms - start_ms, " msec")


func benchmark_refserializer() -> void:
	var start_ms = Time.get_ticks_msec()
	RefSerializer._types.clear()
	RefSerializer.serialize_defaults = true
	RefSerializer.register_type(&"CustomClassOne", CustomClassOne.new)
	RefSerializer.register_type(&"CustomClassTwo", CustomClassTwo.new)
	RefSerializer.register_type(&"BigClassChrisknyfe", BigClassChrisknyfe.new)
	
	var bigdata: BigClassChrisknyfe = RefSerializer.create_object(&"BigClassChrisknyfe")
	for i in range(SUBOBJECTS):
		bigdata.refcounteds.append(RefSerializer.create_object(&"CustomClassOne"))
		bigdata.refcounteds.append(RefSerializer.create_object(&"CustomClassTwo"))
	var s = null
	var u = null
	for i in range(ITERATIONS):
		s = var_to_bytes(RefSerializer.serialize_object(bigdata))
		u = RefSerializer.deserialize_object(bytes_to_var(s))
	var end_ms = Time.get_ticks_msec()
	print("RefSerializer\t", len(s), " bytes ", end_ms - start_ms, " msec")
