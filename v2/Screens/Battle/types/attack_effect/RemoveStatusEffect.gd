extends AttackEffect
class_name RemoveStatusEffectEffect


@export_enum('PSN', 'STN', 'VUL', 'BLK') var effect: String


func _apply(_battle: Battle, _user: Unit, _attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	for eff in target_unit.status_effects:
		target_unit.remove_status_effect(eff)
		break
	
	
func _default_description() -> String:
	return 'Removes %s.' % effect


func _default_animation() -> String:
	return 'none'
