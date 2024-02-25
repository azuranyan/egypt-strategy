extends AttackEffectHandler


func is_handler(attack_effect: AttackEffect) -> bool:
	return attack_effect is AddAnimatedSpriteEffect


@warning_ignore("unused_parameter")
func execute(state: AttackState, target_index: int, attack_effect: AttackEffect, target: Unit) -> void:
	if not OS.is_debug_build():
		return
	var anim := AnimatedSprite2D.new()
	anim.sprite_frames = attack_effect.sprite_frames
	anim.animation = attack_effect.animation
	target.attach(anim, attack_effect.target)
	anim.play()
	await anim.animation_finished
	anim.queue_free()
