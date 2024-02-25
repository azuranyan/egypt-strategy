extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is BackstabEffect


@warning_ignore("unused_parameter")
func execute(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	var new_pos := Map.cell(target.get_position() - Map.DIRECTIONS[target.get_heading()])

	if state.user.is_placeable(new_pos):
		state.user.set_position(new_pos)
		state.user.face_towards(target.get_position())
	
	