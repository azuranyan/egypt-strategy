extends AttackEffect
class_name FlatHealEffect
	

@export var min_heal: int
@export var max_heal: int


func _apply(battle: Battle, user: Unit, _attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	battle.damage_unit(target_unit, user, -randi_range(min_heal, max_heal))
	
	
func _default_description() -> String:
	if min_heal == max_heal:
		return "Heals %s hp." % min_heal
	else:
		return "Heals %s-%s hp." % [min_heal, max_heal]


func _default_animation() -> String:
	return 'basic_heal'
