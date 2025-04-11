extends RefCounted
class_name BigClassThing

var foo: String = "bluh"
var baz: float = 4.0
var qux: String = "x"
var builtins: Array = [
	# refer to @GlobalScope.Variant.Type enum in Godot 4.4
	null,
	true,
	2,
	3.0,
	"four",
	Vector2(5.0,5.0),
	Vector2i(6,6),
	Rect2(7.0, 7.0, 7.0, 7.0),
	Rect2i(8,8,8,8),
	Vector3(9.0,9.0,9.0),
	Vector3i(10,10,10),
	Transform2D(),
	Vector4(12.0,12.0,12.0,12.0),
	Vector4i(13,13,13,13),
	Plane(),
	Quaternion(),
	AABB(),
	Basis(),
	Transform3D(),
	Projection(),
	Color(0.5, 0.5, 0.5, 0.5),
	StringName("twenty_one"),
	NodePath(),
	#RID(), # type 23 rejected type because it's an internal ID
	#Object.new(),
	#Callable(), # type 25 rejected type because it's code-over-the-wire
	#Signal(), # type 26 rejected type because it's code-over-the-wire
	Dictionary(),
	Array(),
	PackedByteArray([29,29,29,29]),
	PackedInt32Array([30,30,30,30]),
	PackedInt64Array([31,31,31,31]),
	PackedFloat32Array([32.0,32.0,32.0,32.0]),
	PackedFloat64Array([33.0,33.0,33.0,33.0]),
	PackedStringArray(["thirty", "four"]),
	PackedVector2Array([Vector2(35,35),Vector2(35,35)]),
	PackedVector3Array([Vector3(36,36,36),Vector3(36,36,36)]),
	PackedColorArray([Color(0.3,0.7,0.0),Color(0.3,0.7,0.0)]),
	PackedVector4Array([Vector4(38.0,38.0,38.0,38.0),Vector4(38.0,38.0,38.0,38.0)]),
]

var refcounteds := []
