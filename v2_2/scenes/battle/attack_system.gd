extends Node


signal attack_started
signal attack_finished


@export_range(0.01, 9) var minimum_attack_time: float = 1

@export var null_effect_handler: AttackEffectHandler


var handlers := {}


## Executes an attack.
func execute_attack(state: AttackState) -> void:
	attack_started.emit()

	var timer := get_tree().create_timer(minimum_attack_time)
	state.user.play_animation(state.attack.user_animation)

	for i in state.target_count:
		apply_target_effects(state, i)

	while state.active_effects_count > 0:
		await state.effect_processing_finished

	if timer.time_left > 0:
		await timer.timeout

	state.user.play_animation('idle')
	for i in state.target_count:
		for ts: Array[Unit] in state.target_units:
			for t in ts:
				t.play_animation('idle')

	attack_finished.emit()


## Applies attack effects to the target units.
func apply_target_effects(state: AttackState, target_index: int) -> void:
	var process_effects := func(effects: Array[AttackEffect], filter: Callable):
		for effect in effects:
			for t in state.target_units[target_index]:
				if filter.call(t):
					dispatch_effect(state, target_index, effect, t)

	process_effects.call(state.attack.self_effects, state.user.is_self)
	process_effects.call(state.attack.ally_effects, state.user.is_ally)
	process_effects.call(state.attack.enemy_effects, state.user.is_enemy)


@warning_ignore("redundant_await")
## Dispatches a single instance of attack to a unit.
func dispatch_effect(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	state.active_effects_count += 1
	state.effect_processing_started.emit(attack_effect, target)
	await get_handler(attack_effect).execute(state, target_index, attack_effect, target)
	state.active_effects_count -= 1
	state.effect_processing_finished.emit(attack_effect)


## Returns the appropriate handler for a specific attack effect.
func get_handler(attack_effect: AttackEffect) -> AttackEffectHandler:
	var handler := get_cached_handler(attack_effect)
	if handler:
		return handler
	for child in get_children():
		if (child is AttackEffectHandler) and child.is_handler(attack_effect):
			cache_handler(attack_effect, child)
			return child
	return null_effect_handler
	

## Returns the cached handler if it exists.
func get_cached_handler(attack_effect: AttackEffect) -> AttackEffectHandler:
	if attack_effect.resource_path in handlers:
		return handlers[attack_effect.resource_path]
	return null
	
	
## Caches a handler.
func cache_handler(attack_effect: AttackEffect, handler: AttackEffectHandler):
	handlers[attack_effect.resource_path] = handler
