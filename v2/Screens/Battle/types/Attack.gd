extends Resource
class_name Attack


signal _effect_completed


enum Target {
	ENEMY = 1 << 0,
	ALLY = 1 << 1,
	SELF = 1 << 2,
}

enum {
	ATTACK_OK = 0,
	ATTACK_NOT_UNLOCKED,
	ATTACK_TARGET_INSIDE_MIN_RANGE,
	ATTACK_TARGET_OUT_OF_RANGE,
	ATTACK_NO_TARGETS,
	ATTACK_INVALID_TARGET,
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


## Returns the target flags.
func get_effect_hints() -> PackedStringArray:
	var re := PackedStringArray()
	for eff in effects:
		if eff.get_effect_hint() not in re:
			re.append(eff.get_effect_hint())
	return re


## Returns an array of cells in the target aoe.
func get_target_cells(target: Vector2, target_rotation: float) -> PackedVector2Array:
	var re := PackedVector2Array()
	for offs in target_shape:
		var m := Transform2D()
		m = m.translated(offs)
		m = m.rotated(target_rotation)
		m = m.translated(target)
		var p := m * Vector2.ZERO 
		# this is from map.to_cell *might have to put somewhere more accessible later
		re.append(Vector2(int(snapped(p.x, 0.01)), int(snapped(p.y, 0.01))))
	return re


## Executes the attack.
func execute(user: Unit, target: Vector2, target_units: Array[Unit]):
	var effect_counter := 0
	for effect in effects:
		effect.attack_started(Game.battle, user, self)
		for target_unit in target_units:
			if _is_effect_target(user, target_unit, effect):
				var wrapper := func():
					effect_counter += 1
					effect.apply(Game.battle, user, self, target, target_unit)
				wrapper.call_deferred()
	
	while effect_counter > 0:
		await _effect_completed
		effect_counter -= 1
		
	for effect in effects:
		effect.attack_finished(Game.battle, user, self)
	
	
func _is_effect_target(unit: Unit, target: Unit, effect: AttackEffect) -> bool:
	match effect.target:
		0: # Enemy
			return unit.is_enemy(target)
		1: # Ally
			return unit.is_ally(target)
		2: # Self
			return unit == target
	return false
	
	
## To be called by the effect once their effects are finished.
func effect_complete(_effect: AttackEffect):
	_effect_completed.emit()
	
