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
const CLASS_KEY = "__CLS"
const NEWARGS_KEY = "__NEW"


## Registry of classes that are allowed to be pickled.
var class_registry: Registry = Registry.new()

var serialize_defaults := false

var compression_mode: FileAccess.CompressionMode = FileAccess.COMPRESSION_DEFLATE 

## Get a name for this object's class. 
## Returns the obj's class name,
## or null if there's no class name for this object.
func get_object_class_name(obj: Object) -> String:
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
func register_custom_class(scr: Script) -> RegisteredClass:
	var gname := scr.get_global_name()
	if gname.is_empty():
		push_warning("Cannot get custom class name")
		return null
	
	var rc = RegisteredClass.new()
	rc.name = gname
	
	# Interrogate the class at registration time to speed up pickling / unpickling	
	rc.constructor = scr.new
	
	var methods = scr.get_script_method_list()
	rc.serialize_defaults = serialize_defaults
	for method in methods:
		match method.name:
			"_init":
				rc.newargs_len = len(method.args)
				if rc.newargs_len > 0:
					rc.serialize_defaults = true
			"__getnewargs__":
				rc.__getnewargs__ = _object_getnewargs
				rc.serialize_defaults = true
			"__getstate__":
				rc.__getstate__ = _object_getstate
				rc.serialize_defaults = true
			"__setstate__":
				rc.__setstate__ = _object_setstate
				rc.serialize_defaults = true
	
	if rc.newargs_len == 0 and not rc.serialize_defaults:
		rc.default_object = scr.new()
	
	var proplist = scr.get_script_property_list()
	for prop in proplist:
		if prop.usage & PROP_WHITELIST and not prop.usage & PROP_BLACKLIST:
			rc.allowed_properties[prop.name] = prop
	
	return class_registry.register(rc) as RegisteredClass


## Register a godot engine native class. 
## cls_name must match the name returned by instance.class_name().
## Returns the [RegisteredBehavior] object representing this native class.
func register_native_class(cls_name: String) -> RegisteredClass:
	if not ClassDB.class_exists(cls_name):
		push_warning("Native class is not recognized: ", cls_name)
		return null
	if not ClassDB.can_instantiate(cls_name):
		push_warning("Native class cannot be instantiated: ", cls_name)
		return null
		
	var rc = RegisteredClass.new()
	rc.name = cls_name
	rc.constructor = ClassDB.instantiate.bind(cls_name)
	for prop in ClassDB.class_get_property_list(cls_name):
		if prop.usage & PROP_WHITELIST and not prop.usage & PROP_BLACKLIST:
			rc.allowed_properties[prop.name] = prop
	
	return class_registry.register(rc) as RegisteredClass

func has_custom_class(scr: Script) -> bool:
	var gname := scr.get_global_name()
	if gname.is_empty():
		return false
	return class_registry.has_by_name(gname)
	
func has_native_class(cls_name: String):
	return class_registry.has_by_name(cls_name)

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

func pre_pickle_object(obj: Object):
	var clsname = get_object_class_name(obj)
	if clsname.is_empty() or not clsname in class_registry.by_name:
		return null
	var reg: RegisteredClass = class_registry.by_name[clsname]
	var dict = {}
	if not reg.__getstate__.is_null():
		dict = reg.__getstate__.call(obj)
	else:
		if reg.serialize_defaults:
			for propname in reg.allowed_properties:
				dict[propname] = obj.get(propname)
		else:
			for propname in reg.allowed_properties:
				var value = obj.get(propname)
				if value != reg.default_object.get(propname):
					dict[propname] = obj.get(propname)
	
	# recursive pre_pickle of the state we just got
	for key in dict:
		dict[key] = pre_pickle(dict[key])
	
	dict[CLASS_KEY] = reg.id
	
	# TODO: test constructor args that have defaults
	if reg.newargs_len > 0 and not reg.__getnewargs__.is_null():
		dict[NEWARGS_KEY] = reg.__getnewargs__.call(obj)
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
	var clsid = dict[CLASS_KEY]
	dict.erase(CLASS_KEY)	
	if typeof(clsid) != TYPE_INT:
		return null
	if not clsid in class_registry.by_id:
		return null
	var reg: RegisteredClass = class_registry.by_id[clsid]
	
	var obj = null
	if NEWARGS_KEY in dict:
		if reg.newargs_len > 0 and not reg.__getnewargs__.is_null():
			var newargs: Array = dict[NEWARGS_KEY]
			newargs = newargs.map(post_unpickle)
			obj = reg.constructor.callv(newargs)
		dict.erase(NEWARGS_KEY)
	else:
		obj = reg.constructor.call()
		
	if obj != null:
		if not reg.__setstate__.is_null():
			for key in dict:
				dict[key] = post_unpickle(dict[key])
			reg.__setstate__.call(obj, dict)
		else:
			for propname in reg.allowed_properties:
				if dict.has(propname):
					obj.set(propname, post_unpickle(dict[propname]))
	return obj
