
# TODO
- Multiplayer Example: TCP server for larger packets in the example, UDP fragmentation starts at 1392 byte packets.

- rename Registry to IDRegistry & RegisteredID
- Too many prints in Registry
- copy Registry back to my game, along with unit tests
- simplify the registry. Call it a TwoWayDictionary, or something. RegisteredBehavior... I do use reg.name and reg.id, but I can get those from the registry itself. So I shouldn't need an explicit class for an element of a TwoWayDictionary.

- Test that defaults of all the builtin types get omitted
- Test that defaults are serialized when a class has a custom __getstate__, __setstate__, or __getnewargs__
- Test that Pickler.pickle_compressed makes smaller pickles, and can be decompressed

- make a toggle for using numeric class ID's vs class names
- Hey, can I make Class ID's for object properties? EVEN SMALLER PICKLES
- Benchmark compressed pickle size when numeric class ID's ared disabled (then I don't need a registry)
