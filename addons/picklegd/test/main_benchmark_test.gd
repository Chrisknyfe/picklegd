extends Control

@onready var pickler := Pickler.new()

@export var iterations := 1000
@export var subobjects := 10
@export var serialize_defaults := true

func _ready():
	var p = benchmark_pickler(iterations, subobjects, serialize_defaults)
	var s = benchmark_refserializer(iterations, subobjects, serialize_defaults)
	var bytes_percent = "%.1f" % [float(p["bytes"]) * 100.0 / float(s["bytes"])]
	var time_percent = "%.1f" % [float(p["msec"]) * 100.0 / float(s["msec"])]
	var comp_percent = "%.1f" % [float(p["bytes_comp"]) * 100.0 / float(s["bytes_comp"])]
	print("Serialize defaults: ", serialize_defaults)
	print("serialize/deserialize roundtrip iterations: ", iterations)
	print()
	print("PickleGD\t\t", p["bytes"], " bytes ", p["msec"], " msec ", p["bytes_comp"], " comp")
	print("RefSerializer\t", s["bytes"], " bytes ", s["msec"], " msec ", s["bytes_comp"], " comp")
	print()
	print("Pickle Perf%\t", bytes_percent, "% size ", time_percent, "% time ", comp_percent, "% comp   compared to RefSerializer")

	# automatically quit
	await get_tree().create_timer(1).timeout
	get_tree().quit()
	#pass

func _process(delta):
	#benchmark_pickler(1, 5)
	#benchmark_refserializer(1, 5)
	pass
	
func benchmark_pickler(iterations: int = 1000, subobjects: int = 10, serialize_defaults: bool = true):
	var start_ms = Time.get_ticks_msec()
	pickler.serialize_defaults = serialize_defaults
	pickler.class_registry.clear()
	pickler.register_custom_class(CustomClassOne)
	pickler.register_custom_class(CustomClassTwo)
	pickler.register_custom_class(BigClassThing)
	
	var bigdata := BigClassThing.new()
	for i in range(subobjects):
		bigdata.refcounteds.append(CustomClassOne.new())
		if serialize_defaults:
			bigdata.refcounteds.append(CustomClassTwo.new())
		else:
			bigdata.refcounteds.append(CustomClassOne.new())
	var p = null
	var u = null
	for i in range(iterations):
		p = pickler.pickle(bigdata)
		u = pickler.unpickle(p)
	var end_ms = Time.get_ticks_msec()
	var pcomp = pickler.pickle_compressed(bigdata)
	return {"bytes":len(p), "bytes_comp":len(pcomp), "msec":end_ms-start_ms}


func benchmark_refserializer(iterations: int = 1000, subobjects: int = 10, serialize_defaults: bool = true):
	var start_ms = Time.get_ticks_msec()
	RefSerializer._types.clear()
	RefSerializer.serialize_defaults = serialize_defaults
	RefSerializer.register_type(&"CustomClassOne", CustomClassOne.new)
	RefSerializer.register_type(&"CustomClassTwo", CustomClassTwo.new)
	RefSerializer.register_type(&"BigClassThing", BigClassThing.new)
	
	var bigdata: BigClassThing = RefSerializer.create_object(&"BigClassThing")
	for i in range(subobjects):
		bigdata.refcounteds.append(RefSerializer.create_object(&"CustomClassOne"))
		if serialize_defaults:
			bigdata.refcounteds.append(RefSerializer.create_object(&"CustomClassTwo"))
		else:
			bigdata.refcounteds.append(RefSerializer.create_object(&"CustomClassOne"))
	var s = null
	var u = null
	for i in range(iterations):
		s = var_to_bytes(RefSerializer.serialize_object(bigdata))
		u = RefSerializer.deserialize_object(bytes_to_var(s))
	var end_ms = Time.get_ticks_msec()
	var scomp = s.compress(FileAccess.COMPRESSION_DEFLATE)
	return {"bytes":len(s), "bytes_comp":len(scomp), "msec":end_ms-start_ms}
