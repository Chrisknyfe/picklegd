class_name Pickler
extends RefCounted
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


const PROP_WHITELIST: PropertyUsageFlags = (
	PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_ALWAYS_DUPLICATE
)
const PROP_BLACKLIST: PropertyUsageFlags = (
	PROPERTY_USAGE_INTERNAL
	| PROPERTY_USAGE_NO_INSTANCE_STATE
	| PROPERTY_USAGE_NEVER_DUPLICATE
	| PROPERTY_USAGE_RESOURCE_NOT_PERSISTENT
)
const CLASS_KEY = "__CLS"
const NEWARGS_KEY = "__NEW"


## Registry of classes that are allowed to be pickled.
var class_registry: Registry = Registry.new()


## Pickle the arbitary GDScript data to a string.
func pickle_str(obj) -> String:
	return var_to_str(pre_pickle(obj))


## Unpickle the string to arbitrary GDScript data.
func unpickle_str(s: String):
	return post_unpickle(str_to_var(s))


## Pickle the arbitary GDScript data to a PackedByteArray.
func pickle(obj) -> PackedByteArray:
	return var_to_bytes(pre_pickle(obj))


## Unpickle the PackedByteArray to arbitrary GDScript data.
func unpickle(buffer: PackedByteArray):
	return post_unpickle(bytes_to_var(buffer))


## Get an ID for this object's class. 
## Returns the obj's class name,
## or null if there's no class name for this object.
func super_get_object_class_id(obj: Object):
	var scr: Script = obj.get_script()
	var obj_class_name = ""
	if scr != null:
		obj_class_name = scr.get_global_name()
	else:
		obj_class_name = obj.get_class()
	if obj_class_name.is_empty():
		push_warning("Cannot get object class id")
		return null
	return obj_class_name

## Get properties that are safe to pickle for this class.
## Properties such as the Object's "script" should be filtered out.
func get_pickleable_properties(obj: Object):
	var good_props = []
	#print("props for class ", get_object_class_id(obj))
	for prop in obj.get_property_list():
		if prop.usage & PROP_WHITELIST and not prop.usage & PROP_BLACKLIST:
			#print("keep prop ", prop.name, " :: ", prop.usage)
			good_props.append(prop)
		#else:
		#print("---- prop ", prop.name, " :: ", prop.usage)
	return good_props

func super_get_object_newargs(obj: Object) -> Array:
	if obj.has_method("__getnewargs__"):
		var newargs = obj.__getnewargs__()
		for i in range(len(newargs)):
			newargs[i] = pre_pickle(newargs[i])
		return newargs
	return []


## Get an object's state.
## Calls an object's [code]__getstate__()[/code], if it has one.
## Override this function if you want your extended pickler to
## perform special behavior for getting an object's state.
## Make sure to call [method BasePickler.pre_pickle] on all elements
## of the dictionary before returning it.
func super_get_object_state(obj: Object) -> Dictionary:
	var dict = {}
	if obj.has_method("__getstate__"):
		# gdlint:ignore = private-method-call
		dict = obj.__getstate__()
	else:
		for prop in get_pickleable_properties(obj):
			dict[prop.name] = obj.get(prop.name)
	for key in dict.keys():
		dict[key] = pre_pickle(dict[key])
	return dict


## Set an object's state.
## Calls an object's [code]__setstate__()[/code], if it has one.
## Override this function if you want your extended pickler to
## perform special behavior when setting an object's state.
## Make sure to call [method BasePickler.post_unpickle] on all elements
## of the state dictionary before setting state.
func super_set_object_state(obj: Object, state: Dictionary):
	if obj.has_method("__setstate__"):
		# for users of __setstate__, just unpickle whatever they want,
		# even if it's a bad idea.
		for key in state:
			state[key] = post_unpickle(state[key])
		# gdlint:ignore = private-method-call
		obj.__setstate__(state)
	else:
		# for Objects, only recursively unpickle allowed properties.
		for prop in get_pickleable_properties(obj):
			if state.has(prop.name):
				obj.set(prop.name, post_unpickle(state[prop.name]))



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
	var obj_class_name = super_get_object_class_id(obj)
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
	return super_get_object_state(obj)
	

func set_object_state(obj: Object, state: Dictionary):
	var reg := get_object_registered_behavior(obj)
	if reg.has_setstate():
		for key in state:
			state[key] = post_unpickle(state[key])
		reg.__setstate__.call(obj, state)
	else:
		super_set_object_state(obj, state)
		
func get_object_newargs(obj: Object) -> Array:
	var reg := get_object_registered_behavior(obj)
	if reg.has_getnewargs():
		var newargs = reg.__getnewargs__.call(obj)
		for i in range(len(newargs)):
			newargs[i] = pre_pickle(newargs[i])
		return newargs
	return super_get_object_newargs(obj)
	

## Preprocess arbitrary GDScript data, converting classes to appropriate dictionaries.
## Used by `pickle()` and `pickle_str()`.
func pre_pickle(obj):
	if obj == null:
		return null
	var retval = null
	match typeof(obj):
		# Rejected types
		TYPE_CALLABLE | TYPE_SIGNAL | TYPE_MAX | TYPE_RID:
			retval = null
		# Collection Types - recursion!
		TYPE_DICTIONARY:
			var out = {}
			var d: Dictionary = obj as Dictionary
			for key in d:
				out[key] = pre_pickle(d[key])
			retval = out
		TYPE_ARRAY:
			var out = []
			var a: Array = obj as Array
			for element in a:
				out.append(pre_pickle(element))
			retval = out
		# Objects - only registered objects get pickled
		TYPE_OBJECT:
			var obj_class_id = get_object_class_id(obj)

			if obj_class_id == null:
				retval = null
			else:
				var dict := get_object_state(obj)
				dict[CLASS_KEY] = obj_class_id
				var newargs := get_object_newargs(obj)
				if not newargs.is_empty():
					dict[NEWARGS_KEY] = newargs
				retval = dict
		# most builtin types are just passed through
		_:
			retval = obj
	return retval


## Post-process recently unpickled arbitrary GDScript data, instantiating custom
## classes and native classes from the appropriate dictionaries representing them.
## Used by `unpickle()` and `unpickle_str()`
func post_unpickle(obj):
	var retval = null
	match typeof(obj):
		# Rejected types
		TYPE_CALLABLE | TYPE_SIGNAL | TYPE_MAX | TYPE_RID | TYPE_OBJECT:
			retval = null
		# Collection Types - recursion!
		TYPE_DICTIONARY:
			var dict: Dictionary = obj as Dictionary
			if CLASS_KEY in dict:
				var newargs = []
				if NEWARGS_KEY in dict:
					newargs = dict[NEWARGS_KEY]
				dict.erase(NEWARGS_KEY)
				var out = instantiate_from_class_id(dict[CLASS_KEY], newargs)
				if out == null:
					return null
				dict.erase(CLASS_KEY)
				set_object_state(out, dict)
				retval = out
			else:
				# for plain Dictionaries, unpickle recursively
				for key in dict:
					dict[key] = post_unpickle(dict[key])
				retval = dict
		TYPE_ARRAY:
			var out = []
			var a: Array = obj as Array
			for element in a:
				out.append(post_unpickle(element))
			retval = out
		# most builtin types are just passed through
		_:
			retval = obj
	return retval
