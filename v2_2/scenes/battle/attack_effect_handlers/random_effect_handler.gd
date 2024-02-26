extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is RandomEffect


@warning_ignore("unused_parameter")
func execute(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	if attack_effect.effects.size() == 0:
		return

	var chances := PackedVector2Array()
	var sum: float = 0
	for weight: float in attack_effect.weights:
		var low: float = sum
		var high: float = sum + weight
		chances.append(Vector2(low, high))
		sum = high
	
	var roll := randf_range(0, sum)
	var effect: AttackEffect = attack_effect.effects[0] # default to the first element in case of an fp error
	for i in chances.size():
		if roll >= chances[i].x and roll < chances[i].y:
			effect = attack_effect.effects[i]
	
	await AttackSystem.instance().dispatch_effect(state, target_index, effect, target)