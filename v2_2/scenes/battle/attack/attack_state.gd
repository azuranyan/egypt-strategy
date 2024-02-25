class_name AttackState


## Emitted when an effect is started.
signal effect_processing_started(effect: AttackEffect, target: Unit)

## Emitted when an effect is finished.
signal effect_processing_finished(effect: AttackEffect)


## Attack being used.
var attack: Attack

## The unit that casted the attack.
var user: Unit

## The number of targets.
var target_count: int = 1

## The target cell
var target_cells: Array[Vector2] = [Vector2.ZERO]

## The target shape rotation.
var target_rotations: Array[float] = [0]

## The list of units that were caught in the attack AOE.
var target_units: Array = [[] as Array[Unit]]

## A count of all active effects.
var active_effects_count := 0


## Creates an attack state.
@warning_ignore("shadowed_variable")
static func create_attack_state(user: Unit, attack: Attack, target_cells: Array[Vector2], target_rotations: Array[float]) -> AttackState:
	var st := AttackState.new()
	st.attack = attack
	st.user = user
	st.target_count = target_cells.size()
	st.target_cells = target_cells
	st.target_rotations = target_rotations
	st.target_units.resize(target_cells.size())
	
	for i in target_cells.size():
		st.target_units[i] = user.attack_target_units(attack, target_cells[i], target_rotations[i])
	
	return st
