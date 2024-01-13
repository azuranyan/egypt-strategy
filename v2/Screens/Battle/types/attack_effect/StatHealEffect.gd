extends AttackEffect
class_name StatHealEffect
	

@export var flat_heal: int

@export_enum('maxhp', 'hp', 'move', 'damage', 'range', 'bond') var stat: String = "bond"

@export var multiplier: float = 1


func apply(battle: Battle, user: Unit, attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	battle.heal_unit(target_unit, user, roundi(user.get(stat)*multiplier + flat_heal))
	attack.effect_completed(self)
	
	
func get_effect_hint() -> String:
	return 'heal'
	
	
func _default_description() -> String:
	if flat_heal > 0:
		return "Heals %sx of %s plus %s hp." % [multiplier, stat_to_str(stat), flat_heal]
	elif flat_heal < 0:
		return "Heals %sx of %s minus %s hp." % [multiplier, stat_to_str(stat), flat_heal]
	else:
		return "Heals %sx of %s hp." % [multiplier, stat_to_str(stat)]


func _default_animation() -> String:
	return 'basic_heal'
