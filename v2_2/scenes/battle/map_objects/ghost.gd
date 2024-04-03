@tool
class_name Ghost
extends MapObject


@export var ghosted_unit: Unit:
	set(value):
		if ghosted_unit == value:
			return

		if _model:
			remove_child(_model)
			_model.queue_free()
			_model = null

		ghosted_unit = value

		if not is_node_ready():
			await ready

		_model = _create_duplicate_unit_model(ghosted_unit)
		add_child(_model)
		

@onready var _model: UnitModel


func _create_duplicate_unit_model(unit: Unit) -> UnitModel:
	if unit and unit.get_map_object() is UnitMapObject:
		return unit.get_map_object().unit_model.duplicate()
	else:
		return UnitMapObject.BasicUnitModel.instantiate()