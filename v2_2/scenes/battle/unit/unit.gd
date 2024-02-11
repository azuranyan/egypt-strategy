class_name Unit extends Node
## The interface for unit.


signal walking_started(start: Vector2, end: Vector2)
signal walking_finished(start: Vector2, end: Vector2)

signal attack_started(st: AttackState)
signal attack_finished(st: AttackState)

signal empire_changed(old: Empire, new: Empire)
signal behavior_changed(old: Behavior, new: Behavior)

signal state_changed(old: State, new: State)
signal position_changed(old_pos: Vector2, new_pos: Vector2)
signal stat_changed(stat: StringName, value: int)
signal damaged(value: int, source: Variant)
signal healed(value: int, source: Variant)
signal died
signal revived

signal status_effect_added(effect: StringName, duration: int)
signal status_effect_removed(effect: StringName)

signal interacted(cursor_pos: Vector2, button_index: int, pressed: bool)


# Turn flags
## Unit moved bitflag.
const HAS_MOVED := 1 << 0

## Unit attacked bitflag.
const HAS_ATTACKED := 1 << 1

## Unit attacked bitflag.
const IS_DONE := 1 << 2

# Phase flags
## Default walk (phase friendly units).
const PHASE_NONE = 0
	
## Ignores enemies.
const PHASE_ENEMIES = 1 << 0
	
## Ignores doodads.
const PHASE_DOODADS = 1 << 1
	
## Ignores terrain.
const PHASE_TERRAIN = 1 << 2
	
## Ignores all pathing and placement restrictions.
const PHASE_NO_CLIP = 1 << 3


## Dictates how his unit chooses its actions.
enum Behavior {
	## UnitState is controlled by player.
	PLAYER_CONTROLLED,
	
	## Always advances towards nearest target and attacks.
	NORMAL_MELEE,
	
	## Always attacks nearest target, flees adjacent attackers.
	NORMAL_RANGED,
	
	## Always advances and tries to attack target with lowest HP.
	EXPLOITATIVE_MELEE,
	
	## Always tries to attack targets that would not be able to retaliate.
	EXPLOITATIVE_RANGED,
	
	## Holds 1 spot and attacks any who approach.
	DEFENSIVE_MELEE,
	
	## Holds 1 spot and attacks any who approach, flees adjacent attackers.
	DEFENSIVE_RANGED,
	
	## Heals allies and self, runs away from attackers.
	SUPPORT_HEALER,
	
	## Aims to inflict as many enemies with negative status as possible, will choose different target if already afflicted.
	STATUS_APPLIER,
}


## The state of a unit.
enum State {INVALID, IDLE, WALKING, ATTACKING, HURT, DYING, DEAD}


#region Unit Attributes
## Returns the unit id.
func id() -> int:
	assert(false, 'not implemented')
	return 0


## The character representing this unit.
func chara() -> CharacterInfo:
	assert(false, 'not implemented')
	return null
	
	
## The blueprint unit type of this unit.
func unit_type() -> UnitType:
	assert(false, 'not implemented')
	return null
	
	
## The name displayed in the game.
func display_name() -> String:
	assert(false, 'not implemented')
	return ''
	

## The name displayed in the game.
func display_icon() -> Texture:
	assert(false, 'not implemented')
	return null
	
	
## The scale of the unit model.
func model_scale() -> Vector2:
	assert(false, 'not implemented')
	return Vector2.ZERO
	
	
## Returns the base stats.
func base_stats() -> Dictionary:
	assert(false, 'not implemented')
	return {}
#endregion Unit Attributes


#region Unit State
## Returns the state of this unit.
func state() -> State:
	assert(false, 'not implemented')
	return 0 as State
	
	
## Returns the empire this unit belongs to.
func get_empire() -> Empire:
	assert(false, 'not implemented')
	return null
	
	
## Sets the empire this unit belongs to.
func set_empire(_empire: Empire) -> void:
	assert(false, 'not implemented')
	
	
## Returns true if another unit is an enemy.
func is_enemy(_other: Unit) -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Returns true if another unit is an ally.
func is_ally(_other: Unit) -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Returns true if this unit is player owned.
func is_player_owned() -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Returns the turn flags.
func turn_flags() -> int:
	assert(false, 'not implemented')
	return 0
	
	
## Returns the unit phase flags.
func get_phase_flags() -> int:
	assert(false, 'not implemented')
	return 0
	
	
## Sets the unit phase flags.
func set_phase_flags(_flags: int) -> void:
	assert(false, 'not implemented')
	

## Returns the unit behavior.
func get_behavior() -> Behavior:
	assert(false, 'not implemented')
	return 0 as Behavior
	
	
## Changes the unit behavior.
func set_behavior(_behavior: Behavior) -> void:
	assert(false, 'not implemented')
	
	
## Returns true if unit is selectable.
func is_selectable() -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Makes the unit selectable or not.
func set_selectable(_selectable: bool) -> void:
	assert(false, 'not implemented')
	
	
## Returns true if the unit is currently selected.
func is_selected() -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Returns the unit stat.
func get_stat(_stat: StringName) -> int:
	assert(false, 'not implemented')
	return 0
	
	
## Sets the unit stat.
func set_stat(_stat: StringName, _value: int) -> void:
	assert(false, 'not implemented')
	
	
## Sets the bond level of this unit.
func set_bond(_value: int) -> void:
	assert(false, 'not implemented')
	

## Returns the bond level.
func get_bond() -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Returns this unit's basic attack.
func basic_attack() -> Attack:
	assert(false, 'not implemented')
	return null
	
	
## Returns this unit's special attack.
func special_attack() -> Attack:
	assert(false, 'not implemented')
	return null
	
	
## Set to true or false to override special unlock, or null for default rules.
func set_special_unlocked(_value: Variant) -> void:
	assert(false, 'not implemented')
	
	
## Returns true if unit special is unlocked.
func is_special_unlocked() -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Adds status effect to unit.
func add_status_effect(_effect: StringName, _duration: int) -> void:
	assert(false, 'not implemented')
	
	
## Removes status effect from unit.
func remove_status_effect(_effect: StringName) -> void:
	assert(false, 'not implemented')

	
## Returns true if unit has a specific status effect.
func has_status_effect(_effect: String) -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Ticks all status effects, triggering them and reducing duration by one.
func tick_status_effects() -> void:
	assert(false, 'not implemented')
	
	
## Removes all status effects.
func clear_status_effects() -> void:
	assert(false, 'not implemented')
	
	
## Returns the cell this unit is residing in.
func cell() -> Vector2:
	assert(false, 'not implemented')
	return Vector2.ZERO
	
	
## Returns the position of this unit.
func get_position() -> Vector2:
	assert(false, 'not implemented')
	return Vector2.ZERO
	
	
## Sets the position of this unit.
func set_position(_pos: Vector2) -> void:
	assert(false, 'not implemented')
	
	
## Returns true if this unit is on standby.
func is_standby() -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Makes this unit face towards target.
func face_towards(_target: Vector2) -> void:
	assert(false, 'not implemented')
	
	
## Returns the direction this unit is facing.
func get_heading() -> Map.Heading:
	assert(false, 'not implemented')
	return 0 as Map.Heading
	
	
## Sets the direction this unit is facing.
func set_heading(_heading: Map.Heading) -> void:
	assert(false, 'not implemented')
	

## Sets this units walk speed.
func walk_speed() -> float:
	assert(false, 'not implemented')
	return 0


## Returns true if alive.
func is_alive() -> bool:
	assert(false, 'not implemented')
	return false
	

## Returns true if unit is playing death animation.
func is_dying() -> bool:
	assert(false, 'not implemented')
	return false
	

## Returns true if dead.
func is_dead() -> bool:
	assert(false, 'not implemented')
	return false


## Returns true if the unit is a valid target.
func is_valid_target() -> bool:
	assert(false, 'not implemented')
	return false
	

## Returns true if unit can path over cell.
func is_pathable(_cell: Vector2) -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Returns true if unit can be placed over cell.
func is_placeable(_cell: Vector2) -> bool:
	assert(false, 'not implemented')
	return false
#endregion Unit State


#region Unit Actions
## Performs an action. This makes
func do_action(_type: StringName, _kwargs := {}) -> void:
	assert(false, 'not implemented')
	
	
## Sets the turn flag.
func set_turn_flag(_flag: int) -> void:
	assert(false, 'not implemented')
	
	
## Clears the turn flag.
func clear_turn_flag(_flag: int) -> void:
	assert(false, 'not implemented')
	
	
## Checks if the turn flag is set.
func is_turn_flag_set(_flag: int) -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Returns true if this unit can move.
func can_move() -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Returns true if this unit can attack.
func can_attack() -> bool:
	assert(false, 'not implemented')
	return false
	

## Returns true if this unit can act.
func can_act() -> bool:
	assert(false, 'not implemented')
	return false
	

## Returns true if this unit has taken any actions.
func has_taken_action() -> bool:
	assert(false, 'not implemented')
	return false


## Makes unit walk towards cell.
func walk_towards(_target: Vector2):
	assert(false, 'not implemented')
	

## Returns true if unit is walking.
func is_walking() -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Makes unit stop walking.
func stop_walking() -> void:
	assert(false, 'not implemented')
	
	
## Pathfinds to a cell.
func pathfind_to(_target: Vector2) -> PackedVector2Array:
	assert(false, 'not implemented')
	return []
	
	
## Returns an array of cells this unit can path through.
func get_pathable_cells(_use_mov_stat := false) -> PackedVector2Array:
	assert(false, 'not implemented')
	return []
	
	
## Makes unit take damage.
func take_damage(_value: int, _source: Variant) -> void:
	assert(false, 'not implemented')
	
	
## Makes unit heal from damage.
func restore_health(_value: int, _source: Variant) -> void:
	assert(false, 'not implemented')
	
	
## Kills a unit.
func kill() -> void:
	assert(false, 'not implemented')


## Revives unit if dead.
func revive() -> void:
	assert(false, 'not implemented')
	
	
## Uses attack on target cell.
func use_attack(_attack: Attack, _cell: Vector2, _rotation: Vector2) -> void:
	assert(false, 'not implemented')
	
	
## Multicasts the attack on target cell.
func use_attack_multicast(_attack: Attack, _cells: PackedVector2Array, _rotations: PackedFloat64Array) -> void:
	assert(false, 'not implemented')
#endregion Unit Actions

