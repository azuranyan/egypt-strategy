class_name AttackSystem
extends Node


signal attack_started
signal attack_finished


@export_range(0.1, 2) var minimum_attack_time: float = 1

var handlers := {}


func execute(context: BattleContext, state: AttackState):
	attack_started.emit()
	var timer := get_tree().create_timer(minimum_attack_time)
	# hide
	
	# stop
	
	if timer.time_left > 0:
		await timer.timeout
	attack_finished.emit()

	
@warning_ignore("redundant_await")
func dispatch_effect(attack_effect: AttackEffect, state: AttackState, target: Unit):
	await get_handler(attack_effect).execute(state, attack_effect, target)


func get_handler(attack_effect: AttackEffect) -> AttackEffectHandler:
	var handler := get_cached_handler(attack_effect)
	if handler:
		return handler
	for child in get_children():
		if (child is AttackEffectHandler) and child.is_handler(attack_effect):
			cache_handler(attack_effect, child)
			return child
	return null
	

func get_cached_handler(attack_effect: AttackEffect) -> AttackEffectHandler:
	if attack_effect.resource_path in handlers:
		return handlers[attack_effect.resource_path]
	return null
	
	
func cache_handler(attack_effect: AttackEffect, handler: AttackEffectHandler):
	handlers[attack_effect.resource_path] = handler
