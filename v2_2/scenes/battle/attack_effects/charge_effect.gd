class_name ChargeEffect
extends AttackEffect
## Represents an effect that makes the unit charge towards the target in a straight line.


## The speed at which the unit moves, in tiles per second. Set to [code]0[/code] for instant movement.
@export_range(0, 999) var speed: float = 0