class_name PlayerAgent extends BattleAgent



enum {
	STATE_NONE,
	STATE_ROTATE_UNIT,
	STATE_PREP_STANDBY,
	STATE_PREP_PLACING_UNIT,
	STATE_PREP_MOVING_UNIT,
	STATE_BATTLE_STANDBY,
	STATE_BATTLE_SELECTING_MOVE,
	STATE_BATTLE_SELECTING_TARGET,
}

@export var undo_stack_size := 99
@export var interaction_handler: InteractionHandler
@export var rotation_deadzone := 0.2

var battle: Battle
var spawn_points: Array[SpawnPoint]
var state := STATE_NONE
var ghost: Ghost

var selected_unit: Unit:
	set(value):
		Game.deselect_unit(selected_unit)
		selected_unit = value
		Game.select_unit(value)

var active_attack: Attack
var multicast_targets: Array[Vector2]
var multicast_rotations: Array[float]

var unit_drag_start: Vector2
var unit_drag_offset: Vector2

var alt_held := false
var undo_stack: Array[Action] = []

var state_stack: Array[int] = [STATE_NONE]


## Called on initialize.
func _initialize():
	battle = Game.battle
	battle.hud().end_button.pressed.connect(interact_end)
	battle.hud().undo_button.pressed.connect(interact_cancel)
	battle.hud().prep_unit_list.unit_selected.connect(_on_prep_unit_selected)
	battle.hud().prep_unit_list.unit_released.connect(_on_prep_unit_released)
	battle.hud().prep_unit_list.unit_dragged.connect(_on_prep_unit_dragged)
	battle.hud().prep_unit_list.cancelled.connect(_on_prep_cancelled)
	interaction_handler.set_battle_remote_unhandled_input(self)

	spawn_points = battle.get_spawn_points(SpawnPoint.Type.PLAYER)


## Called on start preparation.
func _enter_prepare_units():
	clear_undo_stack()
	UnitEvents.clicked.connect(_on_unit_clicked)
	UnitEvents.input_event.connect(_on_unit_input_event)
	change_state(STATE_PREP_STANDBY)
	
	
## Called on end preparation.
func _exit_prepare_units():
	UnitEvents.clicked.disconnect(_on_unit_clicked)
	UnitEvents.input_event.disconnect(_on_unit_input_event)
	undo_stack.clear()
	change_state(STATE_NONE)
	
	
## Called on turn start.
func _enter_turn():
	clear_undo_stack()
	UnitEvents.clicked.connect(_on_unit_clicked)
	UnitEvents.input_event.connect(_on_unit_input_event)
	change_state(STATE_BATTLE_STANDBY)
	
	
### Called on turn end.
func _exit_turn():
	UnitEvents.clicked.disconnect(_on_unit_clicked)
	UnitEvents.input_event.disconnect(_on_unit_input_event)
	change_state(STATE_NONE)


func _input(event: InputEvent):
	if event is InputEventKey and event.keycode == KEY_ALT:
		alt_held = event.pressed
	
	# skip inputs when alt is held
	if alt_held:
		get_viewport().set_input_as_handled()
		return 

	# i don't fucking get why this is still necessary when we're already doing screen_to_* functions
	#event = Battle.instance().world().make_input_local(event)

	# run handlers
	for handler in [handle_start_rotate_unit, handle_stop_rotate_unit, handle_rotate_unit, handle_start_drag_unit, handle_stop_drag_unit, handle_drag_unit, handle_move_cursor, handle_cancel]:
		if handler.call(event):
			get_viewport().set_input_as_handled()
			return


func _unhandled_input(event):
	if interaction_handler.has_hovered_unit():
		return

	# i don't fucking get why this is still necessary when we're already doing screen_to_* functions
	#event = Battle.instance().world().make_input_local(event)

	# run handlers
	for handler in [handle_cancel, handle_select_cell, handle_quit]:
		if handler.call(event):
			get_viewport().set_input_as_handled()
			return


## Handles rotation interaction.
func handle_start_rotate_unit(event) -> bool:
	if not (state in [STATE_PREP_STANDBY, STATE_BATTLE_STANDBY]
		and event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_MIDDLE
		and event.pressed):
		return false

	var unit := interaction_handler.get_hovered_unit()
	if not can_rotate(unit):
		return false

	interact_start_rotate_unit(unit)
	return true


## Handles rotation interaction.
func handle_stop_rotate_unit(event) -> bool:
	if not (state == STATE_ROTATE_UNIT
		and event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_MIDDLE
		and not event.pressed):
		return false

	interact_stop_rotate_unit()
	return true


## Rotates the unit.
func handle_rotate_unit(event) -> bool:
	if not (state == STATE_ROTATE_UNIT
		and event is InputEventMouseMotion):
		return false
		
	var mpos := battle.screen_to_uniform(event.position)
	if selected_unit.get_position().distance_squared_to(mpos) <= rotation_deadzone*rotation_deadzone:
		return false

	set_mouse_input_mode(true)
	interact_rotate_unit(mpos)
	return true


## Handles drag interaction.
func handle_start_drag_unit(event) -> bool:
	if not (state == STATE_PREP_STANDBY
		and event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed):
		return false

	var unit := interaction_handler.get_hovered_unit()
	if not can_reposition(unit):
		return false

	interact_start_drag_unit(unit)
	return true


## Handles drag interaction.
func handle_stop_drag_unit(event) -> bool:
	if not (state == STATE_PREP_MOVING_UNIT
		and event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and not event.pressed):
		return false

	interact_stop_drag_unit()
	return true


## Moves the unit.
func handle_drag_unit(event) -> bool:
	if not (state == STATE_PREP_MOVING_UNIT
		and event is InputEventMouseMotion):
		return false

	set_mouse_input_mode(true)
	interact_drag_unit(event.position)
	return true


## Moves the cursor.
func handle_move_cursor(event) -> bool:
	if event is InputEventMouseMotion:
		set_mouse_input_mode(true)
		var unit := interaction_handler.get_hovered_unit()
		if unit:
			interact_move_cursor(unit.cell())
		else:
			interact_move_cursor(battle.screen_to_cell(event.position))
		return false

	const ACTIONS := ['right', 'down', 'left', 'up']
	for i in 4:
		if event.is_action_pressed(ACTIONS[i]):
			set_mouse_input_mode(false)
			var new_pos := battle.world().as_uniform(battle.get_cursor_pos()) + Map.DIRECTIONS[i]
			interact_move_cursor(new_pos)
			return true
	
	return false


## Cancel interaction.
func handle_cancel(event) -> bool:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		return false
	set_mouse_input_mode(true)
	interact_cancel()
	return true


## Select cell.
func handle_select_cell(event) -> bool:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return false
	set_mouse_input_mode(true)
	interact_select_cell(battle.get_cursor_pos())
	return true


## Quit.
func handle_quit(event) -> bool:
	if not (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		return false
	interact_quit()
	get_viewport().set_input_as_handled()
	return true


## Changes state to new state.
func change_state(new_state: int):
	_change_state(state, new_state)
	state_stack[-1] = new_state


func _change_state(old_state: int, new_state: int):
	_exit_state(old_state)
	_enter_state(new_state)
	state = new_state


## Changes to new state and pushes it on the stack.
func push_state(new_state: int):
	state_stack.append(new_state)
	_change_state(state_stack[-2], state_stack[-1])


## Pops the current state from the stack and restores the previous state.
func pop_state():
	if state_stack.size() > 1:
		var old_state: int = state_stack.pop_back()
		_change_state(old_state, state_stack[-1])


func _enter_state(st: int):
	if selected_unit and selected_unit.can_move() and st in [STATE_PREP_STANDBY, STATE_BATTLE_STANDBY]:
		battle.draw_unit_placeable_cells(selected_unit, selected_unit.is_player_owned())


func _exit_state(st: int):
	battle.clear_overlays(Battle.PATHABLE_MASK)

	if st == STATE_BATTLE_SELECTING_MOVE:
		battle.clear_overlays(Battle.PATH_MASK)
	

## Creates a ghost at ghost_cell of unit at target cell. 
func update_ghost(target_cell: Vector2, ghost_cell: Vector2):
	if selected_unit and battle.is_occupied(target_cell, selected_unit) and is_spawn_cell(target_cell):
		var occupant := battle.get_unit_at(target_cell, selected_unit)
		set_ghost(occupant, ghost_cell)
	else:
		remove_ghost()


##################################################################################################################
#region Interactions
##################################################################################################################


## Starts the battle.
func interact_start_battle():
	update_message_box()
	if not is_hero_deployed():
		Game.create_pause_dialog('%s required.' % empire.leader_name(), 'Confirm', '')
		return
	end_prepare_units()


## Ends the battle.
func interact_quit():
	update_message_box()
	battle.show_forfeit_dialog()

	
## Ends the turn (or prep phase).
func interact_end():
	update_message_box()
	if not battle.is_battle_phase():
		interact_start_battle()
	else:
		end_turn()
		

## Cancels current interaction.
func interact_cancel():
	update_message_box()
	match state:
		STATE_PREP_STANDBY:
			var hovered_unit := interaction_handler.get_hovered_unit()
			if hovered_unit:
				if can_reposition(hovered_unit):
					interact_remove_unit(hovered_unit)
				else:
					pass # do nothing
			else:
				undo_action()

		STATE_BATTLE_STANDBY:
			undo_action()

		STATE_PREP_MOVING_UNIT:
			interact_stop_drag_unit()

		STATE_BATTLE_SELECTING_MOVE:
			pass

		STATE_BATTLE_SELECTING_TARGET:
			pass


## Starts unit rotate interaction.
func interact_start_rotate_unit(unit: Unit):
	update_message_box()
	selected_unit = unit
	change_state(STATE_ROTATE_UNIT)


## Stops unit rotate interaction.
func interact_stop_rotate_unit():
	update_message_box()
	selected_unit = null
	change_state(STATE_BATTLE_STANDBY if battle.is_battle_phase() else STATE_PREP_STANDBY)


## Rotates the unit to face the target cell.
func interact_rotate_unit(target_cell: Vector2):
	update_message_box()
	selected_unit.face_towards(target_cell)


## Starts unit drag interaction.
func interact_start_drag_unit(unit: Unit):
	update_message_box()
	var from_unit_list := unit.get_position() == Map.OUT_OF_BOUNDS

	selected_unit = unit
	
	unit_drag_start = unit.get_global_position()

	if from_unit_list:
		unit_drag_offset = battle.screen_to_global(unit.get_map_object().grab_offset())
		change_state(STATE_PREP_PLACING_UNIT)
	else:
		unit_drag_offset = battle.screen_to_global(get_viewport().get_mouse_position() - get_viewport().canvas_transform*unit_drag_start)
		change_state(STATE_PREP_MOVING_UNIT)
		

## Stops unit drag interaction.
func interact_stop_drag_unit():
	update_message_box()
	var drop_point := selected_unit.cell()
	selected_unit.set_position(battle.screen_to_cell(unit_drag_start))
	interact_place_unit(selected_unit, drop_point)
	#interact_place_unit(selected_unit, selected_unit.cell())
	selected_unit = null
	change_state(STATE_PREP_STANDBY)


## Moves the unit.
func interact_drag_unit(screen_pos: Vector2):
	selected_unit.set_global_position(battle.screen_to_global(screen_pos) - unit_drag_offset)
	update_ghost(selected_unit.cell(), battle.world().as_uniform(unit_drag_start))

	
## Adds unit to play.
func interact_place_unit(unit: Unit, cell: Vector2):
	update_message_box()
	var old_pos := unit.cell()
	if is_spawn_cell(cell):
		if battle.is_occupied(cell, unit):
			var occupant := battle.get_unit_at(cell, unit)
			assert(occupant.is_player_owned(), 'non player unit at spawn point')
			
			if old_pos == Map.OUT_OF_BOUNDS:
				push_undo_action(ReplaceUnitAction.new(unit, occupant))
			else:
				unit.set_position(old_pos)
				push_undo_action(SwapUnitAction.new(unit, occupant))
		else:
			push_undo_action(PlaceUnitAction.new(unit, cell))
	else:
		if old_pos == Map.OUT_OF_BOUNDS:
			prep_remove_unit(unit)
		else:
			if battle.hud().prep_unit_list.get_global_rect().has_point(battle.world().as_global(cell)):
				prep_remove_unit(unit)
			else:
				unit.set_position(old_pos)


## Removes unit from play.
func interact_remove_unit(unit: Unit):
	update_message_box()
	if unit:
		push_undo_action(RemoveUnitAction.new(unit))


## Moves the cursor to the specified position.
func interact_move_cursor(cell: Vector2):
	update_message_box()
	battle.set_cursor_pos(cell)
	match state:
		STATE_BATTLE_SELECTING_MOVE:
			battle.draw_unit_path(selected_unit, cell)

		STATE_BATTLE_SELECTING_TARGET:
			if active_attack.melee:
				selected_unit.face_towards(cell)
				var attack_cell: Vector2 = selected_unit.cell() + Map.DIRECTIONS[selected_unit.get_heading()] * selected_unit.get_attack_range(active_attack)
				battle.set_cursor_pos(attack_cell)
			
			battle.draw_unit_attack_target(selected_unit, active_attack, multicast_targets, multicast_rotations)


## Selects the cell.
func interact_select_cell(cell: Vector2):
	update_message_box()
	battle.set_cursor_pos(cell)
	match state:
		STATE_PREP_STANDBY, STATE_BATTLE_STANDBY:
			interact_select_unit(battle.get_unit_at(cell))

		STATE_BATTLE_SELECTING_MOVE:
			push_undo_action(UnitMoveAction.new(selected_unit, cell))

		STATE_BATTLE_SELECTING_TARGET:
			interact_select_target(cell)


## Selects the unit.
func interact_select_unit(unit: Unit):
	update_message_box()

	selected_unit = unit
	if not unit:
		return

	battle.set_cursor_pos(unit.cell())
	match state:
		STATE_PREP_STANDBY, STATE_PREP_MOVING_UNIT:
			push_undo_action(SelectUnitAction.new(unit))
			
		STATE_BATTLE_STANDBY, STATE_BATTLE_SELECTING_MOVE:
			push_undo_action(SelectUnitAction.new(unit))

		STATE_BATTLE_SELECTING_TARGET:
			interact_select_target(unit.cell())


## Selects the attack.
func interact_select_attack(unit: Unit, attack: Attack):
	update_message_box()
	# 	_select_unit(unit)
	# 	multicast_targets.clear()
	# 	multicast_rotations.clear()
	# 	if attack:
	# 		battle.draw_unit_attack_range(unit, attack)
	# 		state = STATE_BATTLE_SELECTING_TARGET
	# 	active_attack = attack


## Selects the attack target.
func interact_select_target(cell: Vector2):
	update_message_box()
	var err := battle.check_unit_attack(selected_unit, active_attack, cell, 0)
	if err == Battle.OK:
		push_undo_action(SelectTargetAction.new(selected_unit, active_attack, cell, 0))
		if active_attack.multicast <= 0 or multicast_targets.size() > active_attack.multicast:
			pass # TODO
	else:
		const message := {
			Battle.SPECIAL_NOT_UNLOCKED: "Ability not unlocked.",
			Battle.INSIDE_MIN_RANGE: "Target inside minimum range.",
			Battle.OUT_OF_RANGE: "Target outside range.",
			Battle.NO_TARGET: "No target found.",
			Battle.INVALID_TARGET: "Invalid target.",
		}
		Game.play_error_sound()
		update_message_box(message.get(err, ""))


##################################################################################################################
#endregion Interactions
##################################################################################################################


## Pushes the action to the undo stack.
func push_undo_action(action: Action):
	if undo_stack.size() > undo_stack_size:
		undo_stack.pop_front()

	if action.execute():
		battle.hud().undo_button.disabled = false
		if undo_stack.size() >= 1 and undo_stack.back().type_tag() == action.type_tag():
			action.collapse = true
		undo_stack.append(action)
		update_undo_text()


## Undo's an action.
func undo_action():
	if undo_stack.is_empty():
		return

	var last_action: Action = undo_stack.pop_back()
	last_action.undo()
	battle.hud().undo_button.disabled = undo_stack.is_empty()
	update_undo_text()

	if last_action.should_collapse():
		undo_action.call_deferred()


## Clears the undo stack.
func clear_undo_stack():
	undo_stack.clear()
	battle.hud().undo_button.disabled = true
	update_undo_text()


## Updates the text on the undo button.
func update_undo_text():
	var label := battle.hud().undo_button.get_node('Label')
	if undo_stack.is_empty():
		label.text = 'UNDO'
	else:
		var text: String = undo_stack.back().type_tag()
		label.text = 'UNDO\n%s' % text.capitalize().to_upper()


## Updates the message box.
func update_message_box(message := ''):
	battle.hud().show_message(message)
	remove_ghost() # we're just hacking this here


## Changes input modes.
func set_mouse_input_mode(mouse_input_mode: bool):
	var camera = battle.get_active_battle_scene().camera # hack
	camera.drag_horizontal_enabled = mouse_input_mode
	camera.drag_vertical_enabled = mouse_input_mode


## Places a unit ghost at position.
func set_ghost(unit: Unit, cell := Map.OUT_OF_BOUNDS) -> Ghost:
	_ensure_has_ghost()
	ghost.ghosted_unit = unit
	ghost.ghosted_unit.get_map_object().modulate = Color.TRANSPARENT
	ghost.map_position = cell
	return ghost


## Removes the unit ghost.
func remove_ghost():
	_ensure_has_ghost()
	if ghost.ghosted_unit:
		ghost.ghosted_unit.get_map_object().modulate = Color.WHITE
	ghost.map_position = Map.OUT_OF_BOUNDS
	ghost.modulate = Color(1.2, 1.2, 1.2, 0.6)


func _ensure_has_ghost():
	if is_instance_valid(ghost):
		return
	ghost = load('res://scenes/battle/map_objects/ghost.tscn').instantiate()
	battle.add_map_object(ghost)


## Adds unit to the play area.
func prep_add_unit(unit: Unit, cell: Vector2):
	battle.hud().prep_unit_list.remove_unit(unit)
	unit.set_position(cell)


## Removes unit from play area and returns it to the unit list.
func prep_remove_unit(unit: Unit):
	battle.hud().prep_unit_list.add_unit(unit)
	unit.set_position(Map.OUT_OF_BOUNDS)


## Returns true if cell is a valid spawn point.
func is_spawn_cell(cell: Vector2) -> bool:
	if not battle.world_bounds().has_point(cell):
		return false
	for sp in spawn_points:
		if sp.cell() == cell:
			return true
	return false


func can_reposition(unit: Unit) -> bool:
	return (unit
		and unit.is_player_owned()
		and not unit.has_meta('preplaced')
		and battle.on_turn() == empire)


func can_rotate(unit: Unit) -> bool:
	return (unit
		and unit.is_player_owned()
		and not unit.has_meta('preplaced')
		and battle.on_turn() == empire)


func can_move(unit: Unit) -> bool:
	return (unit
		and unit.is_player_owned()
		and unit.can_move()
		and battle.on_turn() == empire)


func _on_unit_input_event(_unit: Unit, event: InputEvent):
	pass


## Accepts interacted event from unit.
func _on_unit_clicked(unit: Unit, mouse_pos: Vector2, button_index: int, pressed: bool) -> void:
	#print(['none', 'pidle', 'pmove', 'bidle', 'bmove', 'btarget'][state], ' ', ['0MB', 'LMB', 'RMB', 'MMB', '4MB', '5MB'][button_index], ' ', pressed)
	pass
	# match state:
	# 	STATE_NONE:
	# 		pass

	# 	STATE_ROTATE_UNIT:
	# 		# stop rotation
	# 		if button_index == MOUSE_BUTTON_MIDDLE:
	# 			if not pressed and unit == selected_unit:
	# 				selected_unit = null
	# 				return get_viewport().set_input_as_handled()
			
	# 	STATE_PREP_STANDBY:
	# 		# remove unit
	# 		if button_index == MOUSE_BUTTON_RIGHT:
	# 			if pressed and can_reposition(unit):
	# 				interact_remove_unit(unit)
	# 				selected_unit = null
	# 				return get_viewport().set_input_as_handled()
			
	# 		if button_index == MOUSE_BUTTON_LEFT:
	# 			# move unit
	# 			if pressed and can_reposition(unit):
	# 				selected_unit = unit
	# 				battle.clear_overlays(Battle.PATHABLE_MASK) # hack
	# 				unit_drag_start = unit.get_global_position()
	# 				unit_drag_offset = mouse_pos - unit.get_global_position()
	# 				change_state(STATE_PREP_MOVING_UNIT)
	# 				return get_viewport().set_input_as_handled()
	# 			# select unit
	# 			else:
	# 				interact_select_unit(unit)
	# 				return get_viewport().set_input_as_handled()

	# 	STATE_PREP_SELECTED_UNIT:
	# 		pass

	# 	STATE_PREP_PLACING_UNIT:
	# 		if button_index == MOUSE_BUTTON_LEFT:
	# 			if not pressed and unit == selected_unit:
	# 				interact_place_unit(selected_unit, selected_unit.cell())
	# 				selected_unit = null
	# 				change_state(STATE_PREP_STANDBY)
	# 				return get_viewport().set_input_as_handled()

	# 	STATE_PREP_MOVING_UNIT:
	# 		# cancel move
	# 		if button_index == MOUSE_BUTTON_RIGHT:
	# 			if pressed and unit == selected_unit:
	# 				selected_unit.set_global_position(unit_drag_start)
	# 				selected_unit = null
	# 				change_state(STATE_PREP_STANDBY)
	# 				get_viewport().set_input_as_handled()
	# 				return
			
	# 		if button_index == MOUSE_BUTTON_LEFT:
	# 			if not pressed and unit == selected_unit:
	# 				# return unit
	# 				if battle.screen_to_cell(unit_drag_start) == selected_unit.cell():
	# 					selected_unit.set_global_position(unit_drag_start)
	# 					interact_select_unit(unit)
	# 					change_state(STATE_PREP_STANDBY)
	# 					return get_viewport().set_input_as_handled()
	# 				# place unit
	# 				else:
	# 					interact_place_unit(selected_unit, selected_unit.cell())
	# 					change_state(STATE_PREP_STANDBY)
	# 					return get_viewport().set_input_as_handled()

	# 	STATE_BATTLE_STANDBY:
	# 		if button_index == MOUSE_BUTTON_LEFT:
	# 			if pressed:
	# 				interact_select_unit(unit)
	# 				return get_viewport().set_input_as_handled()

	# 	STATE_BATTLE_SELECTING_MOVE:
	# 		if pressed:
	# 			# if the unit can move, click it. otherwise the click passes
	# 			# through the unit and clicks the cell behind it
	# 			if unit.is_player_owned() and unit.can_move() and unit != selected_unit:
	# 				interact_select_unit(unit)
	# 			else:
	# 				interact_select_cell(battle.screen_to_uniform(mouse_pos))

	# 	STATE_BATTLE_SELECTING_TARGET:
	# 		if pressed:
	# 			interact_select_cell(battle.screen_to_uniform(mouse_pos))
		
	# # manually pass through _unhandled_input
	# _unhandled_input(UnitEvents.last_input_event)
	

func is_hero_deployed() -> bool:
	for unit in Game.get_empire_units(empire):
		if unit.chara() == empire.leader:
			return true
	return false
	

func _on_prep_unit_selected(unit: Unit):
	interact_start_drag_unit(unit)


func _on_prep_unit_released(unit: Unit):
	assert(unit == selected_unit)
	interact_stop_drag_unit()


func _on_prep_unit_dragged(unit: Unit, pos: Vector2):
	assert(unit == selected_unit)
	interact_drag_unit(pos)


func _on_prep_cancelled(unit: Unit):
	assert(unit == selected_unit)
	interact_stop_drag_unit()
	prep_remove_unit(unit)


## Base class for undoable actions.
class Action:

	var agent: PlayerAgent
	var collapse := false

	func _init():
		# this is a hack but im too lazy to pass this around as a param
		agent = Battle.instance().agents[Battle.instance().player()]
	
	func execute() -> bool:
		return false

	func undo():
		pass

	func type_tag() -> String:
		return ''

	func should_collapse() -> bool:
		return false

	
## Places unit on the field.
class PlaceUnitAction extends Action:

	var unit: Unit
	var cell: Vector2
	var unit_pos: Vector2

	func _init(_unit: Unit, _cell: Vector2):
		super._init()
		unit = _unit
		cell = _cell
		unit_pos = Battle.instance().screen_to_cell(agent.unit_drag_start)
	
	func execute() -> bool:
		if unit_pos == Map.OUT_OF_BOUNDS:
			agent.prep_add_unit(unit, cell)
		else:
			unit.set_position(cell)
		return true

	func undo():
		if unit_pos == Map.OUT_OF_BOUNDS:
			agent.prep_remove_unit(unit)
		else:
			unit.set_position(unit_pos)

	func type_tag() -> String:
		return 'place'


## Replaces unit on the field with another unit from the list.
class ReplaceUnitAction extends Action:

	var unit: Unit
	var other: Unit
	var other_pos: Vector2

	func _init(_unit: Unit, _other: Unit):
		super._init()
		unit = _unit
		other = _other
		other_pos = _other.get_position()
	
	func execute() -> bool:
		agent.prep_remove_unit(other)
		agent.prep_add_unit(unit, other_pos)
		return true

	func undo():
		agent.prep_remove_unit(unit)
		agent.prep_add_unit(other, other_pos)

	func type_tag() -> String:
		return 'replace'


## Swaps unit positions.
class SwapUnitAction extends Action:
	
	var unit: Unit
	var unit_pos: Vector2
	var other: Unit
	var other_pos: Vector2

	func _init(_unit: Unit, _other: Unit):
		super._init()
		unit = _unit
		unit_pos = Battle.instance().screen_to_cell(agent.unit_drag_start)
		other = _other
		other_pos = _other.get_position()
	
	func execute() -> bool:
		unit.set_position(other_pos)
		other.set_position(unit_pos)
		return true

	func undo():
		unit.set_position(unit_pos)
		other.set_position(other_pos)

	func type_tag() -> String:
		return 'swap'


## Removes unit from the field.
class RemoveUnitAction extends Action:
	
	var unit: Unit
	var unit_pos: Vector2

	func _init(_unit: Unit):
		super._init()
		unit = _unit
		unit_pos = _unit.get_position()
	
	func execute() -> bool:
		Game.deselect_unit(unit)
		agent.prep_remove_unit(unit)
		return true

	func undo():
		agent.selected_unit = unit
		agent.prep_add_unit(unit, unit_pos)

	func type_tag() -> String:
		return 'remove'

	func should_collapse() -> bool:
		return false


## Selects a unit.
class SelectUnitAction extends Action:

	var unit: Unit
	var prev_selected_unit: Unit
	#var prev_state: int

	func _init(_unit: Unit):
		super._init()
		unit = _unit
		prev_selected_unit = Game.get_selected_unit()
		#prev_state = agent.state
	
	func execute() -> bool:
		agent.selected_unit = unit

		if not unit:
			return false

		if Battle.instance().is_battle_phase():
			if agent.can_reposition(unit):
				Battle.instance().draw_unit_path(unit, Battle.instance().get_mouse_cell())
				agent.change_state(STATE_BATTLE_SELECTING_MOVE)
				return true

		return false

	func undo():
		agent.selected_unit = prev_selected_unit
		if Battle.instance().is_battle_phase():
			agent.change_state(STATE_BATTLE_STANDBY)
		else:
			agent.change_state(STATE_PREP_STANDBY)

	func type_tag() -> String:
		return 'select_unit'

	func should_collapse() -> bool:
		return collapse


## Selects an attack.
class SelectAttackAction extends Action:

	var unit: Unit
	var attack: Attack
	var prev_selected_unit: Unit

	func _init(_unit: Unit, _attack: Attack):
		super._init()
		unit = _unit
		attack = _attack
		prev_selected_unit = Game.get_selected_unit()
	
	func execute() -> bool:
		get_attack_button().set_pressed_no_signal(true)
		Battle.instance().draw_unit_attack_range(unit, attack)
		return attack != null
		
	func undo():
		get_attack_button().set_pressed_no_signal(false)
		Battle.instance().clear_overlays(Battle.ATTACK_RANGE_MASK)

	func get_attack_button() -> Button:
		if attack == unit.special_attack():
			return Battle.instance().hud().deify_button
		else:
			if attack != unit.basic_attack():
				push_error('invalid attack')
			return Battle.instance().hud().fight_button
				
	func type_tag() -> String:
		return 'select_attack'

	func should_collapse() -> bool:
		return collapse


## Selects attack target.
class SelectTargetAction extends Action:

	var unit: Unit
	var attack: Attack
	var target: Vector2
	var rotation: float

	func _init(_unit: Unit, _attack: Attack, _target: Vector2, _rotation: float):
		super._init()
		unit = _unit
		attack = _attack
		target = _target
		rotation = _rotation
	
	func execute() -> bool:
		agent.multicast_targets.push_back(target)
		agent.multicast_rotations.push_back(rotation)
		Battle.instance().draw_unit_attack_target(unit, attack, agent.multicast_targets, agent.multicast_rotations)
		return true

	func undo():
		agent.multicast_targets.pop_back()
		agent.multicast_rotations.pop_back()
		Battle.instance().clear_overlays(Battle.TARGET_SHAPE_MASK)
	
	func type_tag() -> String:
		return 'select_target'

	func should_collapse() -> bool:
		return collapse


## Issues a unit pass command.
class UnitPassAction extends Action:

	var unit: Unit
	var state: Dictionary
	var prev_state: int

	func _init(_unit: Unit):
		super._init()
		unit = _unit
		state = _unit.save_state()
	
	func execute() -> bool:
		# _select_unit(null)
		# state = STATE_NONE
		# await battle.unit_action_pass(unit)
		# state = STATE_BATTLE_STANDBY
		return false
		
	func undo():
		# unit.load_state(state)
		# _select_unit(unit)
		# agent.state = prev_state
		pass

	func type_tag() -> String:
		return 'rest'


## Issues a unit move command.
class UnitMoveAction extends Action:
	
	var unit: Unit
	var target: Vector2
	var state: Dictionary

	func _init(_unit: Unit, _target: Vector2):
		super._init()
		unit = _unit
		target = _target
		state = unit.save_state()

	func execute() -> bool:
		if unit.is_placeable(target):
			_start_walk.call_deferred()
			return true
		else:
			Game.play_error_sound()
			agent.update_message_box('Cannot move there.')
			return false

	func _start_walk():
		assert(agent.state == STATE_BATTLE_SELECTING_MOVE)
		agent.selected_unit = null
		Battle.instance().clear_overlays(Battle.PATH_MASK)
		agent.state = STATE_NONE
		await Battle.instance().unit_action_move(unit, target)
		agent.state = STATE_BATTLE_STANDBY
		print(unit.can_move())
		if unit.can_attack():
			agent.selected_unit = unit

	func undo():
		Battle.instance().clear_overlays(Battle.PATH_MASK)
		unit.load_state(state)
		agent.selected_unit = unit

		# this is bad but im lazy, we normally only get here via selecting move
		agent.state = STATE_BATTLE_SELECTING_MOVE

	func type_tag() -> String:
		return 'move'
