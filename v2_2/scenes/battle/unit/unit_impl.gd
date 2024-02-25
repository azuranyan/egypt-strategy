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

## Turn flag.
@export var _has_moved: bool

## Turn flag.
@export var _has_attacked: bool

## Turn flag.
@export var _is_turn_done: bool

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


var map_object: UnitMapObject
var attachments := {}

@onready var driver = $UnitDriver


func _init(__id: int = 0, __chara_id: StringName = &'', __chara: CharacterInfo = null, __unit_type: UnitType = null):
	_id = __id
	_chara_id = __chara_id
	_chara = __chara
	_unit_type = __unit_type
	
	
func reset(initial_state: State):
	set_state(initial_state)
	var _base := base_stats()
	for stat in _base:
		set_stat(stat, _base[stat])
	set_stat(&'hp', _base.maxhp)
	clear_status_effects()
	set_position(Map.OUT_OF_BOUNDS)
	set_heading(Map.Heading.EAST)
	set_has_attacked(false)
	set_has_moved(false)
	set_turn_done(false)
	if is_alive():
		_state = State.IDLE
		
		
func set_state(new_state: State):
	var old_state := _state
	_state = new_state
	UnitEvents.state_changed.emit(self, old_state, new_state)

	
func sync_map_position(old: Vector2, new: Vector2):
	_map_position = new
	UnitEvents.position_changed.emit(self, old, new)
	

func sync_heading(old: Map.Heading, new: Map.Heading):
	_heading = new
	UnitEvents.heading_changed.emit(self, old, new)


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
	map_object.heading_changed.connect(sync_heading)
	Battle.instance().add_map_object(map_object)
	map_object.initialize(self)
	driver.target = map_object
	reset(State.IDLE)
	UnitEvents.fielded.emit(self)
	
	
## Unfields unit from battle.
func unfield_unit() -> void:
	if not is_fielded():
		return
	driver.target = null
	map_object.initialize(null)
	Battle.instance().remove_map_object(map_object)
	map_object.map_position_changed.disconnect(sync_map_position)
	map_object.heading_changed.disconnect(sync_heading)
	map_object.queue_free()
	map_object = null
	reset(State.INVALID)
	UnitEvents.unfielded.emit(self)
	
	
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
	UnitEvents.empire_changed.emit(self, old, empire)
	
	
## Returns true if another unit is an enemy.
func is_enemy(other: Unit) -> bool:
	return not is_ally(other)
	
	
## Returns true if another unit is an ally.
func is_ally(other: Unit) -> bool:
	return (other != self) and (other.get_empire() == self.get_empire())
	

## Returns true if another unit is self.
func is_self(other: Unit) -> bool:
	return other == self

	
## Returns true if this unit is player owned.
func is_player_owned() -> bool:
	return _empire.is_player_owned()
	
	
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
	UnitEvents.behavior_changed.emit(self, old, behavior)
	
	
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
		UnitEvents.stat_changed.emit(self, stat)
	
	
## Sets the bond level of this unit.
func set_bond(value: int) -> void:
	_bond = value
	UnitEvents.bond_changed.emit(self)


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
func attack_range(attack: Attack) -> int:
	return attack.attack_range(get_stat(&'rng'))


## Returns the cells in range.
func attack_range_cells(attack: Attack) -> PackedVector2Array:
	return attack.get_cells_in_range(get_position(), get_stat(&'rng'))


## Returns an array of cells in the target aoe.
func attack_target_cells(attack: Attack, target: Vector2, target_rotation: float) -> PackedVector2Array:
	return attack.get_target_cells(target, target_rotation)
	

## Returns an array of units in the target aoe.
func attack_target_units(attack: Attack, target_cell: Vector2, target_rotation: float) -> Array[Unit]:
	var cells := attack.get_target_cells(target_cell, target_rotation)
	var arr: Array[Unit] = []
	for c in cells:
		var u := Battle.instance().get_unit_at(c)
		if u:
			arr.append(u)
	return arr

	
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
	UnitEvents.status_effect_added.emit(self, effect, duration)
	
	
## Removes status effect from unit.
func remove_status_effect(effect: StringName) -> void:
	_status_effects.erase(effect)
	UnitEvents.status_effect_removed.emit(self, effect)

	
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
				set_turn_done(true)
			&'VUL':
				pass
			&'BLK':
				pass
		_status_effects[effect] -= 1
		if _status_effects[effect] <= 0:
			expired_effects.append(effect)
		UnitEvents.status_effect_ticked.emit(self, effect)
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
	return Battle.instance().world().as_global(get_position())


## Sets the global position of this unit.
func set_global_position(pos: Vector2) -> void:
	set_position(Battle.instance().world().as_uniform(pos))
	
	
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
	if _cell == Map.OUT_OF_BOUNDS:
		return false
	for pathable in Battle.instance().get_pathables_at(_cell):
		if not pathable.is_pathable(self):
			return false
	return true
	
	
## Returns true if unit can be placed over cell.
func is_placeable(_cell: Vector2) -> bool:
	return not Battle.instance().is_occupied(_cell) and is_pathable(_cell)
#endregion Unit State


#region Unit Actions
func play_animation(anim_name: String):
	const ANIM_STATES := {
		attack = State.ATTACKING,
		idle = State.IDLE,
		walking = State.WALKING,
		hurt = State.HURT,
		dying = State.DYING,
		dead = State.DEAD,
	}
	map_object.unit_model.state = ANIM_STATES.get(anim_name, State.IDLE)


## Returns true if unit has moved.
func has_moved() -> bool:
	return _has_moved


## Returns true if unit has attacked.
func has_attacked() -> bool:
	return _has_attacked


## Returns true if unit's turn is done.
func is_turn_done() -> bool:
	return _is_turn_done


## Sets `has_moved` flag of this unit.
func set_has_moved(value: bool) -> void:
	_has_moved = value
	UnitEvents.turn_flags_changed.emit(self)
	
	
## Sets `has_attacked` flag of this unit.
func set_has_attacked(value: bool) -> void:
	_has_attacked = value
	UnitEvents.turn_flags_changed.emit(self)


## Sets `has_attacked` flag of this unit.
func set_turn_done(value: bool) -> void:
	_is_turn_done = value
	UnitEvents.turn_flags_changed.emit(self)


## Returns true if this unit can move.
func can_move() -> bool:
	return not (_is_turn_done or _has_attacked or _has_moved)
	
	
## Returns true if this unit can attack.
func can_attack() -> bool:
	return not (_is_turn_done or _has_attacked)
	

## Returns true if this unit can act.
func can_act() -> bool:
	return can_move() or can_attack()
	

## Returns true if this unit has taken any actions.
func has_taken_action() -> bool:
	return _has_attacked or _has_moved


## Makes unit walk towards cell.
func walk_towards(target: Vector2) -> void:
	if is_walking():
		stop_walking()
	var start := _map_position
	var old_state := _state
	set_state(State.WALKING)
	UnitEvents.walking_started.emit(self, start, target)
	if target != cell():
		await driver.start_driver(pathfind_to(target))
	set_state(old_state)
	UnitEvents.walking_finished.emit(self)


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
	

## Returns an array of cells this unit can be placed on.
func get_placeable_cells() -> PackedVector2Array:
	return Util.flood_fill(cell(), _stats.mov, Game.battle.world_bounds(), is_placeable)
	

## Makes unit take damage.
func take_damage(amount: int, source: Variant) -> void:
	# this will emit the hp changed signal
	set_stat(&'hp', clampi(_stats.hp - amount, 0, _stats.maxhp))
	
	# emit more specific signal
	UnitEvents.damaged.emit(self, amount, source)
	
	# hurt animation
	var old_state := _state
	set_state(State.HURT)
	await map_object.unit_model.animation_finished
	set_state(old_state)
	
	# die
	if get_stat(&'hp') <= 0:
		kill()
	
	
## Makes unit heal from damage.
func restore_health(amount: int, source: Variant) -> void:
	# this will emit the hp changed signal
	set_stat(&'hp', clampi(_stats.hp + amount, 0, _stats.maxhp))
	
	# emit more specific signal
	UnitEvents.healed.emit(self, amount, source)
	
	
## Kills a unit.
func kill() -> void:
	# dying animation
	set_state(State.DYING)
	await map_object.unit_model.animation_finished
	
	# dead
	set_state(State.DEAD)
	map_object.set_standby(true)
	UnitEvents.died.emit(self)


## Revives unit if dead.
func revive() -> void:
	set_stat(&'hp', 1)
	set_state(State.IDLE)
	map_object.set_standby(false)
	
	
## Multicasts the attack on target cell.
func use_attack(attack: Attack, target_cells: Array[Vector2], target_rotations: Array[float]) -> void:
	await execute_attack(AttackState.create_attack_state(self, attack, target_cells, target_rotations))

	
## Executes the attack.
func execute_attack(attack_state: AttackState) -> void:
	UnitEvents.attack_started.emit(self, attack_state)

	# we officially set our state to attacking but the actual animation
	# that will play will depend on attack.user_animation
	var old_state := _state
	set_state(State.ATTACKING)

	# execute attack
	await AttackSystem.execute_attack(attack_state)

	set_state(old_state)
	UnitEvents.attack_finished.emit(self)
#endregion Unit Actions


## Returns this unit's map object, or [code]null[/code] if unfielded.
func get_map_object() -> MapObject:
	return map_object


## Attaches a [Node] to this object.
func attach(node: Node, target: StringName) -> void:
	attachments[node] = find_attachment_point(target)
	attachments[node].add_child(node)


## Detaches a [Node] from this object.
func detach(node: Node) -> void:
	var attachment_point: Node = attachments.get(node)
	if attachment_point:
		attachment_point.remove_child(node)
		attachments.erase(node)


## Finds an attachment point by name.
func find_attachment_point(target: StringName) -> Node:
	var stack := [map_object]

	while stack.size() > 0:
		var current = stack.pop_back()

		if current.name.to_snake_case() == target:
			return current

		for child in current.get_children():
			if child is Node2D:
				stack.push_back(child)
				
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
		has_attacked = _has_attacked,
		has_moved = _has_moved,
		is_turn_done = _is_turn_done,
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
	#_state = data.state
	set_state(data.state)
	set_has_attacked(data.has_attacked)
	set_has_moved(data.has_moved)
	set_turn_done(data.is_turn_done)
	_selectable = data.selectable
	_stats = data.stats
	_bond = data.bond
	_special_unlock = data.special_unlock
	_status_effects = data.status_effects
	#_heading = data.heading
	set_heading(data.heading)
	#_map_position = data.map_position
	set_position(data.map_position)
	_walk_speed = data.walk_speed
	_phase_flags = data.phase_flags
#region Serialization
