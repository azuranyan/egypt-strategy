extends AttackEffect
class_name KnockbackEffect
	

const DIRECTIONS := [
	Vector2(1, 0),
	Vector2(0, 1),
	Vector2(-1, 0),
	Vector2(0, -1),
]


func _apply(battle: Battle, user: Unit, _attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	var angle := user.map_pos.angle_to_point(target_unit.map_pos)
	var direction := roundi(angle/(PI/2)) % 4
	var new_pos := Vector2i(target_unit.map_pos + DIRECTIONS[direction])
	
	# TODO check if new_pos has unit, if there is then damage both by 1
	if battle.is_placeable(target_unit, new_pos):
		# TODO animate
		target_unit.map_pos = new_pos
	else:
		battle.damage_unit(target_unit, self, 1)
	
	
func _default_description() -> String:
	return 'Knocks unit back.'


func _default_animation() -> String:
	return 'none'