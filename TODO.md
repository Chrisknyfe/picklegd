
# TODO
- Registry: clobber associations
- Pickler: allow RegisteredClass to have __getstate__ / __setstate__ / __getnewargs__
- Pickler: create some sensible __getstate__ / __setstate__ / __getnewargs__ for some native classes, like SurfaceTool and ArrayMesh.
	- Maybe this could be a "DefaultPickler", which already contains "sensible defaults". Or a "register_native_class_sensibly()"
	function, which adds what I think the defaults should be.
- MP Example: TCP server for larger packets in the example, UDP fragmentation starts at 1392 byte packets.
- Registry: ensure all name-to-ID associations have RegisteredBehaviors in a finalize() call
- Support pickling meta data?
- Support pickling groups?
