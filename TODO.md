
# TODO
- Thorougly test few builtin Resources, Nodes, and direct Object subclasses
- Go through unit tests and make sure unnecessary ones are pruned or updated
- make sure I can import the library into my game without needing gdunit4
- rename the plugin to "PickleGD"

# Next version
- TCP server for larger packets in the example, UDP fragmentation starts at 1392 byte packets.
- __getnewargs__ will allow constructor calls with arguments
- Registry: ensure all name-to-ID associations have RegisteredBehaviors in a finalize() call
- Support pickling meta data?
- Support pickling groups?
