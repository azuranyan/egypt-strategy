class_name PlayAnimationEffect
extends AttackEffect
	
	
@export_enum("idle", "attack", "special", "walk", "hurt", "victory") var animation := "hurt"


func apply(_battle: Battle, user: Unit, attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	var animation_target := user if target == 2 else target_unit
	
	animation_target.play_animation(animation, false)
	var on_animation_finish = func():
			#animation_target.stop_animation()
			attack.effect_complete(self)
	# TODO model should have better way to connect animation finished
	# TODO stop animation later after skill is done
	animation_target.model.sprite.animation_finished.connect(on_animation_finish, CONNECT_ONE_SHOT)
