class_name AttackEffectHandler
extends Node


## Should return true if the handler is able to handle the given effect.
## Note that the attack system does target checking so even if this
## returns true it doesn't guarantee that execute will be called.
func is_handler(_attack_effect: AttackEffect) -> bool:
	return false


## Executes an attack effect.
func execute(_state: AttackState, _target_index: int, _attack_effect: AttackEffect, _target: Unit) -> void:
	pass


