class_name AttackEffect
extends Resource


## Called by the attack when attack starts.
func attack_started(_state: AttackState):
	pass
	

## Called by the attack when attack ends.
func attack_finished(_state: AttackState):
	pass


## Applies the attack effect to a single target.
func execute(_state: AttackState, _target: UnitState) -> void:
	pass
