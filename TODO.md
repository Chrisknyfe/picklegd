
# TODO
- Multiplayer Example: TCP server for larger packets in the example, UDP fragmentation starts at 1392 byte packets.

# TODO after seeing KoBeWi's serializer: https://godotengine.org/asset-library/asset/3167
- roll registry back into Pickler, with no numeric ID's: only I use that feature for shortening block type names to numeric IDs in my game.
- copy Registry back to my game, along with unit tests
- remove BasePickler: we don't want a version that doesn't have a registry, that's a security hole. They can subclass Pickler if they like.
- RegisteredClass.custom_class_def could just be a pointer to the constructor Callable
- RegisteredClass could store Callables for getstate and setstate.
	- no custom setstate in class Script? just use pickler default setstate.
	- otherwise set custom setstate to CustomClass.__setstate__
	- returning a RegisteredClass, you can override __setstate__.
	- so now RegisteredClass has
		- name
		- constructor
		- getnewargs
		- getstate
		- getstate
- I never thought I would have to assign/overwrite an array's values like so:
			if value is Array:
				object.get(property).assign(value)
			else:
				object.set(property, value)
	do I need to also assign to dictionaries?
- Consider using serialize_defaults
- get_pickleable_properties() can be unrolled into the default getstate and setstate

# TODO after seeing Seriously by freehuntx https://godotengine.org/asset-library/asset/2469
I don't like how he constructs a custom object by building source code. No.
