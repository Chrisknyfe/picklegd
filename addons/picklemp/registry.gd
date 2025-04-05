class_name Registry
extends RefCounted
## A generic registry which keeps track of a collection of [RegisteredBehavior].
##
## Can be used to store, for example, weapon types for your game. Or to register custom class types.
## Inherit from RegisteredBehavior to customize the types you are storing.

## The next ID that will be used when a new class is registered.
var next_available_id = 0

## Mapping from names to ID's.
var by_name = {}
## Mapping from ID's to names.
var by_id = {}

## Stores mapping of names to numeric ID's, for when older maps are loaded
## and conflicts need to be resolved.
var name_to_id = {}
## Stores mapping of numeric ID's to names.
var id_to_name = {}


## Clears all RegisteredBehaviors from this Registry.
func clear():
	next_available_id = 0
	by_name.clear()
	by_id.clear()
	name_to_id.clear()
	id_to_name.clear()


## Register a RegisteredBehavior with this registry, which can later be retrieved by name or ID.
func register(behavior: RegisteredBehavior) -> RegisteredBehavior:
	# First make sure we can register with this name
	if not behavior.name:
		push_error("Cannot register with empty name")
		return null
	if behavior.name in by_name:
		print("Cannot add behavior type, name " + behavior.name + " already in use!")
		return null
	by_name[behavior.name] = behavior

	# Find the ID for this name, or get a new ID if there isn't one already.
	if behavior.name in name_to_id:
		print(
			"found associated id {0} for behavior {1}".format(
				[name_to_id[behavior.name], behavior.name]
			)
		)
		behavior.id = name_to_id[behavior.name]
	else:
		# get a valid id if one has not already been chosen
		while next_available_id in id_to_name:
			print(
				(
					"id "
					+ str(next_available_id)
					+ " already belongs to "
					+ id_to_name[next_available_id]
					+ " incrementing..."
				)
			)
			next_available_id += 1
		behavior.id = next_available_id
		next_available_id += 1
		name_to_id[behavior.name] = behavior.id
		id_to_name[behavior.id] = behavior.name
	by_id[behavior.id] = behavior
	return behavior


## Get a RegisteredBehavior by looking up its name.
func get_by_name(behavior_name: String):
	return by_name[behavior_name]


## See if this registry has a RegisteredBehavior by looking up its name.
func has_by_name(behavior_name: String):
	return behavior_name in by_name


## Get a RegisteredBehavior by looking up its numeric ID.
func get_by_id(id: int):
	return by_id[id]


## See if this registry has a RegisteredBehavior by looking up its numeric ID.
func has_by_id(id: int):
	return id in by_id


# TODO: allow the ability to override associations after registering content.
## Add a previously-defined set of associations between a name and a numeric ID.
##
## Use this when you have a set of RegisteredBehaviors that must remain backwards compatible
## as you update your game with new RegisteredBehaviors. Get the list of associations with
## get_associations(), save them to file, then load them later into this function.
##
## `assoc` should be keyed by name, with numeric ID's as values.
## Returns whether all associations were stored without errors.
func add_name_to_id_associations(assoc: Dictionary):
	var retval = true
	for behavior_name in assoc:
		if not add_name_to_id_association(behavior_name, assoc[behavior_name]):
			retval = false
	return retval


## Add a previously-defined association between a name and a numeric ID.
##
## Use this when you have a set of RegisteredBehaviors that must remain backwards compatible
## as you update your game with new RegisteredBehaviors.
##
## Returns whether the association was stored without errors.
func add_name_to_id_association(behavior_name: String, id: int):
	print("Loading association: " + behavior_name + " ==> " + str(id))

	if behavior_name in name_to_id:
		if id != name_to_id[behavior_name]:
			print(
				(
					"Cannot associate "
					+ behavior_name
					+ " with ID "
					+ str(id)
					+ ", name is already bound to ID "
					+ str(name_to_id[behavior_name])
				)
			)
		return false
	if id in id_to_name:
		print(
			(
				"Cannot associate "
				+ behavior_name
				+ " with ID "
				+ str(id)
				+ ", ID is already bound to name "
				+ id_to_name[id]
			)
		)
		return false
	name_to_id[behavior_name] = id
	id_to_name[id] = behavior_name
	return true


## Get the name-to-ID associations for all RegisteredBehaviors
## Use this when you have a set of RegisteredBehaviors that must remain backwards compatible
## as you update your game with new RegisteredBehaviors. Save these associations to file,
## then load them later with add_name_to_id_associations().
func get_associations():
	return name_to_id
