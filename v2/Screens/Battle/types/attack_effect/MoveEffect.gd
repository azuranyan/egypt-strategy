class_name MoveEffect
extends AttackEffect
	

@export var face_target: bool


func apply(_battle: Battle, _user: Unit, attack: Attack, target_cell: Vector2i, target_unit: Unit) -> void:
	target_unit.map_pos = target_cell
	if face_target:
		target_unit.face_towards(target_cell)
	attack.effect_complete(self)
	
