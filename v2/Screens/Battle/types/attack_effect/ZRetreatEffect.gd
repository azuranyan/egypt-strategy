extends AttackEffect
class_name RetreatEffect
	

const DIRECTIONS := [
	Vector2(1, 0),
	Vector2(0, 1),
	Vector2(-1, 0),
	Vector2(0, -1),
]


func _apply(battle: Battle, user: Unit, _attack: Attack, _target_cell: Vector2i, _target_unit: Unit) -> void:
	var new_pos := Vector2i(user.map_pos - DIRECTIONS[user.get_heading()])
	
	if battle.is_placeable(user, new_pos):
		# TODO animate
		user.map_pos = new_pos
	
	
func _default_description() -> String:
	return 'Retreats 1 tile.'


func _default_animation() -> String:
	return 'none'