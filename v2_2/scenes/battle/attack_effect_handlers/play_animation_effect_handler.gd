extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is PlayAnimationEffect


@warning_ignore("unused_parameter")
func execute(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	# this is some hack we're gonna do until we clean up the api for state and animations:
	# take internal model state so we can restore it later
	var model: UnitModel = target.get_map_object().unit_model
	model.play_animation_override(attack_effect.animation)

	match attack_effect.hold_condition:
		PlayAnimationEffect.HoldCondition.DURATION:
			# only create the timer if duration is valid, otherwise fallback to waiting for animation finish
			if attack_effect.duration > 0:
				await get_tree().create_timer(attack_effect.duration).timeout
			else:
				await model.animation_finished
			model.stop_animation_override()
			
		PlayAnimationEffect.HoldCondition.ATTACK_FINISH:
			# this function immediately exits and restores the animation state after the attack ends
			var wait_until_finish := func():
				# AttackState.effect_processing_finished - after an effect finishes
				# AttackSystem.attack_finished - after attack system is done processing an attack
				# UnitEvents.attack_finished - after unit state is restored
				# Battle.attack_sequence_ended - after battle does the hud, camera and stuff
				await AttackSystem.instance().attack_finished
				model.stop_animation_override()
			wait_until_finish.call_deferred()

		PlayAnimationEffect.HoldCondition.ANIMATION_FINISH, _:
			# an easy case that waits until the animation finishes
			await model.animation_finished
			model.stop_animation_override()