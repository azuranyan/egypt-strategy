extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is ChargeEffect


@warning_ignore("unused_parameter")
func execute(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	var angle := state.user.get_position().angle_to_point(target.get_position())
	var direction := roundi(angle/(PI/2)) % 4
	var new_pos := Map.cell(Vector2(target.get_position() - Map.DIRECTIONS[direction]))
	
	if state.user.is_placeable(new_pos):
		if attack_effect.speed == 0:
			state.user.set_position(new_pos)
		else:
			var duration: float = attack_effect.speed/state.user.get_position().distance_to(new_pos)
			var tween := create_tween()
			tween.tween_property(target.get_map_object(), 'map_position', new_pos, duration)
		state.user.set_heading(Map.to_heading(angle))
		