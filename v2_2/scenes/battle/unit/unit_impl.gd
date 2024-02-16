class_name UnitImpl extends Unit


const UnitMapObjectScene := preload("res://scenes/battle/map_objects/unit_map_object.tscn")


## The unit id.
@export var _id: int

## The chara id of unit, solely for debugging.
@export var _chara_id: StringName

## Display name override.
@export var _display_name: String

## Display icon override.
@export var _display_icon: Texture
	
## The character representing this unit.
@export var _chara: CharacterInfo

## The blueprint unit type of this unit.
@export var _unit_type: UnitType

## The scale of the unit model.
@export var _model_scale: Vector2 = Vector2.ONE

@export_group("State")

## The owner of this unit.
@export var _empire: Empire

## Unit behavior.
@export var _behavior: Behavior

## The unit state.
@export var _state: State

@export_flags('Attacked:1', 'Moved:2', 'Done:4') var _turn_flags: int

@export var _selectable: bool = true

@export_subgroup("Stats")

## UnitState stats. Not meant to be changed directly.
@export var _stats := {
	maxhp = 1,
	hp = 1,
	mov = 1,
	dmg = 1,
	rng = 1,
}

## Bond level.
@export var _bond: int

## Overrides bond level and unlocks special.
@export var _special_unlock: int = -1

## List of buffs and debuffs.
@export var _status_effects: Dictionary

@export_subgroup("Movement")

## The direction this unit is facing.
@export var _heading: Map.Heading = Map.Heading.EAST

## This units position.
@export var _map_position: Vector2 = Map.OUT_OF_BOUNDS

## This unit's walk speed.
@export var _walk_speed: float = 200

## Objects this unit can phase through.
@export_flags('Enemies:1', 'Doodads:2', 'Terrain:4') var _phase_flags: int


var battle: Battle
var map_object: UnitMapObject

@onready var driver = $UnitDriver


func _init(__id: int = 0, __chara_id: StringName = &'', __chara: CharacterInfo = null, __unit_type: UnitType = null):
	_id = __id
	_chara_id = __chara_id
	_chara = __chara
	_unit_type = __unit_type
	
	
func _ready():
	battle = Game.battle
	
	
func reset(initial_state: State):
	set_state(initial_state)
	var _base := base_stats()
	for stat in _base:
		set_stat(stat, _base[stat])
	set_stat(&'hp', _base.maxhp)
	clear_status_effects()
	set_position(Map.OUT_OF_BOUNDS)
	set_heading(Map.Heading.EAST)
	if is_alive():
		_state = State.IDLE
		
		
func set_state(new_state: State):
	var old_state := _state
	_state = new_state
	state_changed.emit(old_state, new_state)

	
func sync_map_position(old: Vector2, new: Vector2):
	_map_position = new
	position_changed.emit(old, new)
	
	
func _on_model_interacted(cursor_pos: Vector2, button_index: int, pressed: bool):
	if _selectable:
		interacted.emit(cursor_pos, button_index, pressed)


#region Unit Attributes
## Returns the unit id.
func id() -> int:
	return _id


## The character representing this unit.
func chara() -> CharacterInfo:
	return _chara
	
	
## The blueprint unit type of this unit.
func unit_type() -> UnitType:
	return _unit_type
	
	
## The name displayed in the game.
func display_name() -> String:
	return _display_name
	

## The name displayed in the game.
func display_icon() -> Texture:
	return _display_icon
	
	
## The scale of the unit model.
func model_scale() -> Vector2:
	return Vector2.ONE
	
	
## Returns the base stats.
func base_stats() -> Dictionary:
	var re := _unit_type.stats.duplicate()
	if _bond >= 1:
		for stat in _stats:
			re[stat] += _unit_type.stat_growth_1[stat]
	if _bond >= 2:
		for stat in _stats:
			re[stat] += _unit_type.stat_growth_2[stat]
	return re
#endregion Unit Attributes


#region Unit State
## Returns the state of this unit.
func state() -> State:
	return _state
	
	
## Fields the unit into battle.
func field_unit() -> void:
	if is_fielded():
		push_warning('unit is already fielded, re-fielding')
		unfield_unit()
	map_object = UnitMapObjectScene.instantiate()
	map_object.map_position_changed.connect(sync_map_position)
	map_object.interacted.connect(_on_model_interacted)
	battle.add_map_object(map_object)
	map_object.initialize(self)
	driver.target = map_object
	reset(State.IDLE)
	fielded.emit()
	
	
## Unfields unit from battle.
func unfield_unit() -> void:
	if not is_fielded():
		return
	driver.target = null
	map_object.initialize(null)
	battle.remove_map_object(map_object)
	map_object.map_position_changed.disconnect(sync_map_position)
	map_object.interacted.disconnect(_on_model_interacted)
	map_object.queue_free()
	map_object = null
	reset(State.INVALID)
	unfielded.emit()
	
	
## Returns true if this unit is on the field.
func is_fielded() -> bool:
	return map_object != null
	
	
## Returns the empire this unit belongs to.
func get_empire() -> Empire:
	return _empire
	
	
## Sets the empire this unit belongs to.
func set_empire(empire: Empire) -> void:
	var old := _empire
	_empire = empire
	empire_changed.emit(old, empire)
	
	
## Returns true if another unit is an enemy.
func is_enemy(other: Unit) -> bool:
	return not is_ally(other)
	
	
## Returns true if another unit is an ally.
func is_ally(other: Unit) -> bool:
	return (other != self) and (other.get_empire() == self.get_empire())
	
	
## Returns true if this unit is player owned.
func is_player_owned() -> bool:
	return _empire.is_player_owned()
	
	
## Returns the turn flags.
func turn_flags() -> int:
	return _turn_flags
	
	
## Returns the unit phase flags.
func get_phase_flags() -> int:
	return _phase_flags
	
	
## Sets the unit phase flags.
func set_phase_flags(flags: int) -> void:
	_phase_flags = flags
	

## Returns the unit behavior.
func get_behavior() -> Behavior:
	assert(false, 'not implemented')
	return 0 as Behavior
	
	
## Changes the unit behavior.
func set_behavior(behavior: Behavior) -> void:
	var old := _behavior
	_behavior = behavior
	behavior_changed.emit(old, behavior)
	
	
## Returns true if unit is selectable.
func is_selectable() -> bool:
	return _selectable
	
	
## Makes the unit selectable or not.
func set_selectable(selectable: bool) -> void:
	_selectable = selectable
	
	
## Returns true if the unit is currently selected.
func is_selected() -> bool:
	if is_fielded():
		return map_object.selected
	return false
	
	
## Returns the unit stat.
func get_stat(stat: StringName) -> int:
	return _stats[stat]
	
	
## Sets the unit stat.
func set_stat(stat: StringName, value: int) -> void:
	if stat == &'bond':
		set_bond(value)
	else:
		_stats[stat] = value
		stat_changed.emit(stat, value)
	
	
## Sets the bond level of this unit.
func set_bond(value: int) -> void:
	_bond = value
	stat_changed.emit(&'bond', value)
	

## Returns the bond level.
func get_bond() -> bool:
	return _bond
	
	
## Returns this unit's basic attack.
func basic_attack() -> Attack:
	return _unit_type.basic_attack
	
	
## Returns this unit's special attack.
func special_attack() -> Attack:
	return _unit_type.special_attack
	
	
## Returns the attack range of a given attack.
func get_attack_range(attack: Attack) -> int:
	return attack.attack_range(get_stat(&'rng'))


## Returns the cells in range.
func get_cells_in_range(attack: Attack) -> PackedVector2Array:
	return attack.get_cells_in_range(get_position(), get_stat(&'rng'))


## Returns an array of cells in the target aoe.
func get_target_cells(attack: Attack, target: Vector2, target_rotation: float) -> PackedVector2Array:
	return attack.get_target_cells(target, target_rotation)
	
	
## Set to true or false to override special unlock, or null for default rules.
func set_special_unlocked(value: Variant) -> void:
	if value == null:
		_special_unlock = -1
	else:
		_special_unlock = int(value)
	
	
## Returns true if unit special is unlocked.
func is_special_unlocked() -> bool:
	if _special_unlock == -1:
		return _bond >= 2
	return bool(_special_unlock)
	
	
## Adds status effect to unit.
func add_status_effect(effect: StringName, duration: int) -> void:
	_status_effects[effect] = duration
	status_effect_added.emit(effect, duration)
	
	
## Removes status effect from unit.
func remove_status_effect(effect: StringName) -> void:
	_status_effects.erase(effect)
	status_effect_removed.emit(effect)

	
## Returns true if unit has a specific status effect.
func has_status_effect(effect: String) -> bool:
	return effect in _status_effects
	
	
## Ticks all status effects, triggering them and reducing duration by one.
func tick_status_effects() -> void:
	var expired_effects := []
	for effect in _status_effects:
		match effect:
			&'PSN':
				take_damage(Game.battle.get_config_value(&'poison_damage'), &'PSN')
			&'STN':
				set_turn_flag(IS_DONE)
			&'VUL':
				pass
			&'BLK':
				pass
		_status_effects[effect] -= 1
		if _status_effects[effect] <= 0:
			expired_effects.append(effect)
	for effect in expired_effects:
		remove_status_effect(effect)
	
	
## Removes all status effects.
func clear_status_effects() -> void:
	for effect in _status_effects.duplicate():
		remove_status_effect(effect)
	
	
## Returns the cell this unit is residing in.
func cell() -> Vector2:
	return Map.cell(_map_position)
	
	
## Returns the position of this unit.
func get_position() -> Vector2:
	return _map_position
	
	
## Sets the position of this unit.
func set_position(pos: Vector2) -> void:
	if is_fielded():
		map_object.map_position = pos # this will sync to our _map_position
	else:
		_map_position = pos


## Returns the global position of this unit.
func get_global_position() -> Vector2:
	return battle.world().as_global(get_position())


## Sets the global position of this unit.
func set_global_position(pos: Vector2) -> void:
	set_position(battle.world().as_uniform(pos))
	
	
## Returns true if this unit is on standby.
func is_standby() -> bool:
	return _map_position == Map.OUT_OF_BOUNDS
	
	
## Makes this unit face towards target.
func face_towards(target: Vector2) -> void:
	if is_fielded():
		map_object.heading = Map.to_heading(map_object.map_position.angle_to_point(target))
	else:
		_heading = Map.to_heading(_map_position.angle_to_point(target))
	
	
## Returns the direction this unit is facing.
func get_heading() -> Map.Heading:
	return _heading	
	
	
## Sets the direction this unit is facing.
func set_heading(heading: Map.Heading) -> void:
	if is_fielded():
		map_object.heading = heading
	else:
		_heading = heading
	
	
## Sets this units walk speed.
func walk_speed() -> float:
	return _walk_speed


## Returns true if alive.
func is_alive() -> bool:
	return _state != State.INVALID and _state != State.DYING and _state != State.DEAD
	

## Returns true if unit is playing death animation.
func is_dying() -> bool:
	return _state == State.DYING
		

## Returns true if dead.
func is_dead() -> bool:
	return _state == State.DEAD
	
	
## Returns true if the unit is a valid target.
func is_valid_target() -> bool:
	return not is_standby() and is_alive() and is_selectable() and is_fielded()
	

## Returns true if unit can path over cell.
func is_pathable(_cell: Vector2) -> bool:
	for pathable in battle.get_pathables_at(_cell):
		if not pathable.is_pathable(self):
			return false
	return true
	
	
## Returns true if unit can be placed over cell.
func is_placeable(_cell: Vector2) -> bool:
	return not battle.is_occupied(_cell) and is_pathable(_cell)
#endregion Unit State


#region Unit Actions
## Sets the turn flag.
func set_turn_flag(flag: int) -> void:
	_turn_flags |= flag
	
	
## Clears the turn flag.
func clear_turn_flag(flag: int) -> void:
	_turn_flags &= ~flag
	
	
## Checks if the turn flag is set.
func is_turn_flag_set(flag: int) -> bool:
	return _turn_flags & flag == flag
	
	
## Returns true if this unit can move.
func can_move() -> bool:
	return not is_turn_flag_set(IS_DONE | HAS_ATTACKED | HAS_MOVED)
	
	
## Returns true if this unit can attack.
func can_attack() -> bool:
	return not is_turn_flag_set(IS_DONE | HAS_ATTACKED)
	

## Returns true if this unit can act.
func can_act() -> bool:
	return can_move() # if you can at least move, you can act
	

## Returns true if this unit has taken any actions.
func has_taken_action() -> bool:
	return is_turn_flag_set(HAS_ATTACKED) or is_turn_flag_set(HAS_MOVED)


## Makes unit walk towards cell.
func walk_towards(target: Vector2) -> void:
	if is_walking():
		stop_walking()
	var start := _map_position
	var old_state := _state
	set_state(State.WALKING)
	walking_started.emit(start, target)
	if target != cell():
		await driver.start_driver(pathfind_to(target))
	set_state(old_state)
	walking_finished.emit(start, target)
	

## Returns true if unit is walking.
func is_walking() -> bool:
	return driver.is_walking()
	
	
## Makes unit stop walking.
func stop_walking() -> void:
	driver.stop_driver()
	
	
## Pathfinds to a cell.
func pathfind_to(target: Vector2) -> PackedVector2Array:
	# don't go through all that trouble if target == cell
	if target == cell():
		return [target]

	var pathable_cells := get_pathable_cells(false)

	# append the target in pathable list so we can path to it
	if target not in pathable_cells:
		pathable_cells.append(target)

	# pathfind
	var pathfinder := PathFinder.new(map_object.world, pathable_cells)
	var path := pathfinder.calculate_point_path(cell(), target)
	
	# starting from the end, trim off path until we get a spot we can land on
	for i in range(path.size() - 1, -1, -1):
		if (not Game.battle.is_occupied(path[i])) and (Util.cell_distance(cell(), path[i]) <= _stats.mov):
			return path.slice(0, i + 1)
			
	return path


## Returns an array of cells this unit can path through.
func get_pathable_cells(use_mov_stat := false) -> PackedVector2Array:
	return Util.flood_fill(cell(), _stats.mov if use_mov_stat else 20, Game.battle.world_bounds(), is_pathable)
	
	
## Makes unit take damage.
func take_damage(value: int, source: Variant) -> void:
	# this will emit the hp changed signal
	set_stat(&'hp', clampi(_stats.hp - value, 0, _stats.maxhp))
	
	# emit more specific signal
	damaged.emit(value, source)
	
	# hurt animation
	var old_state := _state
	set_state(State.HURT)
	await map_object.unit_model.animation_finished
	set_state(old_state)
	
	# die
	if get_stat(&'hp') <= 0:
		kill()
	
	
## Makes unit heal from damage.
func restore_health(value: int, source: Variant) -> void:
	# this will emit the hp changed signal
	set_stat(&'hp', clampi(_stats.hp + value, 0, _stats.maxhp))
	
	# emit more specific signal
	healed.emit(value, source)
	
	
## Kills a unit.
func kill() -> void:
	# dying animation
	set_state(State.DYING)
	await map_object.unit_model.animation_finished
	
	# dead
	set_state(State.DEAD)
	map_object.set_standby(true)
	died.emit()


## Revives unit if dead.
func revive() -> void:
	set_stat(&'hp', 1)
	set_state(State.IDLE)
	map_object.set_standby(false)
	
	
## Multicasts the attack on target cell.
func use_attack(_attack: Attack, _cells: PackedVector2Array, _rotations: PackedFloat64Array) -> void:
	print('attack!')
#endregion Unit Actions


## Returns this unit's map object, or [code]null[/code] if unfielded.
func get_map_object() -> MapObject:
	return map_object


#region Serialization
## Returns a dictionary of this unit's state.
func save_state() -> Dictionary:
	return {
		id = _id,
		chara_id = _chara_id,
		chara = _chara,
		display_name = _display_name,
		display_icon = _display_icon,
		unit_type = _unit_type,
		model_scale = _model_scale,
		empire = _empire,
		behavior = _behavior,
		state = _state,
		turn_flags = _turn_flags,
		selectable = _selectable,
		stats = _stats.duplicate(),
		bond = _bond,
		special_unlock = _special_unlock,
		status_effects = _status_effects.duplicate(),
		heading = _heading,
		map_position = _map_position,
		walk_speed = _walk_speed,
		phase_flags = _phase_flags,
	}
	
	
## Loads the unit from data.
func load_state(data: Dictionary):
	_id = data.id
	_chara_id = data.chara_id
	_chara = data.chara
	_display_name = data.display_name
	_display_icon = data.display_icon
	_unit_type = data.unit_type
	_model_scale = data.model_scale
	_empire = data.empire
	_behavior = data.behavior
	_state = data.state
	_turn_flags = data.turn_flags
	_selectable = data.selectable
	_stats = data.stats
	_bond = data.bond
	_special_unlock = data.special_unlock
	_status_effects = data.status_effects
	_heading = data.heading
	_map_position = data.map_position
	_walk_speed = data.walk_speed
	_phase_flags = data.phase_flags
#region Serialization
