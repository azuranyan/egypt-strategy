class_name Unit extends Node
## The interface for unit.

# Phase flags
const PHASE_NONE := 0 ## Default movement (phase friendly units).
const PHASE_ENEMIES := 1 << 0 ## Ignores enemies.
const PHASE_DOODADS := 1 << 1 ## Ignores doodads.
const PHASE_TERRAIN := 1 << 2 ## Ignores terrain.
const PHASE_NO_CLIP := 1 << 3 ## Ignores all pathing and placement restrictions.

# Stats.
const MAX_HP := &'maxhp' ## Unit's max hp.
const HP := &'hp' ## Unit's current hp.
const RANGE := &'rng' ## Unit's range.
const MOVE := &'mov' ## Unit's move range.
const DAMAGE := &'dmg' ## Unit's damage.


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


## Returns the character id.
func chara_id() -> StringName:
	assert(false, 'not implemented')
	return ''
	

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
	
	
## Fields the unit into battle.
func field_unit() -> void:
	assert(false, 'not implemented')
	
	
## Unfields unit from battle.
func unfield_unit() -> void:
	assert(false, 'not implemented')
	
	
## Returns true if this unit is on the field.
func is_fielded() -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Returns the empire this unit belongs to.
func get_empire() -> Empire:
	assert(false, 'not implemented')
	return null
	
	
## Sets the empire this unit belongs to.
func set_empire(_empire: Empire) -> void:
	assert(false, 'not implemented')
	
	
## Returns true if this unit is a hero unit.
func is_hero() -> bool:
	assert(false, 'not implemented')
	return false


## Returns true if another unit is an enemy.
func is_enemy(_other: Unit) -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Returns true if another unit is an ally.
func is_ally(_other: Unit) -> bool:
	assert(false, 'not implemented')
	return false
	

## Returns true if another unit is self.
func is_self(_other: Unit) -> bool:
	assert(false, 'not implemented')
	return false

	
## Returns true if this unit is player owned.
func is_player_owned() -> bool:
	assert(false, 'not implemented')
	return false
	
	
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
func get_bond() -> int:
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
	
	
## Returns the attack range of a given attack.
func attack_range(_attack: Attack) -> int:
	assert(false, 'not implemented')
	return 0


## Returns the cells in range.
func attack_range_cells(_attack: Attack) -> PackedVector2Array:
	assert(false, 'not implemented')
	return []


## Returns an array of cells in the target aoe.
func attack_target_cells(_attack: Attack, _target: Vector2, _target_rotation: float) -> PackedVector2Array:
	assert(false, 'not implemented')
	return []
	

## Returns an array of units in the target aoe.
func attack_target_units(_attack: Attack, _target_cell: Vector2, _target_rotation: float) -> Array[Unit]:
	assert(false, 'not implemented')
	return []

	
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


## Returns the global position of this unit.
func get_global_position() -> Vector2:
	assert(false, 'not implemented')
	return Vector2.ZERO


## Sets the global position of this unit.
func set_global_position(_pos: Vector2) -> void:
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
## Plays an animation.
func play_animation(_anim_name: String) -> void:
	assert(false, 'not implemented')

	
## Returns true if unit has moved.
func has_moved() -> bool:
	assert(false, 'not implemented')
	return false


## Returns true if unit has attacked.
func has_attacked() -> bool:
	assert(false, 'not implemented')
	return false


## Returns true if unit's turn is done.
func is_turn_done() -> bool:
	assert(false, 'not implemented')
	return false


## Sets `has_moved` flag of this unit.
func set_has_moved(_has_moved: bool) -> void:
	assert(false, 'not implemented')
	
	
## Sets `has_attacked` flag of this unit.
func set_has_attacked(_has_attacked: bool) -> void:
	assert(false, 'not implemented')


## Sets `has_attacked` flag of this unit.
func set_turn_done(_turn_done: bool) -> void:
	assert(false, 'not implemented')


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
func walk_towards(_target: Vector2) -> void:
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
	

## Returns an array of cells this unit can be placed on.
func get_placeable_cells() -> PackedVector2Array:
	assert(false, 'not implemented')
	return []
	
	
## Makes unit take damage.
func take_damage(_amount: int, _source: Variant) -> void:
	assert(false, 'not implemented')
	
	
## Makes unit heal from damage.
func restore_health(_amount: int, _source: Variant) -> void:
	assert(false, 'not implemented')
	
	
## Kills a unit.
func kill() -> void:
	assert(false, 'not implemented')


## Revives unit if dead.
func revive() -> void:
	assert(false, 'not implemented')
	

## Uses the attack on the targeted cells.
func use_attack(_attack: Attack, _target_cells: Array[Vector2], _target_rotations: Array[float]) -> void:
	assert(false, 'not implemented')


## Executes the attack.
func execute_attack(_attack_state: AttackState):
	assert(false, 'not implemented')
#endregion Unit Actions


## Returns this unit's map object, or [code]null[/code] if unfielded.
func get_map_object() -> MapObject:
	assert(false, 'not implemented')
	return null
	

## Attaches a [Node] to this object.
func attach(_node: Node, _target: StringName) -> void:
	assert(false, 'not implemented')


## Detaches a [Node] from this object.
func detach(_node: Node) -> void:
	assert(false, 'not implemented')
