class_name Pickler
extends BasePickler
## A system for safely serializing and deserializing arbitrary GDScript data.
##
## This is a system for serializing GDScript objects to byte arrays, using native
## var_to_bytes plus some class inspection magic, to safely handle data without
## allowing attackers to inject malicious code into your game. The Pickler makes
## it easy for you to send complex composite data structures (such as deeply nested
## dictionaries, or large custom classes) over the network to multiplayer peers,
## or to disk to save your game's data.
## [br][br]
## Why should you use the Pickler instead of Godot's built-in tools for serialization,
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
## You can also have direct control over which properties are serialized/deserialized by adding
## [code]__getstate__()[/code] and [code]__setstate__()[/code] methods to your custom class.
## The Pickler will call [code]__getstate__()[/code] to retrieve an Object's properties during
## serialization, and later will call [code]__setstate__()[/code] to set an Object's properties
## during deserialization. You may also use these methods to perform
## input validation on an Object's properties.
## [br]For example:
## [codeblock lang=gdscript]
## class_name CustomClassTwo
##
## const MAX_FOO: float = 5.0
## var foo: float = 4.0
##
## func __getstate__() -> Dictionary:
##     return {"foo": foo}
##
## func __setstate__(state: Dictionary):
##     if foo <= MAX_FOO:
##         foo = state["foo"]
## [/codeblock]
## If you want more control over the objects and properties you pickle,
## you can extend [BasePickler] .

## Registry of classes that are allowed to be pickled.
var class_registry: Registry = Registry.new()


## Register a custom class that can be pickled with this pickler. Returns the
## [RegisteredBehavior] object representing this custom class.
func register_custom_class(c: Script) -> RegisteredClass:
	"""Register a custom class."""
	var rc = RegisteredClass.new()
	rc.name = c.get_global_name()
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


## Get an ID for this object's class, if the class is registered
func get_object_class_id(obj: Object):
	var scr = obj.get_script()
	var obj_class_name = null
	if scr != null:
		obj_class_name = scr.get_global_name()
	else:
		obj_class_name = obj.get_class()
	if not class_registry.has_by_name(obj_class_name):
		push_warning("Object class type unregistered: ", obj_class_name)
		return null
	var reg: RegisteredBehavior = class_registry.get_by_name(obj_class_name)
	return reg.id


## Create an instance of this class from its ID, if the ID is registered.
func instantiate_from_class_id(id) -> Object:
	if typeof(id) != TYPE_INT:
		return null
	if not class_registry.has_by_id(id):
		push_warning("Object class ID unregistered: ", id)
		return null
	var reg: RegisteredClass = class_registry.get_by_id(id)
	return reg.instantiate()
