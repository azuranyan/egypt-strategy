class_name BackstabEffect
extends AttackEffect
	

const DIRECTIONS := [
	Vector2(1, 0),
	Vector2(0, 1),
	Vector2(-1, 0),
	Vector2(0, -1),
]


func apply(battle: Battle, user: Unit, attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	var new_pos := Vector2i(target_unit.map_pos - DIRECTIONS[target_unit.get_heading()])
	
	if user.is_placeable(new_pos) and battle.map.is_inside_bounds(new_pos):
		# TODO animate
		user.map_pos = new_pos
		user.face_towards(target_unit.map_pos)
	attack.effect_complete(self)
	
