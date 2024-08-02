class_name Registry
extends Node

## A generic registry. keeps track of a collection of object types (blocks, entities, items etc.)

var next_available_id = 0
var by_name = {}
var by_id = {}

# Stores mapping of names to ID's, for when older maps are loaded and conflicts need to be resolved.
var name_to_id = {}
var id_to_name = {}


func clear():
	next_available_id = 0
	by_name.clear()
	by_id.clear()
	name_to_id.clear()
	id_to_name.clear()


func _ready():
	clear()


func register(behavior: RegisteredBehavior):
	# Insert block type into the library
	if not behavior.name:
		push_error("Cannot register with empty name")
		return null

	# if association exists, just use that id
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

	if behavior.name in by_name:
		print(
			"Cannot add behavior type, name " + behavior.name + " already in use!"
		)
		return null
	by_name[behavior.name] = behavior
	by_id[behavior.id] = behavior
	return behavior


func get_by_name(behavior_name: String):
	return by_name[behavior_name]
	
func has_by_name(behavior_name: String):
	return behavior_name in by_name


func get_by_id(id: int):
	return by_id[id]
	
func has_by_id(id: int):
	return id in by_id


# Before registering types, these associations should be loaded first. Either from:
# - a multiplayer server (if we are the client)
# - a save file (if we are loading a save in singleplayer or as a server)
#
# TODO: allow the ability to override associations after registering content.
func add_name_to_id_associations(assoc: Dictionary):
	for behavior_name in assoc:
		add_name_to_id_association(behavior_name, assoc[behavior_name])


func add_name_to_id_association(behavior_name: String, id: int):
	print("Loading association: " + behavior_name + " ==> " + str(id))

	if behavior_name in name_to_id:
		if id != name_to_id[behavior_name]:
			print(
				"Cannot associate "
				+ behavior_name
				+ " with ID "
				+ str(id)
				+ ", name is already bound to ID "
				+ str(name_to_id[behavior_name])
			)
		return false
	if id in id_to_name:
		print(
			"Cannot associate "
			+ behavior_name
			+ " with ID "
			+ str(id)
			+ ", ID is already bound to name "
			+ id_to_name[id]
		)
		return false
	name_to_id[behavior_name] = id
	id_to_name[id] = behavior_name


func get_associations():
	return name_to_id


func finalize():
	# TODO: ensure all registered types have associations
	pass
