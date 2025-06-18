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
## [code]__getstate__()[/code], [code]__setstate__()[/code] and
## [code]__getnewargs__()[/code] methods you provide.
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
## to deserialize, see [constant Pickler.PROP_WHITELIST] and
## [constant Pickler.PROP_BLACKLIST].
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
## The [PicklableClass] for an Object type that is created at registration time also has
## `__getnewargs__()`, `__getstate__()` and `__setstate__()` functions you can override.
##

const PROP_WHITELIST: PropertyUsageFlags = (
	PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_ALWAYS_DUPLICATE
)
const PROP_BLACKLIST: PropertyUsageFlags = (
	PROPERTY_USAGE_INTERNAL
	| PROPERTY_USAGE_NO_INSTANCE_STATE
	| PROPERTY_USAGE_NEVER_DUPLICATE
	| PROPERTY_USAGE_RESOURCE_NOT_PERSISTENT
)
const CLASS_KEY := &"__CLS"
const NEWARGS_KEY := &"__NEW"

## registry of classes that are allowed to be pickled.
var class_registry: Dictionary[StringName, PicklableClass] = {}

## Serialize default values of Objects. Set to false to strip default values from objects.
var serialize_defaults := true

## Compression method for compressing and decompressing pickles
var compression_mode: FileAccess.CompressionMode = FileAccess.COMPRESSION_DEFLATE


## Get a name for this object's class.
## Returns the obj's class name,
## or null if there's no class name for this object.
func get_object_class_name(obj: Object) -> StringName:
	var scr: Script = obj.get_script()
	var clsname = &""
	if scr != null:
		clsname = scr.get_global_name()
	else:
		clsname = obj.get_class()
	return clsname


func _object_getnewargs(obj: Object) -> Array:
	return obj.__getnewargs__()


func _object_getstate(obj: Object) -> Dictionary:
	return obj.__getstate__()


func _object_setstate(obj: Object, state: Dictionary) -> void:
	obj.__setstate__(state)


## Register a custom class that can be pickled with this pickler. Returns the
## [RegisteredBehavior] object representing this custom class.
func register_custom_class(scr: Script) -> PicklableClass:
	var clsname := scr.get_global_name()
	if clsname.is_empty():
		push_warning("Cannot get custom class name")
		return null

	var pc := PicklableClass.new()

	# Interrogate the class at registration time to speed up pickling / unpickling
	pc.constructor = scr.new

	var methods = scr.get_script_method_list()
	var can_create_default_object := true
	for method in methods:
		match method.name:
			"_init":
				pc.newargs_len = len(method.args)
				if pc.newargs_len > 0:
					can_create_default_object = false
			"__getnewargs__":
				pc.__getnewargs__ = _object_getnewargs
				can_create_default_object = false
			"__getstate__":
				pc.__getstate__ = _object_getstate
				can_create_default_object = false
			"__setstate__":
				pc.__setstate__ = _object_setstate
				can_create_default_object = false

	if can_create_default_object:
		pc.default_object = scr.new()

	var proplist = scr.get_script_property_list()
	for prop in proplist:
		if prop.usage & PROP_WHITELIST and not prop.usage & PROP_BLACKLIST:
			pc.allowed_properties[prop.name] = true  # prop
	class_registry[clsname] = pc
	return pc


## Register a godot engine native class.
## clsname must match the name returned by instance.class_name().
## Returns the [RegisteredBehavior] object representing this native class.
func register_native_class(clsname: StringName) -> PicklableClass:
	if not ClassDB.class_exists(clsname):
		push_warning("Native class is not recognized: ", clsname)
		return null
	if not ClassDB.can_instantiate(clsname):
		push_warning("Native class cannot be instantiated: ", clsname)
		return null

	var pc := PicklableClass.new()
	pc.constructor = ClassDB.instantiate.bind(clsname)
	for prop in ClassDB.class_get_property_list(clsname):
		if prop.usage & PROP_WHITELIST and not prop.usage & PROP_BLACKLIST:
			pc.allowed_properties[prop.name] = true  # prop

	class_registry[clsname] = pc
	return pc


## Returns true if this custom class has been registered, otherwise false.
func has_custom_class(scr: Script) -> bool:
	var clsname := scr.get_global_name()
	if clsname.is_empty():
		return false
	return clsname in class_registry


## Returns true if this native class has been registered, otherwise false.
func has_native_class(clsname: String):
	return clsname in class_registry


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


## Pickle the arbitary GDScript data to a PackedByteArray.
func pickle_compressed(obj) -> PackedByteArray:
	return var_to_bytes(pre_pickle(obj)).compress(compression_mode)


## Unpickle the PackedByteArray to arbitrary GDScript data.
func unpickle_compressed(buffer: PackedByteArray, buffer_size: int = -1):
	var decomp: PackedByteArray
	if buffer_size > 0:
		decomp = buffer.decompress(buffer_size, compression_mode)
	else:
		decomp = buffer.decompress_dynamic(-1, compression_mode)
	return post_unpickle(bytes_to_var(decomp))


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
			retval = pre_pickle_object(obj)
		# most builtin types are just passed through
		_:
			retval = obj
	return retval


## Preprocess an Object, returning a dictionary representing the object.
func pre_pickle_object(obj: Object):
	var clsname = get_object_class_name(obj)
	if clsname.is_empty() or not clsname in class_registry:
		return null
	var pc: PicklableClass = class_registry[clsname]
	var dict = {}
	if not pc.__getstate__.is_null():
		dict = pc.__getstate__.call(obj)
	else:
		if serialize_defaults or pc.default_object == null:
			for propname in pc.allowed_properties:
				dict[propname] = obj.get(propname)
		else:
			for propname in pc.allowed_properties:
				var value = obj.get(propname)
				if value != pc.default_object.get(propname):
					dict[propname] = obj.get(propname)

	# recursive pre_pickle of the state we just got
	for key in dict:
		dict[key] = pre_pickle(dict[key])

	dict[CLASS_KEY] = clsname

	# TODO: test constructor args that have defaults
	if pc.newargs_len > 0 and not pc.__getnewargs__.is_null():
		dict[NEWARGS_KEY] = pc.__getnewargs__.call(obj)
		for i in range(len(dict[NEWARGS_KEY])):
			dict[NEWARGS_KEY][i] = pre_pickle(dict[NEWARGS_KEY][i])
	return dict


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
			var dict := obj as Dictionary
			if CLASS_KEY in dict:
				retval = post_unpickle_object(dict)
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


## Post-process recently unpickled dictionary that represents an object.
func post_unpickle_object(dict: Dictionary):
	var clsname = dict[CLASS_KEY]
	dict.erase(CLASS_KEY)
	if typeof(clsname) != TYPE_STRING_NAME:
		return null
	if not clsname in class_registry:
		return null
	var pc: PicklableClass = class_registry[clsname]

	var obj = null
	if NEWARGS_KEY in dict:
		if pc.newargs_len > 0 and not pc.__getnewargs__.is_null():
			var newargs: Array = dict[NEWARGS_KEY]
			newargs = newargs.map(post_unpickle)
			obj = pc.constructor.callv(newargs)
		dict.erase(NEWARGS_KEY)
	else:
		obj = pc.constructor.call()

	if obj != null:
		if not pc.__setstate__.is_null():
			for key in dict:
				dict[key] = post_unpickle(dict[key])
			pc.__setstate__.call(obj, dict)
		else:
			for propname in pc.allowed_properties:
				if dict.has(propname):
					var value = post_unpickle(dict[propname])
					match typeof(value):
						TYPE_ARRAY:
							var arr = obj.get(propname) as Array
							if arr.is_typed():
								arr.assign(value)
							else:
								obj.set(propname, value)
						TYPE_DICTIONARY:
							var d2 = obj.get(propname) as Dictionary
							if d2.is_typed():
								d2.assign(value)
							else:
								obj.set(propname, value)
						_:
							obj.set(propname, value)
	return obj
