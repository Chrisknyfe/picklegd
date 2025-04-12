class_name RegisteredObject
extends Resource
## A [RegisteredObject] to be tracked in a [Registry].
## 
## Extend this class to implement your own custom item types, weapon types,
## class types, whatever types you're keeping a registry for.
## [br][br]
## If you pass a [RegisteredObject] to [method Registry.register], 
## the Registry will automatically assign the name and ID for you.

## Registered name of the object. Can be used to retrieve this from a [Registry].
@export var name: StringName = &""

## Registered numeric ID to encode this object when serialized.
## Can be used to retrieve this from a [Registry].
@export var id: int = 0
