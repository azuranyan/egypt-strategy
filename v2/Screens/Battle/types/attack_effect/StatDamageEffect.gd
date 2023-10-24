extends AttackEffect
class_name StatDamageEffect
	

@export var flat_damage: int

@export_enum('maxhp', 'hp', 'mov', 'dmg', 'rng', 'bond') var stat: String = "dmg"

@export var multiplier: float = 1


func apply(battle: Battle, user: Unit, _attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	battle.damage_unit(target_unit, user, roundi(user.get(stat)*multiplier + flat_damage))
	
	
func get_effect_hint() -> String:
	return 'attack'
	
	
func _default_description() -> String:
	if flat_damage > 0:
		return "Deals %sx of %s plus %s damage." % [multiplier, stat_to_str(stat), flat_damage]
	elif flat_damage < 0:
		return "Deals %sx of %s minus %s damage." % [multiplier, stat_to_str(stat), flat_damage]
	else:
		return "Deals %sx of %s damage." % [multiplier, stat_to_str(stat)]


func _default_animation() -> String:
	return 'basic_damage'
