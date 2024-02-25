extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is SequenceEffect


@warning_ignore("unused_parameter")
func execute(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	for seq_effect in attack_effect.effects:
		await AttackSystem.instance().dispatch_effect(state, target_index, seq_effect, target)
