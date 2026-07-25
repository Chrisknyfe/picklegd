# TODO
- Multiplayer Example: TCP server for larger packets in the example, UDP fragmentation starts at 1392 byte packets.
- Create example/picklegd/basic_example.tscn. include binary pickles, compression, strings, saving to file
- Create example/picklegd/advanced_example.tscn. 
    - include __setstate__ and overriding it differently for different pickles. 
    - include use of __getnewargs__ for classes that require constructor parameters
    - include using PicklableClass.allowed_properties. 
    - include Pickler.serialize_defaults
- Picklestudio should show you the contents of the pickle, either in text or in a hex editor format.
- Attempt to create a system where you can give inner classes a class name which the pickler can detect, using a const. 
https://github.com/Chrisknyfe/picklegd/pull/4
```
# For example:
class ExampleClass:
    const __CLASS_NAME__ = "ExampleClass"
```