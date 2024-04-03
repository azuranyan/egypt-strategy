extends Resource
class_name AttackEffect


## The target of this effect.
@export_enum('Enemy', 'Ally', 'Self') var target: int


## Called by the attack when attack starts.
func attack_started(_battle: Battle, _user: Unit, _attack: Attack):
	pass
	

## Called by the attack when attack ends.
func attack_finished(_battle: Battle, _user: Unit, _attack: Attack):
	pass


## Applies the attack effect. Should call attack.effect_completed(self) when done.
func apply(_battle: Battle, _user: Unit, _attack: Attack, _target_cell: Vector2i, _target_unit: Unit) -> void:
	_attack.effect_complete(self)
	
