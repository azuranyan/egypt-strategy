class_name UnitTypeEntry
extends Resource

@export var unit_type: UnitType = preload("res://scenes/battle/unit/data/placeholder_unit_type.tres")
@export var count: int = 1


func _to_string() -> String:
	return '<"%s": %s>' % [unit_type.character_info.name, count]
