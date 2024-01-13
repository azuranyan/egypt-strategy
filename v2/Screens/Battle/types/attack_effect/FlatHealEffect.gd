extends AttackEffect
class_name FlatHealEffect
	

@export var amount: int


func apply(battle: Battle, user: Unit, attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	battle.heal_unit(target_unit, user, amount)
	attack.effect_completed(self)
	
	
func get_effect_hint() -> String:
	return 'heal'
	
	
func _default_description() -> String:
	return "Heals %s hp." % amount


func _default_animation() -> String:
	return 'basic_heal'
