extends AttackEffect
class_name DamageEffect
	

@export var flat_damage: int

@export_enum('maxhp', 'hp', 'move', 'damage', 'range', 'bond') var stat: String = "damage"

@export var multiplier: float = 1


func apply(battle: Battle, user: Unit, attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	battle.damage_unit(target_unit, user, roundi(user.get(stat)*multiplier + flat_damage))
	attack.effect_complete(self)
	
