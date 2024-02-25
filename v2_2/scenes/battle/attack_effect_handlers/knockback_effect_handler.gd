extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is KnockbackEffect


@warning_ignore("unused_parameter")
func execute(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	var angle := state.user.get_position().angle_to_point(target.get_position())
	var direction := roundi(angle/(PI/2)) % 4
	
	for i in attack_effect.distance:
		var new_pos := get_knockback_pos(target.get_position(), Map.DIRECTIONS[direction], 1)
		if target.is_placeable(new_pos):
			target.set_position(new_pos)
		else:
			target.take_damage(1, 'knockback')
			var occupant := Battle.instance().get_unit_at(new_pos)
			if occupant:
				occupant.take_damage(1, 'knockback')
			break


func get_knockback_pos(origin: Vector2, direction: Vector2, distance: int) -> Vector2:
	return Map.cell(origin + direction * distance)