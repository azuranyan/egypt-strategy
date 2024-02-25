extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is MoveEffect


@warning_ignore("unused_parameter")
func execute(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	var origin := get_origin(state, target_index, attack_effect, target)
	var rotation := get_rotation(state, target_index, attack_effect, target)
	var new_pos := Map.cell(Vector2(origin + attack_effect.offset).rotated(rotation))
	if attack_effect.speed == 0:
		state.user.set_position(new_pos)
	else:
		var duration: float = state.user.get_position().distance_to(new_pos)/attack_effect.speed
		var tween := create_tween()
		tween.tween_property(target.get_map_object(), 'map_position', new_pos, duration)


func get_origin(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> Vector2:
	match attack_effect.origin:
		MoveEffect.Origin.USER:
			return state.user.get_position()
		MoveEffect.Origin.TARGET_UNIT:
			return target.get_position()
		MoveEffect.Origin.TARGET_CELL, _:
			return state.target_cells[target_index]


func get_rotation(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> float:
	match attack_effect.direction:
		MoveEffect.Direction.ATTACK_ROTATION:
			return state.target_rotations[target_index]
		MoveEffect.Direction.USER_FORWARD:
			return Map.to_facing(state.user.get_heading())
		MoveEffect.Direction.TARGET_UNIT_FORWARD:
			return Map.to_facing(target.get_heading())
		MoveEffect.Direction.USER_TO_TARGET:
			return state.user.get_position().angle_to_point(target.get_position())
		MoveEffect.Direction.TARGET_TO_USER:
			return target.get_position().angle_to_point(state.user.get_position())
		MoveEffect.Direction.ABSOLUTE, _:
			return 0