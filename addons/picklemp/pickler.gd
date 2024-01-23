extends Resource
class_name Pickler

"""The default pickler"""

func pickle(obj, registry):
	return JSON.stringify({})
	
func unpickle(datastruct, registry):
	return JSON.parse_string(datastruct)
