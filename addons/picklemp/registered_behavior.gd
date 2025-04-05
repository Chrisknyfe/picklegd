class_name RegisteredBehavior
extends Resource
## A registered behavior to be registered in a [Registry].
##
## Extend this class to implement your own custom item types, weapon types,
## class types, whatever types you're keeping a registry for.

## Name of the behavior. Can be used to retrieve this from a [Registry].
@export var name: String = ""

## Numeric ID to encode this behavior when serialized.
## Can be used to retrieve this from a [Registry].
@export var id: int = 0
