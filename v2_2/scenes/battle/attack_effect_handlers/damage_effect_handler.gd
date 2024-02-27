extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is DamageEffect


@warning_ignore("unused_parameter")
func execute(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	var amount: int = attack_effect.amount + get_stat_value(state.user, attack_effect.stat) * attack_effect.stat_multiplier
	target.take_damage(amount, state.user)


func get_stat_value(unit: Unit, stat: String) -> int:
	match stat:
		'maxhp', 'hp':
			return unit.get_stat(stat)
		'damage':
			return unit.get_stat('dmg')
		'range':
			return unit.get_stat('rng')
		'move':
			return unit.get_stat('mov')
		'bond':
			return unit.get_bond()
		_:
			return 0
