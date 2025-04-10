class_name BasePickler
extends RefCounted

## A system for serializing and deserializing arbitrary GDScript data.
##
## This is a system for serializing GDScript objects to byte arrays, using native
## var_to_bytes plus some class inspection magic, to safely handle data without
## allowing attackers to inject malicious code into your game. [BasePickler] makes
## it easy for you to send complex composite data structures (such as deeply nested
## dictionaries, or large custom classes) over the network to multiplayer peers,
## or to disk to save your game's data.
## [br][br]
## [BasePickler] is a base class which allows all class types to be pickled by
## default. This may be insecure. See [Pickler] for a safer option that only
## allows whitelisted classes to be pickled.
## [br][br]
## Why should you use a [Pickler] instead of Godot's built-in tools for serialization,
## such as plain [method @GlobalScope.var_to_bytes],
## [method @GlobalScope.var_to_bytes_with_objects], or
## [ResourceLoader]? In the case of the var_to_bytes family of methods,
## an attacker can change the script path of any serialized [Object], causing your deserialized data
## to behave in unwanted ways. Using ResourceLoader will execute any custom code
## in the [Resource] files being loaded.
## [br][br]
## [BasePickler] attempts to prevent malicious code injection by:
## [br] -  Filtering out unsafe properties, such as "script" or "script/source"
## [br] -  Allowing you fine-grained control over serialized data using
## [code]__getstate__()[/code] and [code]__setstate__()[/code] methods you provide.
## [br][br]
## Serializing data with [BasePickler] is simple. For example:
## [codeblock lang=gdscript]
## var data = {"one": CustomClassOne.new(), "two": 2}
## var pickler = BasePickler.new()
## var pickle: PackedByteArray = pickler.pickle(data)
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
## The [BasePickler] will first call [code]__getnewargs__()[/code] to get the arguments for the
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
## For example:
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
