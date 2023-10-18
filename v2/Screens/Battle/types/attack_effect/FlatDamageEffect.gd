extends AttackEffect
class_name FlatDamageEffect
	

@export var min_damage: int
@export var max_damage: int


func _apply(battle: Battle, user: Unit, _attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	battle.damage_unit(target_unit, user, randi_range(min_damage, max_damage))
	
	
func _default_description() -> String:
	if min_damage == max_damage:
		return "Deals %s damage." % min_damage
	else:
		return "Deals %s-%s damage." % [min_damage, max_damage]


func _default_animation() -> String:
	return 'basic_damage'
