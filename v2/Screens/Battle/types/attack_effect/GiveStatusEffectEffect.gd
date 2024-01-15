extends AttackEffect
class_name GiveStatusEffectEffect


@export_enum('PSN', 'STN', 'VUL', 'BLK') var effect: String

@export var duration: int


func apply(_battle: Battle, _user: Unit, attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	target_unit.add_status_effect(effect, duration)
	attack.effect_complete(self)
	
