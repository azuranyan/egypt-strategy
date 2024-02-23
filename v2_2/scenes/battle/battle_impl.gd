class_name BattleImpl extends Battle

signal _death_animations_finished


enum State {
	INVALID = -1,
	STANDBY,
	AI_PREP,
	PLAYER_PREP,
	BATTLE_START,
	CYCLE_START,
	CYCLE_END,
	TURN_START,
	TURN_END,
	ON_TURN,
	BATTLE_END,
}


@export var _attacker: Empire
@export var _defender: Empire
@export var _territory: Territory
@export var _map_id: int

@export var _turns: int
@export var _turn_queue: Array[Empire]
@export var _should_end: bool
@export var _result_value: int

@export var _quick: bool
@export var _battle_phase: bool

@export var _dying_units: int
@export var _next_state: State


var last_acting_unit: Unit
var level: Level
var agents: Dictionary


## Starts the battle cycle.
@warning_ignore("shadowed_variable")
func start_battle(_attacker: Empire, _defender: Empire, _territory: Territory, _map_id: int) -> void:
	# initialize context
	self._attacker = _attacker
	self._defender = _defender
	self._territory = _territory
	self._map_id = _map_id
	
	self._turns = 0
	self._should_end = false
	self._result_value = BattleResult.NONE
	
	self._quick = not _attacker.is_player_owned() and not _defender.is_player_owned()
	self._battle_phase = false
	self._next_state = State.STANDBY
	
	# do battle
	if _quick:
		_quick_battle.call_deferred()
	else:
		_real_battle.call_deferred()
	
	
func _quick_battle():
	battle_started.emit(_attacker, _defender, _territory, _map_id)
	print("Entering quick battle.")
	# TODO randomize or simulate the victor
	_result_value = BattleResult.ATTACKER_VICTORY
	battle_ended.emit(get_battle_result())
	
	
func _real_battle():
	print("Entering real battle.")
	SceneManager.call_scene(SceneManager.scenes.battle, 'fade_to_black')
	await SceneManager.transition_finished
	hud().menu_button.pressed.connect(show_pause_menu)
	level = get_active_battle_scene().level
	
	_distribute_units()
	_field_units()
		
	# initialize agents and ai placement
	create_agent(_attacker)
	create_agent(_defender)

	# do battle
	await _real_battle_main()

	for agent in agents.values():
		agent.queue_free()
	agents.clear()
	
	_unfield_units()

	SceneManager.scene_return('fade_to_black')
		

func _distribute_units():
	print("[Battle] Redistributing units.")
	for u in level.objects:
		if not u is UnitMapObject:
			continue

		if u.empire_id.is_empty():
			print('[Battle] Pre-placed unit missing `empire_id`.')
			u.queue_free()
			continue

		var empire := Game.overworld.get_empire_by_chara_id(u.empire_id)
		if empire:
			#u.set_meta("preplaced", true)
			#Game.create_unit(null, 
			#spawn_unit(u.unit_type, empire, {map_unit=u, map_position=u.map_position})
			push_error('not implemented')
			pass
		u.queue_free()

	
func _field_units():
	UnitEvents.state_changed.connect(_on_unit_state_changed)
	UnitEvents.died.connect(_on_unit_death)
	get_tree().call_group(Game.ALL_UNITS_GROUP, 'field_unit')
	
	
func _unfield_units():
	UnitEvents.state_changed.disconnect(_on_unit_state_changed)
	UnitEvents.died.disconnect(_on_unit_death)
	get_tree().call_group(Game.ALL_UNITS_GROUP, 'unfield_unit')
		
		
func _on_unit_state_changed(_unit: Unit, _old: Unit.State, _new: Unit.State):
	if _new == Unit.State.DYING:
		_dying_units += 1
		
		
func _on_unit_death(_unit: Unit):
	if _dying_units <= 0:
		return
	assert(_dying_units >= 0)
	_dying_units -= 1
	_death_animations_finished.emit()
	

func _real_battle_main():
	while true:
		if check_for_battle_end():
			_next_state = State.BATTLE_END

		match _next_state:
			State.INVALID:
				push_error('invalid state')
			
			State.STANDBY:
				_next_state = State.AI_PREP

			State.AI_PREP:
				_turn_queue = [ai()]
				await agents[on_turn()].prepare_units()
				_next_state = State.PLAYER_PREP

			State.PLAYER_PREP:
				_turn_queue = [player()]
				hud().update()
				player_prep_phase.emit()
				await agents[on_turn()].prepare_units()
				battle_started.emit(_attacker, _defender, _territory, _map_id)
				_next_state = State.BATTLE_START

			State.BATTLE_START:
				hud().hide()
				await get_active_battle_scene().show_battle_start()
				hud().show()
				_battle_phase = true
				_next_state = State.CYCLE_START
			
			State.CYCLE_START:
				_turn_queue = [_attacker, _defender]

				cycle_started.emit(_turns)
				_next_state = State.TURN_START

			State.TURN_START:
				if last_acting_unit:
					await set_camera_target(last_acting_unit.get_map_object().position)
				get_active_battle_scene().hud_visibility_control.show()
				await hud().show_turn_banner(1)
				get_active_battle_scene().hud_visibility_control.visible = on_turn().is_player_owned()

				for u in Game.get_empire_units(on_turn()):
					u.tick_status_effects()

				turn_started.emit(on_turn())
				_next_state = State.ON_TURN

			State.ON_TURN:
				await agents[on_turn()].start_turn()
				_next_state = State.TURN_END

			State.TURN_END:
				clear_overlays()
				
				for u in Game.get_empire_units(on_turn()):
					if not u.has_taken_action():
						u.restore_health(get_config_value('idle_heal_value'), self)

				var empire: Empire = _turn_queue.pop_front()
				turn_ended.emit(empire)
				if _turn_queue.is_empty():
					_next_state = State.CYCLE_END
				else:
					_next_state = State.TURN_START

			State.CYCLE_END:
				cycle_ended.emit(_turns) 
				_turns += 1
				_next_state = State.CYCLE_START

			State.BATTLE_END:
				battle_ended.emit(get_battle_result())
				if _result_value != BattleResult.CANCELLED and _result_value != BattleResult.NONE:
					await get_active_battle_scene().show_battle_results()
				_next_state = State.INVALID
				break
		
	
## Checks for battle end.
func check_for_battle_end() -> bool:
	if not (_next_state > State.PLAYER_PREP):
		return false

	var result := evaluate_battle_result()
	if not result.is_none():
		stop_battle()
	
	if _should_end or should_end_turn(on_turn()):
		agents[on_turn()].end_turn()
		return true
	return false
	

## Returns true if empire should end turn.
func should_end_turn(empire: Empire) -> bool:
	if not Preferences.auto_end_turn:
		return false
	for u in Game.get_empire_units(empire):
		if u.can_act():
			return false
	return true
	
	
func wait_for_death_animations():
	if _dying_units > 0:
		await _death_animations_finished
	

## Returns the active overworld scene. Kind of a hack, but yes.
func get_active_battle_scene() -> BattleScene:
	assert(is_running(), 'overworld not running!')
	return get_tree().current_scene
	
	
## Creates the agent for the empire.
func create_agent(empire: Empire) -> BattleAgent:
	var agent: BattleAgent
	if empire.is_player_owned():
		agent = load("res://scenes/battle/agents/player_agent.tscn").instantiate()
	else:
		agent = load("res://scenes/battle/agents/ai_agent.tscn").instantiate()
	add_child(agent)
	agent.name = empire.leader_name()
	agent.initialize(empire)
	agents[empire] = agent
	return agent
		
	
func end_battle(result_value: int):
	_result_value = result_value
	_should_end = true
	agents[on_turn()].force_end()
	
	
## Stops the battle cycle.
func stop_battle() -> void:
	if not is_running():
		return
	
	_should_end = true
	

## Returns true if the battle is running.
func is_running() -> bool:
	# a small hack to get the current overworld scene
	return get_tree().current_scene is BattleScene
	
	
## Returns true if battle should end.
func should_end() -> bool:
	return _should_end
	
	
## Returns the ai-controlled empire.
func ai() -> Empire:
	return _defender if _attacker.is_player_owned() else _attacker
	
	
## Returns the player-controlled empire.
func player() -> Empire:
	return _attacker if _attacker.is_player_owned() else _defender
	
	
## Returns the attacking empire.
func attacker() -> Empire:
	return _attacker
	

## Returns the defender empire.
func defender() -> Empire:
	return _defender
	
	
## Returns the territory the battle is happening on.
func territory() -> Territory:
	return _territory
	
	
## Returns the map id being used.
func map_id() -> int:
	return _map_id
	
	
## Returns the battle missions.
func missions() -> Array[VictoryCondition]:
	return level.map.victory_conditions
	
	
## Returns the battle bonus goals.
func bonus_goals() -> Array[VictoryCondition]:
	assert(false, 'not implemented')
	return []


## Returns the empire currently on turn.
func on_turn() -> Empire:
	return null if _turn_queue.is_empty() else _turn_queue.front()
	

## Returns true if battle is on battle phase.
func is_battle_phase() -> bool:
	return _battle_phase
	

## Returns true if this is a training battle.
func is_training_battle() -> bool:
	return false
	
	
## Returns true if this is a quick battle.
func is_quick_battle() -> bool:
	return _quick
	
	
## Returns true if saving is allowed.
func saving_allowed() -> bool:
	return false
	
	
## Returns the unit at cell.
func get_unit_at(cell: Vector2, excluded: Unit = null) -> Unit:
	for obj in get_objects_at(cell):
		if obj is UnitMapObject and obj.unit and obj.unit != excluded and obj.unit.is_valid_target():
			return obj.unit
	return null
		

## Returns true if cell is occupied by a unit.
func is_occupied(cell: Vector2, excluded: Unit = null) -> bool:
	return get_unit_at(cell, excluded) != null
	
	
## Returns the objects at cell.
func get_objects_at(cell: Vector2) -> Array[MapObject]:
	if not level.is_within_bounds(cell):
		return []
	return level.get_objects_at(cell)
	

## Returns all the pathables.
func get_pathables() -> Array[PathableComponent]:
	return level.pathables


## Returns all the pathables at cell.
func get_pathables_at(cell: Vector2) -> Array[PathableComponent]:
	if not level.is_within_bounds(cell):
		return []
	return level.get_pathables_at(cell)


## Returns the world.
func world() -> World:
	return level.map.world

	
## Returns the world bounds.
func world_bounds() -> Rect2:
	return level.get_bounds()


## Returns the out of bounds location in global coordinates.
func global_out_of_bounds() -> Vector2:
	return world().as_global(Map.OUT_OF_BOUNDS)


## Returns the global coordinates of a screen position.
## Screen positions are affected by camera transformation so this conversion is necessary.
func screen_to_global(screen_pos: Vector2) -> Vector2:
	return get_viewport().canvas_transform.affine_inverse() * screen_pos


## Returns the uniform coordinates of a screen position.
## Screen positions are affected by camera transformation so this conversion is necessary.
func screen_to_uniform(screen_pos: Vector2) -> Vector2:
	return world().as_uniform(screen_to_global(screen_pos))


## Returns the cell of a screen position.
## Screen positions are affected by camera transformation so this conversion is necessary.
func screen_to_cell(screen_pos: Vector2) -> Vector2:
	return Map.cell(screen_to_uniform(screen_pos))


## Returns the mouse position in uniform coordinates.
func get_uniform_mouse_position() -> Vector2:
	return world().as_uniform(world().get_global_mouse_position())


## Returns the mouse cell.
func get_mouse_cell() -> Vector2:
	return Map.cell(get_uniform_mouse_position())


## Returns the spawn points
func get_spawn_points(type: SpawnPoint.Type) -> Array[SpawnPoint]:
	return level.get_spawn_points(type)


## Returns the battle result.
func get_battle_result() -> BattleResult:
	return BattleResult.new(_result_value, _attacker, _defender, _territory, _map_id)
	
	
## Evaluates victory conditions and returns first valid result.
func evaluate_battle_result() -> BattleResult:
	for vc in missions():
		_result_value = vc.evaluate()
		if _result_value != BattleResult.NONE:
			break
	return get_battle_result()
	

## Returns a config variable.
func get_config_value(config: StringName) -> Variant:
	var config_data := {
		poison_damage = 1,
		idle_heal_value = 1,
	}
	return config_data.get(config, null)
	
	
## Adds a map object.
func add_map_object(map_object: MapObject) -> void:
	#level.add_object(map_object)
	level.map.add_child(map_object)
	
	
## Removes a map object.
func remove_map_object(map_object: MapObject) -> void:
	#level.remove_object(map_object)
	level.map.remove_child(map_object)


## Draws overlays.
func draw_overlay(_cells: PackedVector2Array, _overlay: Overlay) -> void:
	# TODO yes i know this is stupid, but i need the debugging info
	# for this so i want them to be separate for now
	var overlays := {
		Overlay.PATHABLE: level.pathing_overlay,
		Overlay.ATTACK_RANGE: level.attack_range_overlay,
		Overlay.TARGET_SHAPE: level.target_shape_overlay, 
		Overlay.PATH: level.unit_path,
	}

	for overlay in overlays:
		if _overlay == overlay:
			overlays[overlay].set_cells(_cells)
		else:
			overlays[overlay].erase_cells(_cells)
	
	
## Clears overlays.
func clear_overlays(overlay_mask: int = PATHABLE_MASK | ATTACK_RANGE_MASK | TARGET_SHAPE_MASK | PATH_MASK) -> void:
	if overlay_mask & (1 << Overlay.PATHABLE):
		level.pathing_overlay.clear()
	if overlay_mask & (1 << Overlay.ATTACK_RANGE):
		level.attack_range_overlay.clear()
	if overlay_mask & (1 << Overlay.TARGET_SHAPE):
		level.target_shape_overlay.clear()
	if overlay_mask & (1 << Overlay.PATH):
		level.unit_path.clear()
		
	level.map.pathing_painter.visible = false
	

## Draws the unit path.
func draw_unit_path(unit: Unit, cell: Vector2) -> void:
	clear_overlays(PATH_MASK)
	level.unit_path.initialize(unit.get_pathable_cells(true))
	level.unit_path.draw(unit.cell(), cell)


var used_cells := [
	PackedVector2Array(),
	PackedVector2Array(),
	PackedVector2Array(),
	PackedVector2Array(),
]

## Draws the pathable cells.
func draw_unit_placeable_cells(unit: Unit, use_alt_color := false) -> void:
	clear_overlays(PATHABLE_MASK)
	var color := TileOverlay.TileColor.RED if use_alt_color else TileOverlay.TileColor.GREEN
	var cells := unit.get_placeable_cells()
	level.pathing_overlay.set_cells(cells, color)
	used_cells[Overlay.PATHABLE].clear()
	used_cells[Overlay.PATHABLE].append_array(cells)


func draw_non_pathable_cells(unit: Unit) -> void:
	for x in world().map_size.x:
		for y in world().map_size.y:
			level.map.pathing_painter.set_cell(0, Vector2(x, y), 0, Vector2i(TileOverlay.TileColor.BLACK, 0))
	for cell in unit.get_pathable_cells():
		level.map.pathing_painter.erase_cell(0, cell)
	level.map.pathing_painter.z_index = 0
	level.map.pathing_painter.visible = true
	

## Draws the cells that can be reached by specified attack.
func draw_unit_attack_range(unit: Unit, attack: Attack) -> void:
	clear_overlays(ATTACK_RANGE_MASK)
	var cells := unit.attack_range_cells(attack)
	level.attack_range_overlay.set_cells(cells, TileOverlay.TileColor.RED)
	used_cells[Overlay.ATTACK_RANGE].clear()
	used_cells[Overlay.ATTACK_RANGE].append_array(cells)


## Draws the cells in target aoe.
func draw_unit_attack_target(unit: Unit, attack: Attack, target: Array[Vector2], rotation: Array[float]) -> void:
	clear_overlays(TARGET_SHAPE_MASK)
	used_cells[Overlay.TARGET_SHAPE].clear()
	for i in target.size():
		var cells := unit.attack_target_cells(attack, target[i], rotation[i])
		level.target_shape_overlay.set_cells(cells, TileOverlay.TileColor.BLUE)
	used_cells[Overlay.TARGET_SHAPE].append_array(level.target_shape_overlay.get_used_cells_by_color(TileOverlay.TileColor.BLUE))


## Sets the camera target. If target are either [Unit] or [Node2D],
## the camera will follow it and if target is [Vector2], the camera
## will be fixed to that position. Setting this to [code]null[/code]
## will stop following the previous target node.
func set_camera_target(target: Variant) -> void:
	var final_pos := _camera_target_position(target)
	get_active_battle_scene().set_camera_target(target)
	while get_active_battle_scene().camera.position != final_pos:
		await get_tree().process_frame


func _camera_target_position(target: Variant) -> Vector2:
	if target is Unit:
		return target.get_map_object().position
	elif target is Node2D:
		return target.position
	elif target is Vector2 or target is Vector2i:
		return target
	return get_active_battle_scene().camera.position
		

var cursor_pos: Vector2 = Vector2.ZERO:
	set(value):
		cursor_pos = value
		# if is_instance_valid(level):
		# 	var tween := create_tween()
		# 	tween.tween_property(level.cursor, 'position', world().as_global(Map.cell(cursor_pos)), 0.05)
		level.cursor.position = world().as_global(Map.cell(cursor_pos))

		
## Sets the cursor position
func set_cursor_pos(cell: Vector2) -> void:
	cursor_pos = cell


## Returns the cursor position.
func get_cursor_pos() -> Vector2:
	return cursor_pos


## Returns the HUD.
func hud() -> BattleHUD:
	return get_active_battle_scene().hud


func show_pause_menu() -> void:
	get_active_battle_scene().pause_menu.show()


func hide_pause_menu() -> void:
	get_active_battle_scene().pause_menu.hide()


var forfeit_dialog: PauseDialog


func show_forfeit_dialog() -> void:
	hide_forfeit_dialog()

	if not is_battle_phase() and player() == attacker():
		forfeit_dialog = Game.create_pause_dialog("Cancel Attack?", 'Yes', 'No')
	else:
		forfeit_dialog = Game.create_pause_dialog("Forfeit?", 'Confirm', 'Cancel')
		forfeit_dialog.confirm_button.disabled = player() == defender()
	
	var forfeit_confirm: bool = await forfeit_dialog.closed
	if not forfeit_confirm:
		return
	
	if not is_battle_phase():
		end_battle(BattleResult.CANCELLED)
	else:
		if player() == attacker():
			end_battle(BattleResult.ATTACKER_WITHDRAW)
		else:
			end_battle(BattleResult.DEFENDER_WITHDRAW)


func hide_forfeit_dialog() -> void:
	if is_instance_valid(forfeit_dialog):
		forfeit_dialog.hide()
	

#region Actions
## Returns [constant Error.OK] if movement is valid otherwise returns the error code.
func check_unit_move(unit: Unit, cell: Vector2) -> int:
	if unit.is_turn_done():
		return TURN_DONE
		
	if unit.has_moved() or unit.has_attacked():
		return ACTION_ALREADY_TAKEN
		
	if Util.cell_distance(unit.cell(), cell) > unit.get_stat(&'mov'):
		return OUT_OF_RANGE
		
	return OK


## Returns [constant Error.OK] if attack is valid otherwise returns the error code.
func check_unit_attack(unit: Unit, attack: Attack, target: Vector2, rotation: float) -> int:
	if unit.is_turn_done():
		return TURN_DONE
		
	if unit.has_attacked():
		return ACTION_ALREADY_TAKEN
		
	if attack == null:
		return NO_ATTACK
	
	if attack != unit.basic_attack() and attack != unit.special_attack():
		return INVALID_ACTION
		
	if attack == unit.special_attack() and not unit.is_special_unlocked():
		return SPECIAL_NOT_UNLOCKED
				
	var target_distance := Util.cell_distance(target, unit.cell())
	if attack.min_range > 0 and target_distance <= attack.min_range:
		return INSIDE_MIN_RANGE
		
	if target_distance > attack.attack_range(unit.get_stat(&'rng')):
		return OUT_OF_RANGE
		
	var targets := 0
	var has_valid_target := false
	for offs in attack.target_shape:
		var m := Transform2D()
		var t := m.translated(offs).rotated(rotation) * Vector2.ZERO + target
		var u := get_unit_at(t)
		if not u:
			continue
		targets += 1
		if ((attack.target_flags & 1) and self == u
			or (attack.target_flags & 2) and unit.is_ally(u)
			or (attack.target_flags & 4) and unit.is_enemy(u)):
			has_valid_target = true
		
	if targets == 0:
		return NO_TARGET

	if not has_valid_target:
		return INVALID_TARGET
		
	return OK
	
	
## Executes unit action.
func do_action(unit: Unit, action: UnitAction) -> void:
	print('<Action: %s; %s; %s; %s; %s>' % [unit.display_name(), action.cell, action.attack, action.target, action.rotation])
	# allow move in place as do nothing
	if not action.is_move and not action.is_attack or action.is_move and action.cell == unit.cell():
		unit_action_pass(unit)
	else:
		if action.is_move:
			await unit_action_move(unit, action.cell)
		if action.is_attack:
			await unit_action_attack(unit, action.attack, [action.target], [action.rotation])


## Unit does nothing and ends their turn.
func unit_action_pass(unit: Unit) -> void:
	unit.set_is_done(true)

	last_acting_unit = unit
	check_for_battle_end()
	await wait_for_death_animations()


## Unit walks towards a target.
@warning_ignore("redundant_await")
func unit_action_move(unit: Unit, target: Vector2) -> void:
	hud().hide()
	await set_camera_target(unit)

	if on_turn() == ai():
		draw_overlay(unit.get_pathable_cells(true), Battle.Overlay.PATHABLE)
		await get_tree().create_timer(0.5).timeout
		clear_overlays(1 << Battle.Overlay.PATHABLE)
		
	await unit.walk_towards(target)

	await set_camera_target(null)
	hud().show()
	unit.set_has_moved(true)

	last_acting_unit = unit
	check_for_battle_end()
	await wait_for_death_animations()


## Unit executes attack.
@warning_ignore("redundant_await")
func unit_action_attack(unit: Unit, attack: Attack, target: PackedVector2Array, rotation: PackedFloat64Array) -> void:
	hud().show_attack_banner(attack)
	var centroid := Util.centroid(target)
	await set_camera_target(level.map.world.as_global(centroid))

	await unit.use_attack(attack, target, rotation)

	await set_camera_target(unit)
	hud().hide_attack_banner()
	unit.set_has_attacked(true)

	last_acting_unit = unit
	check_for_battle_end()
	await wait_for_death_animations()

		
## Generates an array of all possible actions.
func generate_actions(unit: Unit) -> Array[UnitAction]:
	var re: Array[UnitAction] = []
	
	re.append(UnitAction.do_nothing(unit))
	_get_attack_actions_in_range(unit, unit.basic_attack(), re)
	_get_attack_actions_in_range(unit, unit.special_attack(), re)
	
	for cell in unit.get_pathable_cells(true):
		if cell == unit.cell():
			continue
		# add unit move to new location action
		re.append(UnitAction.move(unit, cell))
		_get_move_attack_actions_in_range(unit, cell, unit.basic_attack(), re)
		_get_move_attack_actions_in_range(unit, cell, unit.special_attack(), re)
	return re
	
	
func _is_action_present(action: UnitAction, actions: Array[UnitAction]) -> bool:
	for other in actions:
		if other != action and action.is_same_action(other):
			return true
	return false
			
	
func _get_attack_actions_in_range(unit: Unit, attack: Attack, dest: Array[UnitAction]):
	const ROTATIONS := [0, PI/2, PI, PI*3/2]
	if not attack:
		return
	for t in unit.attack_range_cells(attack):
		for r in ROTATIONS:
			var action := UnitAction.new(false, Vector2.ZERO, true, attack, t, r)
			if not _is_action_present(action, dest) and check_unit_attack(unit, attack, t, r) == OK:
				dest.append(action)
				
				
func _get_move_attack_actions_in_range(unit: Unit, cell: Vector2, attack: Attack, dest: Array[UnitAction]):
	const ROTATIONS := [0, PI/2, PI, PI*3/2]
	if not attack:
		return
	var original_pos := unit.get_position()
	unit.set_position(cell)
	for t in unit.get_cells_in_range(attack):
		for r in ROTATIONS:
			var action := UnitAction.new(true, cell, true, attack, t, r)
			if not _is_action_present(action, dest) and check_unit_attack(unit, attack, t, r) == OK:
				dest.append(action)
	unit.set_position(original_pos)

	
## Returns true if the given action is a valid action for the unit.
func is_valid_action(action: UnitAction, unit: Unit) -> bool:
	if action.is_move and check_unit_move(unit, action.cell) != OK:
		return false
	if action.is_attack and check_unit_attack(unit, action.attack, action.target, action.rotation) != OK:
		return false
	return unit.can_act()
#endregion Actions
