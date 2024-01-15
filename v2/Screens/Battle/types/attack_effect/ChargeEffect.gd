class_name ChargeEffect
extends AttackEffect
	

const DIRECTIONS := [
	Vector2(1, 0),
	Vector2(0, 1),
	Vector2(-1, 0),
	Vector2(0, -1),
]


func apply(battle: Battle, user: Unit, attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	var angle := user.map_pos.angle_to_point(target_unit.map_pos)
	var direction := roundi(angle/(PI/2)) % 4
	var new_pos := Vector2i(target_unit.map_pos - DIRECTIONS[direction])
	
	if battle.is_placeable(user, new_pos) and battle.map.is_inside_bounds(new_pos):
		# TODO animate
		user.map_pos = new_pos
		user.facing = angle
	attack.effect_complete(self)
	
