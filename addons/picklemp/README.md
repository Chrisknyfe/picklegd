# PickleGD
PickleGD is a Godot asset for serializing arbitrary godot data structures, 
including custom classes, over multiplayer and to disk.

Tested with: Godot Engine v4.3.stable.official.77dcf97d8 

This is a system for "pickling" GDScript objects to byte arrays, using native 
var_to_bytes plus some code inspection magic. It's meant to make it easy for you
to send complex data structures (such as large custom classes) over the network
to multiplayer peers, or to create your own save system.

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
pickler.register_native_class("SurfaceTool")
```

Now you are ready to pickle your data! On the sender's side, just pass your data
to `picker.pickle()`, send the resulting PackedByteArray, then at the receiver's
side pass the PackedByteArray to `pickler.unpickle()`.

```
var data = {
		"one": CustomClassOne.new(),
		"things": ["str", 42, {"foo":"bar"}, [1,2,3], true, false, null],
	}
var pba: PackedByteArray = pickler.pickle(data)

# "unpickled" should be the same as "data"
var unpickled = pickler.unpickle(pba)
```

# API Docs
