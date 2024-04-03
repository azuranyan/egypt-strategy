class_name HealEffect
extends AttackEffect
	

@export var flat_heal: int

@export_enum('maxhp', 'hp', 'move', 'damage', 'range', 'bond') var stat: String = "bond"

@export var multiplier: float = 1


func apply(battle: Battle, user: Unit, attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	battle.heal_unit(target_unit, user, roundi(user.get(stat)*multiplier + flat_heal))
	attack.effect_completed(self)
	
