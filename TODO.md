
# TODO
- Multiplayer Example: TCP server for larger packets in the example, UDP fragmentation starts at 1392 byte packets.
- copy Registry back to my game, along with unit tests
- Test that defaults of all the builtin types get omitted
- Test that defaults are serialized when a class has a custom __getstate__, __setstate__, or __getnewargs__
- make a toggle for using numeric class ID's vs class names
- Hey, can I make Class ID's for object properties? EVEN SMALLER PICKLES
- Benchmark compressed pickle size when numeric class ID's ared disabled (then I don't need a registry)
