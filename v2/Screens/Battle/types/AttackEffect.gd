extends Resource
class_name AttackEffect


## The target of this effect.
@export_enum('Enemy', 'Ally', 'Self') var target: int


## Called by the attack when attack starts.
func attack_started(battle: Battle, user: Unit, attack: Attack):
	pass
	

## Called by the attack when attack ends.
func attack_finished(battle: Battle, user: Unit, attack: Attack):
	pass


## Applies the attack effect. Should call attack.effect_completed(self) when done.
func apply(battle: Battle, user: Unit, attack: Attack, target_cell: Vector2i, target_unit: Unit) -> void:
	attack.effect_completed(self)
	
