extends AttackEffect
class_name RandomEffect


@export var effects: Array[AttackEffect]


func _apply(battle: Battle, user: Unit, attack: Attack, target_cell: Vector2i, target_unit: Unit) -> void:
	if effects.size() > 0:
		var i = randi_range(0, effects.size() - 1)
		effects[i].apply(battle, user, attack, target_cell, target_unit)
	
	
func _default_description() -> String:
	return "Does random effects."


func _default_animation() -> String:
	return 'none'
