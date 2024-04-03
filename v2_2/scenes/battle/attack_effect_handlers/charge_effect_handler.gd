extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is ChargeEffect


@warning_ignore("unused_parameter")
func execute(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	var angle := state.user.get_position().angle_to_point(target.cell())
	var direction := roundi(angle/(PI/2)) % 4
	var new_pos := Map.cell(Vector2(target.cell() - Map.DIRECTIONS[direction]))
	
	if state.user.is_placeable(new_pos):
		state.user.set_heading(Map.to_heading(angle))
		if attack_effect.speed == 0:
			state.user.set_position(new_pos)
		else:
			var duration: float = state.user.get_position().distance_to(new_pos)/attack_effect.speed
			var tween := create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(state.user.get_map_object(), 'map_position', new_pos, duration)
			await tween.finished
		