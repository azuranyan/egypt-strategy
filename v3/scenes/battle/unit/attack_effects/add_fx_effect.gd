class_name AddFXEffect
extends AttackEffect


@export var sprite_frames: SpriteFrames = preload("res://scenes/battle/unit/attack_effects/data/default_effects.tres")

@export var animation: String = 'damage'


## Applies the attack effect to a single target.
func execute(_state: AttackState, target: Unit) -> void:
	var gfx := AnimatedSprite2D.new()
	gfx.sprite_frames = sprite_frames
	gfx.animation = animation
	target.add_child(gfx)
