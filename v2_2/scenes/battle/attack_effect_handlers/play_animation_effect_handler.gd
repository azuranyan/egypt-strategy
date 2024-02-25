extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is PlayAnimationEffect


@warning_ignore("unused_parameter")
func execute(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	# this is some hack we're gonna do until we clean up the api for state and animations
	# take internal model state so we can restore it later
	var model: UnitModel = target.get_map_object().unit_model
	var old_state: Unit.State = model.state

	# play animation
	target.play_animation(attack_effect.animation)
	await model.animation_finished

	# restore internal model state
	# this is necessary because animations will just stop on the last frame if not reset
	model.state = old_state