extends AttackEffect
class_name FlatDamageEffect
	

@export var amount: int


func apply(battle: Battle, user: Unit, _attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	battle.damage_unit(target_unit, user, amount)
	
	
func get_effect_hint() -> String:
	return 'attack'
	
	
func _default_description() -> String:
	return "Deals %s damage." % amount


func _default_animation() -> String:
	return 'basic_damage'
