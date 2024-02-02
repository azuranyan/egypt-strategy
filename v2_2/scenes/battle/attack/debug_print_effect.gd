extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is DebugPrintEffect


func execute(state: AttackState, attack_effect: AttackEffect, target: Unit) -> void:
	if not Game.debug:
		return
	print(attack_effect.format.format({
		attack = state.attack,
		user = state.user,
		target = target,
		target_cell = state.target_cell,
		target_rotation = state.target_rotation,
		target_units = state.target_units,
		data = state.data,
	}))
