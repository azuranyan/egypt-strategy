extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is WaitEffect


@warning_ignore("unused_parameter")
func execute(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	match attack_effect.type:
		'duration':
			await get_tree().create_timer(attack_effect.duration).timeout

		'signal':
			var node := get_node_or_null(attack_effect.signal_object_path)
			if not node:
				push_error('no node at path: %s' % attack_effect.signal_object_path)
				return

			if attack_effect.signal_name not in node:
				push_error('signal not found: %s' % attack_effect.signal_name)
				return
			
			await node.get(attack_effect.signal_name)