class_name RetreatEffect
extends AttackEffect
	

const DIRECTIONS := [
	Vector2(1, 0),
	Vector2(0, 1),
	Vector2(-1, 0),
	Vector2(0, -1),
]


func apply(battle: Battle, user: Unit, attack: Attack, _target_cell: Vector2i, _target_unit: Unit) -> void:
	var new_pos := Vector2i(user.map_pos - DIRECTIONS[user.get_heading()])
	
	if user.is_placeable(new_pos) and battle.map.is_inside_bounds(new_pos):
		# TODO animate
		user.map_pos = new_pos
	attack.effect_complete(self)
	
