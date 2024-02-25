extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is HealEffect


@warning_ignore("unused_parameter")
func execute(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	var amount: int = attack_effect.amount
	if attack_effect.stat != 'none':
		amount += state.user.get_stat(attack_effect.stat) * attack_effect.stat_multiplier
		
	target.restore_health(amount, state.user)
