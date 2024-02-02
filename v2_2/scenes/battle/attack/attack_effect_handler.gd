class_name AttackEffectHandler
extends Node


func is_handler(_attack_effect: AttackEffect) -> bool:
	return false


func execute(_state: AttackState, _attack_effect: AttackEffect, _target: Unit) -> void:
	pass
