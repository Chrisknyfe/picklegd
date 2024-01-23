extends Resource
class_name Pickler

"""The default pickler"""

func pickle(obj:Object, registry:PicklerRegistry):
	return JSON.stringify({})
	
func unpickle(datastruct, registry):
	return JSON.parse_string(datastruct)
