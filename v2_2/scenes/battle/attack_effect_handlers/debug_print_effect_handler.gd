extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is DebugPrintEffect


@warning_ignore("unused_parameter")
func execute(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	if not OS.is_debug_build():
		return
	print(attack_effect.format.format({
		effect = attack_effect.resource_path.get_file().trim_suffix('.tres'),
		attack = state.attack.name,
		user = state.user.display_name(),
		target = target.display_name(),
		user_id = state.user.id(),
		user_chara_id = state.user._chara_id if '_chara_id' in state.user else '<null>',
		target_id = target.id(),
		target_chara_id = target._chara_id if '_chara_id' in target else '<null>',
	}))
