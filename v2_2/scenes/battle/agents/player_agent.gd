class_name PlayerAgent extends BattleAgent


enum {
	## Marker for none/invalid state.
	STATE_NONE,

	## Prep standby.
	STATE_PREP_STANDBY,

	## Battle standby.
	STATE_BATTLE_STANDBY,

	## Unit is selected and allowed to select a move (or attack).
	STATE_BATTLE_SELECTING_MOVE,

	## Unit has locked on an attack and is selecting a target.
	STATE_BATTLE_SELECTING_TARGET,
}


@export var undo_stack_size := 99
@export var interaction_handler: InteractionHandler
@export var rotation_deadzone := 0.2

var battle: Battle
var spawn_points: Array[SpawnPoint]
var state: int = STATE_NONE
var ghost: Ghost

var selected_unit: Unit
var rotated_unit: Unit
var dragged_unit: Unit

var active_attack: Attack
var multicast_targets: Array[Vector2]
var multicast_rotations: Array[float]

var unit_drag_start: Vector2
var unit_drag_offset: Vector2

var alt_held := false
var undo_stack: Array[Action] = []

var global_handlers := [handle_select_unit, handle_move_cursor, handle_cancel, handle_esc]
var rotate_unit_handlers := [handle_start_rotate_unit, handle_stop_rotate_unit, handle_rotate_unit]
var drag_unit_handlers := [handle_start_drag_unit, handle_stop_drag_unit, handle_drag_unit]
var handlers := {
	STATE_NONE: [],
	STATE_PREP_STANDBY: rotate_unit_handlers + drag_unit_handlers + global_handlers,
	STATE_BATTLE_STANDBY: rotate_unit_handlers + global_handlers,
	STATE_BATTLE_SELECTING_MOVE: global_handlers,
	STATE_BATTLE_SELECTING_TARGET: global_handlers,
}


func _initialize():
	battle = Game.battle
	battle.hud().end_button.pressed.connect(interact_end)
	battle.hud().undo_button.pressed.connect(interact_undo)
	battle.hud().prep_unit_list.unit_selected.connect(_on_prep_unit_selected)
	battle.hud().prep_unit_list.unit_released.connect(_on_prep_unit_released)
	battle.hud().prep_unit_list.unit_dragged.connect(_on_prep_unit_dragged)
	battle.hud().prep_unit_list.cancelled.connect(_on_prep_cancelled)
	interaction_handler.set_battle_remote_unhandled_input(self)

	spawn_points = battle.get_spawn_points(SpawnPoint.Type.PLAYER)

	UnitEvents.input_event.connect(_on_unit_input_event)


func _enter_prepare_units():
	clear_undo_stack()
	change_state(STATE_PREP_STANDBY)
	
	
func _exit_prepare_units():
	undo_stack.clear()
	change_state(STATE_NONE)
	
	
func _enter_turn():
	clear_undo_stack()
	change_state(STATE_BATTLE_STANDBY)
	
	
func _exit_turn():
	change_state(STATE_NONE)


func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.keycode == KEY_ALT:
		alt_held = event.pressed
	
	if alt_held:
		get_viewport().set_input_as_handled()
		return 

	for handler in handlers[state]:
		if handler.call(event):
			get_viewport().set_input_as_handled()
			return


## Handles rotation interaction.
func handle_start_rotate_unit(event) -> bool:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed):
		var unit := interaction_handler.get_hovered_unit()
		if can_rotate(unit):
			interact_start_rotate_unit(unit)
			return true
	return false


## Handles rotation interaction.
func handle_stop_rotate_unit(event) -> bool:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed and rotated_unit):
		interact_stop_rotate_unit()
		return true
	return false


## Rotates the unit.
func handle_rotate_unit(event) -> bool:
	if event is InputEventMouseMotion and rotated_unit:
		var mpos := battle.screen_to_uniform(event.position)
		if rotated_unit.get_position().distance_squared_to(mpos) > rotation_deadzone*rotation_deadzone:
			set_mouse_input_mode(true)
			interact_rotate_unit(mpos)
			return true
	return false


## Handles drag interaction.
func handle_start_drag_unit(event) -> bool:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		# 
		var unit := interaction_handler.get_hovered_unit()
		if can_reposition(unit):
			interact_start_drag_unit(unit)
			return true
	return false


## Handles drag interaction.
func handle_stop_drag_unit(event) -> bool:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and dragged_unit):
		interact_stop_drag_unit()
		return true
	return false


## Moves the unit.
func handle_drag_unit(event) -> bool:
	if event is InputEventMouseMotion and dragged_unit:
		set_mouse_input_mode(true)
		interact_drag_unit(event.position)
		return true
	return false


## Moves the cursor.
func handle_move_cursor(event) -> bool:
	# handle mouse
	if event is InputEventMouseMotion:
		set_mouse_input_mode(true)
		var unit := interaction_handler.get_hovered_unit()
		if unit:
			interact_move_cursor(unit.cell())
		else:
			interact_move_cursor(battle.screen_to_cell(event.position))
		return false

	# handle actions
	const ACTIONS := ['right', 'down', 'left', 'up']
	for i in 4:
		if event.is_action_pressed(ACTIONS[i]):
			set_mouse_input_mode(false)
			var new_pos := battle.get_cursor_pos() + Map.DIRECTIONS[i]
			interact_move_cursor(new_pos)
			return true

	return false


## Selects unit.
func handle_select_unit(event) -> bool:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed):
		return false
	interact_select_unit(interaction_handler.get_hovered_unit())
	return interaction_handler.has_hovered_unit()


## Cancel interaction.
func handle_cancel(event) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		set_mouse_input_mode(true)
		interact_cancel()
		return true
	return false


## Select cell.
func handle_select_cell(event) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		set_mouse_input_mode(true)
		interact_select_cell(battle.get_cursor_pos())
		return true
	return false


## Quit.
func handle_esc(event) -> bool:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		interact_quit()
		return true
	return false


## Changes state to new state.
func change_state(new_state: int):
	_exit_state(state)
	state = new_state
	_enter_state(new_state)


func _enter_state(_st: int):
	if selected_unit:
		battle.draw_unit_placeable_cells(selected_unit, not selected_unit.is_player_owned())


func _exit_state(_st: int):
	if not selected_unit:
		battle.clear_overlays(Battle.PATHABLE_MASK)


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
	if dragged_unit:
		interact_stop_drag_unit()
		return

	if rotated_unit:
		interact_stop_rotate_unit()
		return

	if active_attack:
		interact_select_attack(null)
		return

	if selected_unit:
		interact_select_unit(null)
		return

	var hovered_unit := interaction_handler.get_hovered_unit()
	if hovered_unit:
		if not battle.is_battle_phase() and can_reposition(hovered_unit):
			interact_remove_unit(hovered_unit)
		else:
			pass # do nothing
	else:
		undo_action()


## Undo's action.
func interact_undo():
	update_message_box()
	if dragged_unit: interact_stop_drag_unit()
	if rotated_unit: interact_stop_rotate_unit()
	if active_attack: interact_select_attack(null)
	if selected_unit: interact_select_unit(null)
	undo_action()


## Starts unit rotate interaction.
func interact_start_rotate_unit(unit: Unit):
	update_message_box()
	rotated_unit = unit


## Stops unit rotate interaction.
func interact_stop_rotate_unit():
	update_message_box()
	rotated_unit = null


## Rotates the unit to face the target cell.
func interact_rotate_unit(target_cell: Vector2):
	update_message_box()
	rotated_unit.face_towards(target_cell)


## Starts unit drag interaction.
func interact_start_drag_unit(unit: Unit):
	update_message_box()
	var from_unit_list := unit.get_position() == Map.OUT_OF_BOUNDS

	dragged_unit = unit
	
	unit_drag_start = unit.get_global_position()

	if from_unit_list:
		unit_drag_offset = battle.screen_to_global(unit.get_map_object().grab_offset())
	else:
		unit_drag_offset = battle.screen_to_global(get_viewport().get_mouse_position() - get_viewport().canvas_transform*unit_drag_start)
		

## Stops unit drag interaction.
func interact_stop_drag_unit():
	update_message_box()

	var drop_point := dragged_unit.cell()
	var drag_start := Map.cell(battle.world().as_uniform(unit_drag_start))

	dragged_unit.set_position(drag_start)

	if drop_point != drag_start:
		interact_place_unit(dragged_unit, drop_point)
		dragged_unit = null
	else:
		var unit := dragged_unit
		dragged_unit = null
		interact_select_unit(unit)


## Moves the unit.
func interact_drag_unit(screen_pos: Vector2):
	dragged_unit.set_global_position(battle.screen_to_global(screen_pos) - unit_drag_offset)

	var target_cell := dragged_unit.cell()
	var ghost_cell := battle.world().as_uniform(unit_drag_start)

	if dragged_unit and battle.is_occupied(target_cell, dragged_unit) and is_spawn_cell(target_cell):
		var occupant := battle.get_unit_at(target_cell, dragged_unit)
		set_ghost(occupant, ghost_cell)
	else:
		remove_ghost()

	
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

	if unit:
		battle.set_cursor_pos(unit.cell())
		if state == STATE_BATTLE_SELECTING_TARGET:
			interact_select_target(unit.cell())
			return

	select_unit(unit)


## Selects the attack.
func interact_select_attack(attack: Attack):
	update_message_box()
	# 	_select_unit(unit)
	# 	multicast_targets.clear()
	# 	multicast_rotations.clear()
	# 	if attack:
	# 		battle.draw_unit_attack_range(unit, attack)
	# 		state = STATE_BATTLE_SELECTING_TARGET
	# 	active_attack = attack


	# func execute() -> bool:

	# 	get_attack_button().set_pressed_no_signal(true)
	# 	Battle.instance().draw_unit_attack_range(unit, attack)
	# 	return attack != null
		
	# func undo():
	# 	get_attack_button().set_pressed_no_signal(false)
	# 	Battle.instance().clear_overlays(Battle.ATTACK_RANGE_MASK)

	# func get_attack_button() -> Button:
	# 	if attack == unit.special_attack():
	# 		return Battle.instance().hud().deify_button
	# 	else:
	# 		if attack != unit.basic_attack():
	# 			push_error('invalid attack')
	# 		return Battle.instance().hud().fight_button

## Selects the attack target.
func interact_select_target(cell: Vector2):
	update_message_box()
	# var err := battle.check_unit_attack(selected_unit, active_attack, cell, 0)
	# if err == Battle.OK:
	# 	push_undo_action(SelectTargetAction.new(selected_unit, active_attack, cell, 0))
	# 	if active_attack.multicast <= 0 or multicast_targets.size() > active_attack.multicast:
	# 		pass # TODO
	# else:
	# 	const message := {
	# 		Battle.SPECIAL_NOT_UNLOCKED: "Ability not unlocked.",
	# 		Battle.INSIDE_MIN_RANGE: "Target inside minimum range.",
	# 		Battle.OUT_OF_RANGE: "Target outside range.",
	# 		Battle.NO_TARGET: "No target found.",
	# 		Battle.INVALID_TARGET: "Invalid target.",
	# 	}
	# 	Game.play_error_sound()
	# 	update_message_box(message.get(err, ""))


		# func execute() -> bool:
		# 	agent.multicast_targets.push_back(target)
		# 	agent.multicast_rotations.push_back(rotation)
		# 	Battle.instance().draw_unit_attack_target(unit, attack, agent.multicast_targets, agent.multicast_rotations)
		# 	return true
	
		# func undo():
		# 	agent.multicast_targets.pop_back()
		# 	agent.multicast_rotations.pop_back()
		# 	Battle.instance().clear_overlays(Battle.TARGET_SHAPE_MASK)


func select_unit(unit: Unit):
	if selected_unit == unit:
		return
	if selected_unit:
		deselect_unit()
	if unit:
		interaction_handler.select_unit(unit)
		battle.draw_unit_placeable_cells(unit, not unit.is_player_owned())
	selected_unit = unit


func deselect_unit():
	if not selected_unit:
		return
	interaction_handler.select_unit(null)
	multicast_targets.clear()
	multicast_rotations.clear()
	battle.clear_overlays(Battle.PATHABLE_MASK)
	selected_unit = null
	

##################################################################################################################
#endregion Interactions
##################################################################################################################


## Pushes the action to the undo stack.
func push_undo_action(action: Action):
	if undo_stack.size() > undo_stack_size:
		undo_stack.pop_front()

	action.execute()
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
	# we're just gonna hack these here
	remove_ghost()


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
	# this is important because just removing the unit
	# will trigger cancel if a unit is still selected.
	battle.hud().prep_unit_list.set_selected_unit(null)
	battle.hud().prep_unit_list.remove_unit(unit)
	unit.set_position(cell)


## Removes unit from play area and returns it to the unit list.
func prep_remove_unit(unit: Unit):
	battle.hud().prep_unit_list.add_unit(unit)
	unit.set_position(Map.OUT_OF_BOUNDS)
	if unit == selected_unit:
		battle.clear_overlays(Battle.PATHABLE_MASK)


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


func is_hero_deployed() -> bool:
	for unit in Game.get_empire_units(empire):
		if unit.chara() == empire.leader:
			return true
	return false


func _on_prep_unit_selected(unit: Unit):
	interact_start_drag_unit(unit)
	get_viewport().set_input_as_handled() # stop event from propagating to _unhandled_input


func _on_prep_unit_released(unit: Unit):
	assert(unit == dragged_unit)
	interact_stop_drag_unit()
	get_viewport().set_input_as_handled() # stop event from propagating to _unhandled_input


func _on_prep_unit_dragged(unit: Unit, pos: Vector2):
	assert(unit == dragged_unit)
	interact_drag_unit(pos)
	# we should also stop it here but for some reason button events
	# are also consumed so we just skip it.
	# get_viewport().set_input_as_handled() 


func _on_prep_cancelled(unit: Unit):
	assert(unit == dragged_unit)
	interact_stop_drag_unit()
	prep_remove_unit(unit)
	 
	get_viewport().set_input_as_handled() # stop event from propagating to _unhandled_input


func _on_unit_input_event(_unit: Unit, event: InputEvent):
	_unhandled_input(event)


## Base class for undoable actions.
class Action:

	var agent: PlayerAgent = Battle.instance().agents[Battle.instance().player()]
	var collapse := false

	func execute():
		pass

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
	var old_pos: Vector2

	func _init(_unit: Unit, _cell: Vector2):
		unit = _unit
		cell = _cell
		old_pos = unit.get_position()
	
	func execute():
		agent.prep_add_unit(unit, cell)

	func undo():
		if old_pos == Map.OUT_OF_BOUNDS:
			agent.prep_remove_unit(unit)
		else:
			unit.set_position(old_pos)

	func type_tag() -> String:
		return 'place'


## Replaces unit on the field with another unit from the list.
class ReplaceUnitAction extends Action:

	var unit: Unit
	var other: Unit
	var other_pos: Vector2

	func _init(_unit: Unit, _other: Unit):
		unit = _unit
		other = _other
		other_pos = _other.get_position()
	
	func execute():
		agent.prep_remove_unit(other)
		agent.prep_add_unit(unit, other_pos)

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
		unit = _unit
		unit_pos = Battle.instance().world().as_uniform(agent.unit_drag_start)
		other = _other
		other_pos = _other.get_position()
	
	func execute():
		unit.set_position(other_pos)
		other.set_position(unit_pos)

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
		unit = _unit
		unit_pos = _unit.get_position()
	
	func execute():
		agent.prep_remove_unit(unit)

	func undo():
		agent.prep_add_unit(unit, unit_pos)

	func type_tag() -> String:
		return 'remove'


## Issues a unit pass command.
class UnitPassAction extends Action:

	var unit: Unit
	var state: Dictionary
	var prev_state: int

	func _init(_unit: Unit):
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
