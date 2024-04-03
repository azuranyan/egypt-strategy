@tool
class_name PlayAnimationEffect
extends AttackEffect
## Represents an effect that plays an animation.


enum HoldCondition {
	## Holds the animation until it finishes.
	ANIMATION_FINISH,

	## Holds for the specified amount of time.
	DURATION,

	## Holds until the attack sequence is finished.
	ATTACK_FINISH,
}


## The animation to play.
@export var animation: StringName

## The hold condition.
@export var hold_condition := HoldCondition.ATTACK_FINISH:
	set(value):
		hold_condition = value
		if hold_condition == HoldCondition.DURATION:
			duration = 1
		else:
			duration = 0
		notify_property_list_changed()


var duration: float


func _get_property_list() -> Array[Dictionary]:
	return [
		{
			name = 'duration',
			type = TYPE_FLOAT,
			usage = PROPERTY_USAGE_DEFAULT if hold_condition == HoldCondition.DURATION else PROPERTY_USAGE_NONE,
		}
	]