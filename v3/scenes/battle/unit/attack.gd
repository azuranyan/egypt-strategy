class_name Attack
extends Resource


signal _effect_completed


enum {
	TARGET_SELF = 1 << 0,
	TARGET_ALLY = 1 << 1,
	TARGET_ENEMY = 1 << 2,
}


## Display name of the attack.
@export var name: String

## Flavor text description.
@export_multiline var description: String

@export_subgroup('Effect')

## Unit animation played for the user.
@export var user_animation: String = 'attack'

## Allows the attack to be queued more than once.
@export var multicast: int

## List of attack effects.
@export var self_effects: Array[AttackEffect] = []

## List of attack effects.
@export var enemy_effects: Array[AttackEffect] = []

## List of attack effects.
@export var ally_effects: Array[AttackEffect] = []

@export_subgroup('Targeting')

## Shape of the targeting cursor.
@export var target_shape: Array[Vector2i] = [Vector2i(0, 0)]

## Melee targeting mode.
@export var melee: bool

@export_flags("Self:1", "Ally:2", "Enemy:4") var targeting: int = TARGET_ENEMY

## Whether rotation is allowed.
@export var allow_rotation: bool

## Range of the attack.
@export var max_range: int = -1

## Minimum range of the attack.
@export var min_range: int

	
## Returns true if attack is multicast.
func is_multicast() -> bool:
	return multicast > 0
	

## Returns an array of cells in the target aoe.
func get_target_cells(target: Vector2, target_rotation: float) -> PackedVector2Array:
	var re := PackedVector2Array()
	for offs in target_shape:
		var m := Transform2D()
		m = m.translated(offs)
		m = m.rotated(target_rotation)
		m = m.translated(target)
		var p := m * Vector2.ZERO 
		re.append(Vector2(roundi(p.x), roundi(p.y)))
	return re


## Returns an array of effected untis
func is_attack_target(user: Unit, other: Unit) -> bool:
	if (targeting | TARGET_SELF != 0) and user == other: return true
	if (targeting | TARGET_ALLY != 0) and user.is_ally(other): return true
	if (targeting | TARGET_ENEMY != 0) and user.is_enemy(other): return true
	return false
	
	
## Executes the attack.
func execute(state: AttackState):
	var timer := Game.get_tree().create_timer(1)
	
	_notify_effect_started(state)
	await _execute_effects(state)
	_notify_effect_ended(state)
	
	if timer.time_left > 0:
		await timer.timeout
	
	
	
	
func _notify_effect_started(state: AttackState):
	for effect in self_effects:
		effect.attack_started(state)
	for effect in ally_effects:
		effect.attack_started(state)
	for effect in enemy_effects:
		effect.attack_started(state)
		
		
func _notify_effect_ended(state: AttackState):
	for effect in self_effects:
		effect.attack_finished(state)
	for effect in ally_effects:
		effect.attack_finished(state)
	for effect in enemy_effects:
		effect.attack_finished(state)
	
	
func _execute_effects(state: AttackState):
	var captures := {counter = 0}
	for effect in self_effects:
		for target in state.targets:
			if (targeting | TARGET_SELF != 0) and state.user == target:
				_execute_later(state, effect, target, captures)
	
	for effect in ally_effects:
		for target in state.targets:
			if (targeting | TARGET_ALLY != 0) and state.user.is_ally(target):
				_execute_later(state, effect, target, captures)
	
	for effect in enemy_effects:
		for target in state.targets:
			if (targeting | TARGET_ENEMY != 0) and state.user.is_enemy(target):
				_execute_later(state, effect, target, captures)
	
	while captures.counter > 0:
		await _effect_completed
		captures.counter -= 1
	

func _execute_later(state: AttackState, effect: AttackEffect, target: Unit, captures: Dictionary):
	var wrapped := func():
		captures.counter += 1
		await effect.execute(state, target)
		_effect_completed.emit()
	wrapped.call_deferred()
