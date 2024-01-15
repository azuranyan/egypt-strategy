class_name RemoveStatusEffectEffect
extends AttackEffect


@export_enum('PSN', 'STN', 'VUL', 'BLK') var effect: String


func apply(_battle: Battle, _user: Unit, attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	for eff in target_unit.status_effects:
		# TODO play cleanse sfx
		target_unit.remove_status_effect(eff)
		break
	attack.effect_complete(self)
	
