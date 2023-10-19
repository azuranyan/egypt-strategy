extends AttackEffect
class_name BackstabEffect
	

const DIRECTIONS := [
	Vector2(1, 0),
	Vector2(0, 1),
	Vector2(-1, 0),
	Vector2(0, -1),
]


func apply(battle: Battle, user: Unit, _attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	var new_pos := Vector2i(target_unit.map_pos - DIRECTIONS[target_unit.get_heading()])
	
	if battle.is_placeable(user, new_pos):
		# TODO animate
		user.map_pos = new_pos
		user.face_towards(target_unit.map_pos)
	
	
func _default_description() -> String:
	return 'Teleports user behind target.'


func _default_animation() -> String:
	return 'none'
