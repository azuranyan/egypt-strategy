
@tool
class_name ResourcePropertyAccess
extends Resource


@export var resource: Resource

@export var property: StringName


func value() -> Variant:
	if resource and property in resource:
		return resource.get(property)
	else:
		return null


func _to_string() -> String:
	return str(value())