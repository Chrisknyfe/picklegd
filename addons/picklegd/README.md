# PickleGD
PickleGD is a Godot asset for safely serializing arbitrary godot data structures, 
including custom classes, over multiplayer and to disk.

Tested with: Godot Engine v4.4.stable.official.4c311cbee 

This is a system for "pickling" GDScript objects to byte arrays, using native 
var_to_bytes plus some code inspection magic. It's meant to make it easy for you
to send complex data structures (such as large custom classes) over the network
to multiplayer peers, or to create your own save system. PickleGD is designed
to prevent arbitrary code execution in the serialization and deserialization
process.

Note: this asset is not compatible with Python's pickle format.

# Quick Start example

To get started pickling your data, first create a pickler.

```
var pickler = Pickler.new()
```

If you have custom classes you want to register, register them at scene load time:
```
pickler.register_custom_class(CustomClassOne)
pickler.register_custom_class(CustomClassTwo)
```

If you want to register godot engine native classes, you must use the class name
as a string:
```
pickler.register_native_class("Node2D")
```

Now you are ready to pickle your data! On the sender's side, just pass your data
to `picker.pickle()`, send the resulting PackedByteArray, then at the receiver's
side pass the PackedByteArray to `pickler.unpickle()`.

```
var data = {
		"one": CustomClassOne.new(),
		"things": ["str", 42, {"foo":"bar"}, [1,2,3], true, false, null],
		"node": Node2D.new(),
	}
var pba: PackedByteArray = pickler.pickle(data)

# "unpickled" should be the same as "data"
var unpickled = pickler.unpickle(pba)
```

# Compressing a pickle

You can create smaller pickles by setting `Pickler.serialize_defaults` to `false`,
which removes default values from pickled Objects.

You can create compressed binary pickles using `Pickler.pickle_compressed()`.

# Customizing a pickle

You can also have direct control over which properties are serialized/deserialized by adding
`__getnewargs__()`,
`__getstate__()` and `__setstate__()` methods to your custom class.
The [Pickler] will first call `__getnewargs__()` to get the arguments for the
object's constructor, then
will call `__getstate__()` to retrieve an Object's properties during
serialization, and later will call `__setstate__()` to set an Object's properties
during deserialization. You may also use these methods to perform
input validation on an Object's properties.

`__getnewargs__()` takes no arguments, and must return an Array.

`__getstate__()` takes no arguments, and must return a Dictionary.

`__setstate__()` takes one argument, the state Dictionary, and has no return value.

For example:
```
extends Resource
class_name CustomClassNewargs

var foo: String = "bluh"
var baz: float = 4.0
var qux: String = "x"

func _init(new_foo: String):
    foo = new_foo

func __getnewargs__() -> Array:
    return [foo]

func __getstate__() -> Dictionary:
    return {"1": baz, "2": qux}

func __setstate__(state: Dictionary):
    baz = state["1"]
    qux = state["2"]
```