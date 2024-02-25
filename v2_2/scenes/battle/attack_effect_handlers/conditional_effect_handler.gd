extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is ConditionalEffect


@warning_ignore("unused_parameter")
func execute(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	var node := get_node_or_null(attack_effect.node)
	if not node:
		return
	if not node.has_method(attack_effect.method):
		return
	if not node.call(attack_effect.method):
		return
	await AttackSystem.instance().dispatch_effect(state, target_index, attack_effect.effect, target)
