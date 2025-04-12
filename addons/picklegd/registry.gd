class_name Registry
extends RefCounted
## A [Registry] which keeps track of a collection of values
## accessible by two types of keys: string names and numeric IDs.
##
## When you add a name/value pair to a Registry, the registry creates a new numeric ID
## for you (or gives you a previously associated numeric ID.) This creates a three-way
## association
## [br][br]
## Can be used, for example, to assign numeric ID's to inventory items to reduce
## the size of your inventory data structure. I use a [Registry] in the [Pickler]
## to assign numeric ID's to Object class types.
## [br][br]
## If you pass a [RegisteredObject] to [method Registry.register], 
## the Registry will automatically assign the name and ID for you.
## [br][br]
## Inspired by [url]https://nekoyue.github.io/ForgeJavaDocs-NG/javadoc/1.16.5/net/minecraftforge/registries/ForgeRegistry.html[/url]

const ID_INVALID = -1

## The next ID that will be used when a new class is registered.
var next_available_id = 0

## Mapping from names to stored objects.
var by_name: Dictionary[StringName, Variant] = {}
## Mapping from ID's to stored objects.
var by_id: Dictionary[int, Variant] = {}


## Mapping from names to ID's.
var name_to_id: Dictionary[StringName, int] = {}
## Mapping from ID's to names. No need for name_to_id.find_key(id)
var id_to_name: Dictionary[int, StringName] = {}


## Clears all RegisteredBehaviors from this Registry.
func clear():
	next_available_id = 0
	by_name.clear()
	by_id.clear()
	name_to_id.clear()
	id_to_name.clear()


## Makes a shallow duplication of this [Registry].
func duplicate() -> Registry:
	var reg = Registry.new()
	reg.by_name = by_name.duplicate()
	reg.by_id = by_id.duplicate()
	reg.name_to_id = name_to_id.duplicate()
	reg.id_to_name = id_to_name.duplicate()
	return reg
	
	
func register(name: StringName, obj: Variant = null) -> int:
	if name.is_empty() or name in by_name:
		# TODO: allow overwrite? maybe a different function
		return ID_INVALID
	var new_id: int
	if name in name_to_id:
		new_id = name_to_id[name]
	else:
		while next_available_id in by_id:
			next_available_id += 1
		new_id = next_available_id
		next_available_id += 1
		name_to_id[name] = new_id
	id_to_name[new_id] = name
	by_name[name] = obj
	by_id[new_id] = obj
	if obj is RegisteredObject:
		obj.name = name
		obj.id = new_id
	return new_id


func unregister(name: StringName) -> bool:
	#if not is_entry_valid(name):
		#return false
	var id = name_to_id[name]
	var success = true
	success = success and by_name.erase(name)
	success = success and by_id.erase(id)
	success = success and name_to_id.erase(name)
	success = success and id_to_name.erase(id)
	return success
	


## Get the value keyed by this name.
func get_by_name(name: String):
	return by_name[name]


## See if this registry has a value keyed by this name.
func has_by_name(name: String):
	return name in by_name


## Get the value keyed by this numeric ID.
func get_by_id(id: int):
	return by_id[id]


## See if this registry has a value keyed by this numeric ID.
func has_by_id(id: int):
	return id in by_id


func find_id(name: StringName):
	return name_to_id[name]


func find_name(id: int):
	return id_to_name[id]


func size():
	return by_name.size()
	
func names():
	return by_name.keys()
	
func ids():
	return by_id.keys()
	
func values():
	return by_name.values()


# TODO: allow the ability to override associations after registering content.
## Add a previously-defined set of associations between names and numeric ID's.
##
## Use this when you want your [Registry] to remain backwards compatible
## as you update it with new things. 
## Get the list of associations with
## [method get_associations], save them to file, 
## then load them from file and pass them to 
## [method merge_associations].
## [br]
## `assoc` should be keyed by name, with numeric ID's as values.
## [br]
## Returns whether all associations were stored without errors.
func merge_associations(assoc: Dictionary[StringName, int]) -> bool:
	# check that `assoc` is consistent with current associations
	for name in assoc:
		var id = assoc[name]
		if name in name_to_id or id in id_to_name:
			if name_to_id[name] != id or id_to_name[id] != name:
				return false
	# associate
	for name in assoc:
		var id = assoc[name]
		name_to_id[name] = id
		id_to_name[id] = name
	return true


## Add a previously-defined association between a name and a numeric ID.
## [br]
## Returns true if the association succeeded, 
## or if name and id were already associated to each other.
func associate(name: String, id: int) -> bool:
	# check that `name` and `id` are consistent with current associations
	if name in name_to_id or id in id_to_name:
		return name_to_id[name] == id and id_to_name[id] == name
	# associate
	name_to_id[name] = id
	id_to_name[id] = name
	return true


## Get the associations between names and numeric ID's.
## Use this when you want your [Registry] to remain backwards compatible
## as you update it with new things. 
## Get the list of associations with
## [method get_associations], save them to file, 
## then load them from file and pass them to 
## [method merge_associations].
func get_associations() -> Dictionary[StringName, int]:
	return name_to_id


func is_entry_valid(name:StringName) -> bool:
	if name.is_empty():
		return false
	if name not in by_name or name not in name_to_id:
		return false
	var id = name_to_id[name]
	if id not in by_id or id not in id_to_name:
		return false
	if id_to_name[id] != name:
		return false
	if not is_same(by_name[name], by_id[id]):
		return false
	if by_name[name] is RegisteredObject:
		if by_name[name].name != name or by_name[name].id != id:
			return false
	return true

## Check that this entire table is valid. There's a lot of moving parts.
## Returns true if all internal tables are consistent.
func is_valid() -> bool:
	var s = by_name.size()
	if by_id.size() != s or name_to_id.size() != s or id_to_name.size() != s:
		return false
	for name in by_name:
		if not is_entry_valid(name):
			return false
	return true
