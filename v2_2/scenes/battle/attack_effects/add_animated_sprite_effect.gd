class_name AddAnimatedSpriteEffect
extends AttackEffect
## Represents an effect that spawns an animated sprite on the target unit.


## The sprite frames to use.
@export var sprite_frames: SpriteFrames = preload("data/default_effects.tres")

## The animation string to play.
@export var animation: StringName = 'basic_damage'

## The name of the target node to spawn this effect on. Defaults to the unit origin if not found.
@export var target: StringName