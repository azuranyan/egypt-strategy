class_name AttackEffect
extends Resource


## Called by the attack when attack starts.
func attack_started(state: AttackState):
	pass
	

## Called by the attack when attack ends.
func attack_finished(state: AttackState):
	pass


## Applies the attack effect to a single target.
func execute(state: AttackState, target: Unit) -> void:
	pass
