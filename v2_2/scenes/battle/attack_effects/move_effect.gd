class_name MoveEffect
extends AttackEffect
## Represents an effect that teleports the unit to the target position.


enum Origin {
	## Uses the attack target cell as the origin.
	TARGET_CELL,

	## Uses the attack user cell as the origin.
	USER,

	## Uses the unit's current position as the origin.
	TARGET_UNIT,
}


enum Direction {
	## The offset is used as-is, e.g., [code](0, 1)[/code] will be [constant Vector2.UP].
	ABSOLUTE,

	## The offset will be relative to the attack target rotation.
	ATTACK_ROTATION,

	## The forward direction will be the user's current heading.
	USER_FORWARD,

	## The forward direction will be the target unit's current heading.
	TARGET_UNIT_FORWARD,

	## The forward direction will be the angle between the user and the target unit.
	USER_TO_TARGET,

	## The forward direction will be the angle between the target unit and the user.
	TARGET_TO_USER,
}


## Specifies the source of the target location for the teleportation.
@export var origin: Origin = Origin.TARGET_CELL

## The offset from the specified teleport origin.
@export var offset := Vector2.ZERO

## Sets the alignment of the offset.
@export var direction := Direction.ABSOLUTE

## The speed at which the unit moves, in tiles per second. Set to [code]0[/code] for instant movement.
@export_range(0, 999) var speed: float = 0