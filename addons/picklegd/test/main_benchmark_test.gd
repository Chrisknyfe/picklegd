extends Control

@onready var pickler := Pickler.new()

func _ready():
	var p = benchmark_pickler()
	var s = benchmark_refserializer()
	var bytes_percent = "%.1f" % [float(p["bytes"]) * 100.0 / float(s["bytes"])]
	var time_percent = "%.1f" % [float(p["msec"]) * 100.0 / float(s["msec"])]
	print("PickleGD\t\t", p["bytes"], " bytes ", p["msec"], " msec")
	print("RefSerializer\t", s["bytes"], " bytes ", s["msec"], " msec")
	print("Pickle Perf%\t", bytes_percent, "% size ", time_percent, "% time compared to RefSerializer")

	# automatically quit
	await get_tree().create_timer(1).timeout
	get_tree().quit()
	#pass

func _process(delta):
	#benchmark_pickler(1, 5)
	#benchmark_refserializer(1, 5)
	pass
	
func benchmark_pickler(iterations: int = 1000, subobjects: int = 10):
	var start_ms = Time.get_ticks_msec()
	pickler.class_registry.clear()
	pickler.register_custom_class(CustomClassOne)
	pickler.register_custom_class(CustomClassTwo)
	pickler.register_custom_class(BigClassChrisknyfe)
	
	var bigdata := BigClassChrisknyfe.new()
	for i in range(subobjects):
		bigdata.refcounteds.append(CustomClassOne.new())
		bigdata.refcounteds.append(CustomClassTwo.new())
	var p = null
	var u = null
	for i in range(iterations):
		p = pickler.pickle(bigdata)
		u = pickler.unpickle(p)
	var end_ms = Time.get_ticks_msec()
	return {"bytes":len(p), "msec":end_ms-start_ms}


func benchmark_refserializer(iterations: int = 1000, subobjects: int = 10):
	var start_ms = Time.get_ticks_msec()
	RefSerializer._types.clear()
	RefSerializer.serialize_defaults = true
	RefSerializer.register_type(&"CustomClassOne", CustomClassOne.new)
	RefSerializer.register_type(&"CustomClassTwo", CustomClassTwo.new)
	RefSerializer.register_type(&"BigClassChrisknyfe", BigClassChrisknyfe.new)
	
	var bigdata: BigClassChrisknyfe = RefSerializer.create_object(&"BigClassChrisknyfe")
	for i in range(subobjects):
		bigdata.refcounteds.append(RefSerializer.create_object(&"CustomClassOne"))
		bigdata.refcounteds.append(RefSerializer.create_object(&"CustomClassTwo"))
	var s = null
	var u = null
	for i in range(iterations):
		s = var_to_bytes(RefSerializer.serialize_object(bigdata))
		u = RefSerializer.deserialize_object(bytes_to_var(s))
	var end_ms = Time.get_ticks_msec()
	return {"bytes":len(s), "msec":end_ms-start_ms}
