class_name BattleImpl extends Battle

signal _death_animations_finished


enum State {
	INVALID = -1,
	INITIALIZATION,
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
@export var _training: bool
@export var _battle_phase: bool

@export var _dying_units: int
@export var _next_state: State = State.INVALID


var _waiting_for: StringName
var _battle_scene
var last_acting_empire_unit: Dictionary
var level: Level
var agents: Dictionary
var _is_running: bool

var forfeit_dialog: PauseDialog
var pause_menu: BattlePauseMenu


func _ready() -> void:
	UnitEvents.damaged.connect(_on_unit_damaged)
	BattleEvents.start_battle_requested.connect(start_battle)
	BattleEvents.stop_battle_requested.connect(stop_battle)
	SceneManager.scene_ready.connect(_on_scene_ready)


func save_state() -> Dictionary:
	# save all the unit states
	var unit_states := {}
	for unit in get_tree().get_nodes_in_group(Game.ALL_UNITS_GROUP):
		# not standby, alive, selectable, fielded
		if not unit.is_valid_target():
			continue
		unit_states[unit.id()] = unit.save_state()

	return {
		attacker = _attacker,
		defender = _defender,
		territory = _territory,
		map_id = _map_id,
		turns = _turns,
		turn_queue = _turn_queue.duplicate(),
		should_end = _should_end,
		result_value = _result_value,
		quick = _quick,
		battle_phase = _battle_phase,
		dying_units = _dying_units,
		next_state = _next_state,
		last_acting_empire_unit = last_acting_empire_unit,
		unit_states = unit_states,
	}


func load_state(data: Dictionary) -> void:
	_is_running = false
	_attacker = data.attacker
	_defender = data.defender
	_territory = data.territory
	_map_id = data.map_id
	_turns = data.turns
	_turn_queue.assign(data.turn_queue)
	_should_end = data.should_end
	_result_value = data.result_value
	_quick = data.quick
	_battle_phase = data.battle_phase
	_dying_units = data.dying_units
	_next_state = data.next_state
	last_acting_empire_unit = data.last_acting_empire_unit

	if _next_state != State.INVALID:
		_is_running = true
		SceneManager.scene_ready.connect(_load_battle_scene.bind(data).unbind(1), CONNECT_ONE_SHOT)


## Starts the battle cycle.
@warning_ignore("shadowed_variable")
func start_battle(data: Dictionary) -> void:
	if is_running():
		push_error('battle already running!')
		return
	_is_running = true
	_next_state = State.INITIALIZATION

	# initialize context
	_attacker = data.attacker
	_defender = data.defender
	_territory = data.territory
	_map_id = data.map_id
	_training = data.training
	
	_turns = 0
	_should_end = false
	_result_value = BattleResult.NONE
	
	_quick = not _attacker.is_player_owned() and not _defender.is_player_owned()
	_battle_phase = false
	_next_state = State.INVALID

	# these will be replaced later anyway but just leave it here for peace of mind
	assert(_battle_scene == null)
	_battle_scene = null

	# do battle
	if _quick:
		_quick_battle.call_deferred()
	else:
		_real_battle.call_deferred()
	
	
func _end_battle(result: BattleResult):
	# give out the rewards
	_update_unit_bonds(result)

	# allow at least 1 frame between battle start and end
	# this fixes signals that happen in the same frame
	await get_tree().process_frame

	# unload scene if necessary
	if _battle_scene:
		_unload_battle_scene()
		SceneManager.scene_return('fade_to_black')

	_is_running = false
	print("MOTHERFUCKER WHEN")
	BattleEvents.battle_ended.emit(result)


func _quick_battle():
	BattleEvents.battle_started.emit(_attacker, _defender, _territory, _map_id)
	
	# add variance
	var atk := Overworld.instance().calculate_empire_force_rating(_attacker) * randf_range(0.9, 1.1)
	var def := Overworld.instance().calculate_empire_force_rating(_defender) * randf_range(0.9, 1.1)
	var roll := atk/def + 0.05

	# scale it so enemy is more likely to withdraw the bigger the power gap is
	var power_difference := absf(atk - def)
	var withdraw_chance := clampf(power_difference/(atk + def), 0.1, 0.9)
	var withdraw := randf() < withdraw_chance

	if roll > 1.0:
		if withdraw:
			_result_value = BattleResult.DEFENDER_WITHDRAW
		else:
			_result_value = BattleResult.ATTACKER_VICTORY
	else:
		if withdraw:
			_result_value = BattleResult.ATTACKER_WITHDRAW
		else:
			_result_value = BattleResult.DEFENDER_VICTORY
		
	# end battle
	_end_battle(get_battle_result())


func _real_battle() -> void:
	BattleEvents.battle_started.emit(_attacker, _defender, _territory, _map_id)
	SceneManager.call_scene(SceneManager.scenes.battle, 'fade_to_black')
	SceneManager.scene_ready.connect(_load_battle_scene.bind({}).unbind(1), CONNECT_ONE_SHOT)


func _load_battle_scene(saved_state: Dictionary) -> void:
	# level
	level = get_active_battle_scene().level
	_distribute_units()
	_field_units()

	# agents
	create_agent(_attacker)
	create_agent(_defender)

	if saved_state:
		# restore all the unit states
		var saved_unit_states: Dictionary = saved_state.unit_states
		for id in saved_unit_states:
			Game.load_unit(id).load_state(saved_unit_states[id])

		# start the game from where we left off
		_next_state = saved_state.next_state
	else:
		# start ai prep phase
		start_prep_phase(ai())

		# start the game from the beginning
		_next_state = State.PLAYER_PREP

	# hud
	hud().update()
	hud().menu_button.pressed.connect(show_pause_menu)

	# start other post-load tasks
	BattleEvents.battle_scene_pre_enter.emit()

	# start the main loop after the transition
	await SceneManager.transition_finished
	_real_battle_main()


func _unload_battle_scene() -> void:
	# agents
	for agent in agents.values():
		agent.queue_free()
	agents.clear()
	
	# level
	_unfield_units()
	last_acting_empire_unit.clear()
	level = null

	# hud
	hud().menu_button.pressed.disconnect(show_pause_menu)


func _distribute_units():
	print("[Battle] Redistributing units.")
	for u in level.objects:
		if not u is UnitMapObject:
			continue

		if u.empire_id.is_empty():
			push_warning('[Battle] Pre-placed unit missing `empire_id`, removing.')
			u.queue_free()
			continue

		var empire: Empire
		if u.empire_id == '$ai':
			empire = ai()
		elif u.empire_id == '$player':
			empire = player()
		else:
			empire = Overworld.instance().get_empire_by_leader_id(u.empire_id)

		if not empire:
			push_warning('[Battle] Empire `%s` not found, removing.' % u.empire_id)
			u.queue_free()
			continue
		
		# we just yeet this to the standby
		u.set_meta('preplaced', true)
		# TODO this will cause it to spawn the wrong unit. change to pre-placed unit maybe?
		push_error("pre placed unit not supported yet")
		var unit := Game.create_unit(empire, u.empire_id, null, u.unit_type)
		unit.set_position(u.map_position)
		unit.set_heading(u.heading)
		u.map_position = Map.OUT_OF_BOUNDS
		
	
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
	

## Calls the function and waits for it.
## Keeps track of the name of the function we're waiting for for debugging purposes.
func _call_and_wait(callable: Callable, argv: Array = [], tag: StringName = '') -> void:
	_waiting_for = callable.get_method() if tag.is_empty() else tag
	await callable.callv(argv)
	_waiting_for = ''


func _real_battle_main():
	BattleEvents.battle_scene_entered.emit()

	while not _should_end:
		if check_for_battle_end():
			_next_state = State.INVALID
			break

		match _next_state:
			State.INVALID:
				push_error('invalid state')
			
			State.PLAYER_PREP:
				await _call_and_wait(start_prep_phase, [player()])
				_next_state = State.BATTLE_START

			State.STANDBY:
				_next_state = State.STANDBY

			State.BATTLE_START:
				hud().hide()
				await _call_and_wait(get_active_battle_scene().show_battle_start)
				hud().show()
				_battle_phase = true
				_next_state = State.CYCLE_START
			
			State.CYCLE_START:
				_turn_queue = [_attacker, _defender]

				BattleEvents.cycle_started.emit(_turns)
				_next_state = State.TURN_START

			State.TURN_START:
				await _call_and_wait(pan_to_last_acting_unit, [on_turn()])

				get_active_battle_scene().hud_visibility_control.show()
				await _call_and_wait(hud().show_turn_banner)

				get_active_battle_scene().hud_visibility_control.visible = on_turn().is_player_owned()

				for u in Game.get_empire_units(on_turn()):
					u.tick_status_effects()

				BattleEvents.turn_started.emit(on_turn())
				_next_state = State.ON_TURN

			State.ON_TURN:
				await _call_and_wait(agents[on_turn()].start_turn, [], '%s::start_turn' % agents[on_turn()].agent_name())
				_next_state = State.TURN_END

			State.TURN_END:
				clear_overlays()
				
				for u in Game.get_empire_units(on_turn()):
					# idle heal
					if not u.has_taken_action():
						u.restore_health(get_config_value('idle_heal_value'), self)

					# reset flags
					u.set_has_attacked(false)
					u.set_has_moved(false)
					u.set_turn_done(false)

				var empire: Empire = _turn_queue.pop_front()
				BattleEvents.turn_ended.emit(empire)
				if _turn_queue.is_empty():
					_next_state = State.CYCLE_END
				else:
					_next_state = State.TURN_START

			State.CYCLE_END:
				BattleEvents.cycle_ended.emit(_turns) 
				_turns += 1
				_next_state = State.CYCLE_START
				
		await get_tree().process_frame
	
	# show the battle result banner
	if _result_value != BattleResult.CANCELLED and _result_value != BattleResult.NONE:
		await _call_and_wait(get_active_battle_scene().show_battle_results)

	# start end sequence
	BattleEvents.battle_scene_exiting.emit()
	
	_end_battle(get_battle_result())


func pan_to_last_acting_unit(empire: Empire) -> void:
	if empire in last_acting_empire_unit:
		var unit: Unit = last_acting_empire_unit[empire]
		if is_instance_valid(unit):
			await set_camera_target(unit.get_map_object().position)


func _update_unit_bonds(result: BattleResult) -> void:
	# ignore when no results
	if result.value == BattleResult.NONE or result.value == BattleResult.CANCELLED:
		return
	
	# only attacking gets you a bond point on victory
	if result.defender_won():
		return

	var winner := result.winner()
	if winner.is_player_owned():
		# player units have stricter bond levelling
		for unit in Game.get_empire_units(winner, Game.ALL_UNITS_MASK):
			# exclude units not fielded
			if not unit.is_fielded(): continue

			# exclude units not in play
			if unit.is_standby(): continue

			# exclude units not surviving the battle *not necessary cos death mechanics put them to standby
			if not unit.is_alive(): continue

			# exclude player hero unit
			if unit.chara_id() == Overworld.instance().player_empire().leader_id: continue

			unit.set_bond(unit.get_bond() + 1)
	else:
		# ai units just level up everyone
		for unit in Game.get_empire_units(winner):
			unit.set_bond(unit.get_bond() + 1)


## Checks for battle end.
func check_for_battle_end() -> bool:
	if not (_next_state > State.PLAYER_PREP):
		return false

	var result := evaluate_battle_result()
	if not result.is_none():
		stop_battle(result.value)
	
	if _should_end or should_end_turn(on_turn()):
		agents[on_turn()].end_turn()
		return true
	return false
	

## Returns true if empire should end turn.
func should_end_turn(empire: Empire) -> bool:
	if not Game.settings.auto_end_turn:
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
	return _battle_scene
	
	
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
	if on_turn():
		agents[on_turn()].force_end()
	
	
## Stops the battle cycle.
func stop_battle(result_value: int = BattleResult.CANCELLED) -> void:
	if not is_running():
		return
	
	_result_value = result_value
	_should_end = true
	if on_turn():
		agents[on_turn()].force_end()
	

## Returns true if the battle is running.
func is_running() -> bool:
	return _is_running
	
	
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
func missions() -> Array[Objective]:
	return level.missions
	
	
## Returns the battle bonus goals.
func bonus_goals() -> Array[Objective]:
	return level.bonus_goals


## Returns the empire currently on turn.
func on_turn() -> Empire:
	return null if _turn_queue.is_empty() else _turn_queue.front()
	

## Returns the number of cycles.
func cycle() -> int:
	return _turns


## Returns true if battle is on battle phase.
func is_battle_phase() -> bool:
	return _battle_phase
	

## Returns true if this is a training battle.
func is_training_battle() -> bool:
	return _training
	
	
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
	# does not do anything other than allow objectives to be manually polled for results
	BattleEvents.objectives_evaluated.emit()
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

	
## Draws the pathable cells.
func draw_unit_placeable_cells(unit: Unit, use_alt_color := false) -> void:
	level.pathing_overlay.clear()
	var color := TileOverlay.TileColor.RED if use_alt_color else TileOverlay.TileColor.GREEN
	var cells := unit.get_pathable_cells(true)
	level.pathing_overlay.set_cells(cells, color)



## horrible workaround until custom callables are supported in c# modules.
var _bound_non_pathable_unit: Unit


## Draws non pathable cells that aren't solely units.
func draw_unit_non_pathable_cells(unit: Unit) -> void:
	level.map.pathing_painter.clear()
	# color everything
	for x in world().map_size.x:
		for y in world().map_size.y:
			level.map.pathing_painter.set_cell(0, Vector2(x, y), 0, Vector2i(TileOverlay.TileColor.BLACK, 0))
	
	# erase pathable cells
	_bound_non_pathable_unit = unit
	var pathable_cells := Util.flood_fill(unit.cell(), world_bounds(), 20, _is_pathable_non_unit_cell)
	for cell in pathable_cells:
		level.map.pathing_painter.erase_cell(0, cell)
	level.map.pathing_painter.z_index = 0
	level.map.pathing_painter.visible = true


func _is_pathable_non_unit_cell(cell: Vector2) -> bool:
	for pathable in get_pathables_at(cell):
		if pathable.pathing_group != Map.PathingGroup.UNIT and not pathable.is_pathable(_bound_non_pathable_unit):
			return false
	return true
	

## Draws the cells that can be reached by specified attack.
func draw_unit_attack_range(unit: Unit, attack: Attack) -> void:
	level.attack_range_overlay.clear()
	var cells := unit.attack_range_cells(attack)
	level.attack_range_overlay.set_cells(cells, TileOverlay.TileColor.RED)


## Draws the cells in target aoe.
func draw_unit_attack_target(unit: Unit, attack: Attack, target: Array[Vector2], rotation: Array[float]) -> void:
	level.target_shape_overlay.clear()
	for i in target.size():
		var cells := unit.attack_target_cells(attack, target[i], rotation[i])
		level.target_shape_overlay.set_cells(cells, TileOverlay.TileColor.BLUE)


## Draws the unit path.
func draw_unit_path(unit: Unit, cell: Vector2) -> void:
	level.unit_path.clear()
	level.unit_path.initialize(unit.get_pathable_cells(true))
	level.unit_path.draw(unit.cell(), cell)


## Clears overlays.
func clear_overlays(mask: int = ALL_OVERLAYS) -> void:
	if (mask & PLACEABLE_CELLS) == PLACEABLE_CELLS:
		level.pathing_overlay.clear()
	if (mask & NON_PLACEABLE_CELLS) == NON_PLACEABLE_CELLS:
		level.map.pathing_painter.clear()
	if (mask & ATTACK_RANGE) == ATTACK_RANGE:
		level.attack_range_overlay.clear()
	if (mask & TARGET_SHAPE) == TARGET_SHAPE:
		level.target_shape_overlay.clear()
	if (mask & UNIT_PATH) == UNIT_PATH:
		level.unit_path.clear()


## Sets the camera target. If target are either [Unit] or [Node2D],
## the camera will follow it and if target is [Vector2], the camera
## will be fixed to that position. Setting this to [code]null[/code]
## will stop following the previous target node.
func set_camera_target(target: Variant) -> void:
	if Game.settings.camera_follow == Settings.CameraFollow.DISABLED:
		return

	if Game.settings.camera_follow == Settings.CameraFollow.CURSOR_ONLY and not Util.is_equal(target, level.cursor):
		return

	var final_pos := _camera_target_position(target)
	get_active_battle_scene().set_camera_target(target)

	# BUG when game stops running, but has already freed the resources
	while get_active_battle_scene() and get_active_battle_scene().camera.position != final_pos:
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
	hide_pause_menu()
	pause_menu = preload("res://scenes/battle/hud/pause_menu.tscn").instantiate()
	get_active_battle_scene().add_child(pause_menu)
	pause_menu.resume_button.pressed.connect(hide_pause_menu)
	pause_menu.forfeit_button.pressed.connect(show_forfeit_dialog)
	pause_menu.forfeit_button.disabled = player() == defender()
	pause_menu.save_button.pressed.connect(_stub.bind('save'))
	pause_menu.save_button.disabled = not saving_allowed()
	pause_menu.load_button.pressed.connect(_stub.bind('load'))
	pause_menu.settings_button.pressed.connect(func():
		var settings = load('res://scenes/common/settings_scene.tscn').instantiate()
		get_tree().root.add_child(settings, true)
		settings.initialize(Game.settings)
	)
	pause_menu.quit_to_title_button.pressed.connect(_stub.bind('quit_to_title'))


func hide_pause_menu() -> void:
	if is_instance_valid(pause_menu):
		pause_menu.close()


func _stub(msg: String) -> void:
	print('stub ', msg)


func show_forfeit_dialog() -> void:
	hide_forfeit_dialog()

	if not is_battle_phase() and player() == attacker():
		forfeit_dialog = Game.create_pause_dialog("Cancel Attack?", 'Yes', 'No')
	else:
		forfeit_dialog = Game.create_pause_dialog("Forfeit?", 'Confirm', 'Cancel')
	
	var forfeit_confirm: bool = await forfeit_dialog.closed
	if not forfeit_confirm:
		return

	# is there a way to better do this? 
	hide_pause_menu()
	
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
	
	if is_occupied(cell, unit):
		return ALREADY_OCCUPIED

	if not cell in unit.get_pathable_cells():
		return NOT_PATHABLE

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
	if attack.melee:
		rotation = Map.to_facing(unit.get_heading()) - PI/2
	for offs in attack.target_shape:
		var m := Transform2D()
		var t := m.translated(offs).rotated(rotation) * Vector2.ZERO + target
		var u := get_unit_at(t)
		if not u:
			continue
		targets += 1
		if ((attack.target_flags & 1) and unit.is_self(u)
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
	if not action:
		push_error('no action')
		return
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
	unit.set_turn_done(true)
	hud().set_selected_unit(unit)

	last_acting_empire_unit[unit.get_empire()] = unit
	check_for_battle_end()
	await wait_for_death_animations()


## Unit walks towards a target.
@warning_ignore("redundant_await")
func unit_action_move(unit: Unit, target: Vector2) -> void:
	hud().hide()
	
	await set_camera_target(unit)

	if on_turn() == ai():
		draw_unit_placeable_cells(unit, true)
		await get_tree().create_timer(0.5).timeout
		clear_overlays(PLACEABLE_CELLS)
	
	# TODO this doesn't work anyway because above set_camera_target doesn't
	# wait for panning to finish going to target unit
	get_active_battle_scene().camera.drag_horizontal_enabled = false
	get_active_battle_scene().camera.drag_vertical_enabled = false
	get_active_battle_scene().camera.position_smoothing_enabled = false
	await unit.walk_towards(target)
	get_active_battle_scene().camera.drag_horizontal_enabled = true
	get_active_battle_scene().camera.drag_vertical_enabled = true
	get_active_battle_scene().camera.position_smoothing_enabled = true

	unit.set_has_moved(true)

	await set_camera_target(null)
	hud().set_selected_unit.call_deferred(unit)
	hud().show()

	last_acting_empire_unit[unit.get_empire()] = unit
	check_for_battle_end()
	await wait_for_death_animations()


## Unit executes attack.
@warning_ignore("redundant_await")
func unit_action_attack(unit: Unit, attack: Attack, target: Array[Vector2], rotation: Array[float]) -> void:
	hud().show_attack_banner(attack)
	var old_pos := unit.get_position()
	var centroid := Util.centroid(target)
	await set_camera_target(world().as_global(centroid))

	await unit.use_attack(attack, target, rotation)
	await set_camera_target(unit)
	unit.set_has_attacked(true)
	unit.set_turn_done(true)

	await set_camera_target(unit)
	hud().set_selected_unit(null)
	hud().hide_attack_banner()

	last_acting_empire_unit[unit.get_empire()] = unit
	check_for_battle_end()
	await wait_for_death_animations()
	await set_camera_target(old_pos)


## Generates an array of all possible actions.
func generate_actions(unit: Unit) -> Array[UnitAction]:
	var re: Array[UnitAction] = []
	
	re.append(UnitAction.do_nothing(unit))
	_get_attack_actions_in_range(unit, unit.basic_attack(), re)
	_get_attack_actions_in_range(unit, unit.special_attack(), re)
	
	for cell in unit.get_placeable_cells():
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
	for t in unit.attack_range_cells(attack):
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


func start_prep_phase(empire: Empire) -> void:
	_turn_queue = [empire]
	hud().update()
	BattleEvents.prep_phase_started.emit(empire)
	await agents[empire].prepare_units()
	BattleEvents.prep_phase_ended.emit(empire)
	_turn_queue = []


func _on_unit_damaged(_unit: Unit, amount: int, _source: Variant) -> void:
	if amount > 0:
		get_active_battle_scene().shake_camera()


func _on_scene_ready(node: Node) -> void:
	# this will make it so it's null when a diff scene is loaded
	_battle_scene = node as BattleScene
