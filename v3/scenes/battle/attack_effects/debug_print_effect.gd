class_name DebugPrintEffect
extends AttackEffect


@export var format: String


func execute(state: AttackState, target: UnitState) -> void:
	if not Game.debug:
		return
	print(format.format({
		attack = state.attack,
		user = state.user,
		target = target,
		target_cell = state.target_cell,
		target_rotation = state.target_rotation,
		target_units = state.target_units,
		data = state.data,
	}))
