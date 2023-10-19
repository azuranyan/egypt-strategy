extends AttackEffect
class_name MoveEffect
	

@export var face_target: bool


func apply(_battle: Battle, _user: Unit, attack: Attack, target_cell: Vector2i, target_unit: Unit) -> void:
	target_unit.map_pos = target_cell
	if face_target:
		target_unit.face_towards(target_cell)
	
	
func _default_description() -> String:
	return "Instantly moves unit towards target."


func _default_animation() -> String:
	return 'none'
