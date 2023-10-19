extends Resource
class_name Attack


enum Target {
	ENEMY = 1 << 0,
	ALLY = 1 << 1,
	SELF = 1 << 2,
}


## Display name of the attack.
@export var name: String

## Flavor text description.
@export var description: String

@export_subgroup('Animation')

## Unit animation played for the user.
@export var user_animation: String

## Unit animation played for the target.
@export var target_animation: String

@export_subgroup('Targeting')

## Shape of the targeting cursor.
@export var target_shape: Array[Vector2i] = [Vector2i(0, 0)]

## Whether rotation is allowed.
@export var allow_rotation: bool

## Range of the attack.
@export var range: int = -1

## Minimum range of the attack.
@export var min_range: int

## Allows the attack to be queued more than once.
@export var multicast: int
	
## Melee targeting mode.
@export var melee: bool

@export_subgroup('Effect')

## List of attack effects.
@export var effects: Array[AttackEffect] = []


## Returns the effect description.
func get_effect_description() -> String:
	var arr := PackedStringArray()
	for eff in effects:
		arr.append(eff.get_description())
	return '\n'.join(arr)
	

## Returns the target flags.
func get_target_flags() -> int:
	var flags := 0
	for eff in effects:
		flags |= 1 << eff.target
	return flags
