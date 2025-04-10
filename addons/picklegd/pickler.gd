class_name Pickler
extends BasePickler
## A system for safely serializing and deserializing arbitrary GDScript data,
## which whitelists Object types that are allowed to be pickled.
##
## This is a system for serializing GDScript objects to byte arrays, using native
## var_to_bytes plus some class inspection magic, to safely handle data without
## allowing attackers to inject malicious code into your game. The Pickler makes
## it easy for you to send complex composite data structures (such as deeply nested
## dictionaries, or large custom classes) over the network to multiplayer peers,
## or to disk to save your game's data.
## [br][br]
## Why should you use a [Pickler] instead of Godot's built-in tools for serialization,
## such as plain [method @GlobalScope.var_to_bytes],
## [method @GlobalScope.var_to_bytes_with_objects], or
## [ResourceLoader]? In the case of the var_to_bytes family of methods,
## an attacker can change the script path of any serialized [Object], causing your deserialized data
## to behave in unwanted ways. Using ResourceLoader will execute any custom code
## in the [Resource] files being loaded.
## [br][br]
## A Pickler attempts to prevent malicious code injection by:
## [br] -  Filtering out unsafe properties, such as "script" or "script/source"
## [br] -  Only serializing class types that you deliberately register with the Pickler
## [br] -  Allowing you fine-grained control over serialized data using
## [code]__getstate__()[/code] and [code]__setstate__()[/code] methods you provide.
## [br][br]
## To pickle an object using a [Pickler], first register that object's class
## by calling [method Pickler.register_custom_class] or [method Pickler.register_native_class].
## Now you can [method Pickler.pickle] any data that contains those classes.
## [br]For example:
## [codeblock lang=gdscript]
## var data = {"one": CustomClassOne.new(), "two": 2}
## var pickler = Pickler.new()
## pickler.register_custom_class(CustomClassOne)
## var pickle = pickler.pickle(data)
## var plain_data = pickler.unpickle(pickle)
## [/codeblock]
## By default an Object's storage and script properties will be serialized and deserialized.
## For the full list of property flags the pickler considers when deciding if a property is safe
## to deserialize, see [constant BasePickler.PROP_WHITELIST] and
## [constant BasePickler.PROP_BLACKLIST].
## [br][br]
## You can also have direct control over which properties are serialized/deserialized by adding
## [code]__getnewargs__()[/code], 
## [code]__getstate__()[/code] and [code]__setstate__()[/code] methods to your custom class.
## The [Pickler] will first call [code]__getnewargs__()[/code] to get the arguments for the
## object's constructor, then
## will call [code]__getstate__()[/code] to retrieve an Object's properties during
## serialization, and later will call [code]__setstate__()[/code] to set an Object's properties
## during deserialization. You may also use these methods to perform
## input validation on an Object's properties.
## [br][br]
## [code]__getnewargs__()[/code] takes no arguments, and must return an [Array].
## [br][br]
## [code]__getstate__()[/code] takes no arguments, and must return a [Dictionary].
## [br][br]
## [code]__setstate__()[/code] takes one argument, the state [Dictionary], and has no return value.
## [br][br]
## [br]For example:
## [codeblock lang=gdscript]
## extends Resource
## class_name CustomClassNewargs
##
## var foo: String = "bluh"
## var baz: float = 4.0
## var qux: String = "x"
##
## func _init(new_foo: String):
##     foo = new_foo
##
## func __getnewargs__() -> Array:
##     return [foo]
##
## func __getstate__() -> Dictionary:
##     return {"1": baz, "2": qux}
##
## func __setstate__(state: Dictionary):
##     baz = state["1"]
##     qux = state["2"]
## [/codeblock]
## Finally, [Pickler] allows you to further override [code]__getnewargs__()[/code], 
## [code]__getstate__()[/code] and [code]__setstate__()[/code] when you register
## a class with the Pickler. For example:
## [codeblock lang=gdscript]
## var pickler := Pickler.new()
## var reg := pickler.register_custom_class(CustomClassNewargs)
## reg.__getnewargs__ = func(obj): return ["lambda_newarg!"]
## reg.__getstate__ = func(obj): return {"baz": obj.baz}
## reg.__setstate__ = func(obj, state): obj.baz = state["baz"]
## var obj := CustomClassNewargs.new("constructor arg will be overwritten")
## obj.qux = "won't be pickled."
## var pickle = pickler.pickle(obj)
## var plain_data = pickler.unpickle(pickle)
## [/codeblock]
##
## If you want more control over the objects and properties you pickle,
## you can extend [BasePickler] .

## Registry of classes that are allowed to be pickled.
var class_registry: Registry = Registry.new()


## Register a custom class that can be pickled with this pickler. Returns the
## [RegisteredBehavior] object representing this custom class.
func register_custom_class(c: Script) -> RegisteredClass:
	"""Register a custom class."""
	var rc = RegisteredClass.new()
	var gname: StringName = c.get_global_name()
	if gname.is_empty():
		push_warning("Cannot get class name: ", c)
		return null
	rc.name = gname
	rc.custom_class_def = c
	return class_registry.register(rc) as RegisteredClass


## Returns true if the custom class is registered with this pickler.
func has_custom_class(c: Script) -> bool:
	return class_registry.has_by_name(c.get_global_name())


## Register a godot engine native class. Returns the
## [RegisteredBehavior] object representing this native class.
func register_native_class(cls_name: String) -> RegisteredClass:
	"""Register a native class. cls_name must match the name returned by instance.class_name()"""
	var rc = RegisteredClass.new()
	rc.name = cls_name
	rc.custom_class_def = null
	return class_registry.register(rc) as RegisteredClass


## Returns true if the native class is registered with this pickler.
func has_native_class(cls_name: String) -> bool:
	return class_registry.has_by_name(cls_name)


func get_object_registered_behavior(obj: Object) -> RegisteredClass:
	var obj_class_name = super.get_object_class_id(obj)
	if obj_class_name == null:
		return null
	if not class_registry.has_by_name(obj_class_name):
		push_warning("Object class type unregistered: ", obj_class_name)
		return null
	var reg: RegisteredBehavior = class_registry.get_by_name(obj_class_name)
	return reg


## Get an ID for this object's class, if the class is registered
func get_object_class_id(obj: Object):
	var reg := get_object_registered_behavior(obj)
	if reg == null:
		return null
	return reg.id


## Create an instance of this class from its ID, if the ID is registered.
func instantiate_from_class_id(id, newargs: Array) -> Object:
	if typeof(id) != TYPE_INT:
		return null
	if not class_registry.has_by_id(id):
		push_warning("Object class ID unregistered: ", id)
		return null
	var reg: RegisteredClass = class_registry.get_by_id(id)
	if not newargs.is_empty():
		if reg.custom_class_def != null:
			return reg.custom_class_def.callv("new", newargs)
		if ClassDB.class_exists(reg.name):
			push_warning("Cannot instantiate a native class with constructor arguments")
			return null
	else:
		if reg.custom_class_def != null:
			return reg.custom_class_def.new()
		if ClassDB.class_exists(reg.name):
			return ClassDB.instantiate(reg.name)
	return null
	
func get_object_state(obj: Object) -> Dictionary:
	var reg := get_object_registered_behavior(obj)
	if reg.has_getstate():
		var dict = reg.__getstate__.call(obj)
		for key in dict.keys():
			dict[key] = pre_pickle(dict[key])
		return dict
	return super.get_object_state(obj)
	

func set_object_state(obj: Object, state: Dictionary):
	var reg := get_object_registered_behavior(obj)
	if reg.has_setstate():
		for key in state:
			state[key] = post_unpickle(state[key])
		reg.__setstate__.call(obj, state)
	else:
		super.set_object_state(obj, state)
		
func get_object_newargs(obj: Object):
	var reg := get_object_registered_behavior(obj)
	if reg.has_getnewargs():
		var newargs = reg.__getnewargs__.call(obj)
		for i in range(len(newargs)):
			newargs[i] = pre_pickle(newargs[i])
		return newargs
	return super.get_object_newargs(obj)
	
