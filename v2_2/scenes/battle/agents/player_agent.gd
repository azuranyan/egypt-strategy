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

## The interaction handler for this agent.
@export var interaction_handler: InteractionHandler

@export_group("Config")

## The maximum stack size of the undo stack.
@export var undo_stack_size := 99

## When true, pressing cancel will immediately undoes the move, otherwise unit selection is cancelled first.
@export var enable_undo_after_move := true


var battle: Battle
var state: int = STATE_NONE
var spawn_points: Array[SpawnPoint]

var selected_unit: Unit

var rotated_unit: Unit
var dragged_unit: Unit
var drag_prev_selected_unit: Unit
var unit_drag_start: Vector2
var unit_drag_offset: Vector2

# attack
var active_attack: Attack:
	set(value):
		active_attack = value
		if not is_node_ready():
			await ready
		%ActiveAttack/ValueLabel.text = active_attack.name if active_attack else '<null>'
var multicast_targets: Array[Vector2]
var mutlicast_rotations: Array[float]

var last_target_cell: Vector2
var alt_held := false
var undo_stack: Array[Action] = []
var ghost: Ghost


func _initialize():
	battle = Game.battle
	battle.hud().end_button.pressed.connect(interact_end)
	battle.hud().undo_button.pressed.connect(interact_undo)
	battle.hud().prep_unit_list.unit_selected.connect(_on_prep_unit_selected)
	battle.hud().prep_unit_list.unit_released.connect(_on_prep_unit_released)
	battle.hud().prep_unit_list.unit_dragged.connect(_on_prep_unit_dragged)
	battle.hud().prep_unit_list.cancelled.connect(_on_prep_cancelled)

	battle.hud().rest_button.pressed.connect(_on_rest_button_pressed)
	battle.hud().fight_button.pressed.connect(_on_fight_button_pressed)
	battle.hud().deify_button.pressed.connect(_on_deify_button_pressed)

	spawn_points = battle.get_spawn_points(SpawnPoint.Type.PLAYER)


func _enter_prepare_units():
	clear_undo_stack()
	change_state(STATE_PREP_STANDBY)
	
	
func _exit_prepare_units():
	interact_select_unit(null)
	clear_undo_stack()
	change_state(STATE_NONE)
	
	
func _enter_turn():
	interact_select_unit(null)
	clear_undo_stack()
	change_state(STATE_BATTLE_STANDBY)
	
	
func _exit_turn():
	interact_select_unit(null)
	change_state(STATE_NONE)


## Changes state to new state.
func change_state(new_state: int):
	_exit_state(state)
	state = new_state
	_enter_state(new_state)


func _enter_state(st: int):
	const ENABLED_INTERACTIONS := {
		# state : [global, drag, rotate]
		STATE_NONE: [false, false, false],
		STATE_PREP_STANDBY: [true, true, true],
		STATE_BATTLE_STANDBY: [true, false, true],
		STATE_BATTLE_SELECTING_MOVE: [true, false, false],
		STATE_BATTLE_SELECTING_TARGET: [true, false, false],
	}

	interaction_handler.set_global_handlers_enabled(ENABLED_INTERACTIONS[st][0])
	interaction_handler.set_drag_unit_handlers_enabled(ENABLED_INTERACTIONS[st][1])
	interaction_handler.set_rotate_unit_handlers_enabled(ENABLED_INTERACTIONS[st][2])


func _exit_state(_st: int):
	pass


##################################################################################################################
#region Interactions
##################################################################################################################


## Starts the battle.
func interact_start_battle():
	if state == STATE_NONE:
		return
	update_message_box()
	if not is_hero_deployed():
		Game.create_pause_dialog('%s required.' % empire.leader_name(), 'Confirm', '')
		return
	end_prepare_units()


## Ends the battle.
func interact_quit():
	if state == STATE_NONE:
		return
	update_message_box()
	battle.show_forfeit_dialog()

	
## Ends the turn (or prep phase).
func interact_end():
	if state == STATE_NONE:
		return
	update_message_box()
	if not battle.is_battle_phase():
		interact_start_battle()
	else:
		end_turn()
		

## Cancels current interaction.
func interact_cancel():
	if state == STATE_NONE:
		return
	update_message_box()

	match state:
		STATE_PREP_STANDBY, STATE_BATTLE_STANDBY:
			if dragged_unit:
				interact_stop_drag_unit()
				return
		
			if rotated_unit:
				interact_stop_rotate_unit()
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

		STATE_BATTLE_SELECTING_MOVE:
			if not enable_undo_after_move:
				if selected_unit:
					interact_select_unit(null)
					return

			if not undo_stack.is_empty() and undo_stack.back() is UnitMoveAction:
				interact_undo()
			else:
				interact_select_unit(null)
			return

		STATE_BATTLE_SELECTING_TARGET:
			if not multicast_targets.is_empty():
				multicast_targets.pop_back()
				mutlicast_rotations.pop_back()
				battle.draw_unit_attack_target(selected_unit, active_attack, multicast_targets, mutlicast_rotations)

			if multicast_targets.is_empty():
				interact_select_attack(null)
				interact_select_unit(selected_unit)


## Undo's action.
func interact_undo():
	if state == STATE_NONE:
		return
	update_message_box()
	if dragged_unit: interact_stop_drag_unit()
	if rotated_unit: interact_stop_rotate_unit()
	if active_attack: interact_select_attack(null)
	if selected_unit: interact_select_unit(null)
	undo_action()


## Starts unit rotate interaction.
func interact_start_rotate_unit(unit: Unit):
	if state == STATE_NONE:
		return
	update_message_box()
	rotated_unit = unit
	interact_select_unit(unit, false)
	battle.clear_overlays(Battle.PLACEABLE_CELLS)


## Stops unit rotate interaction.
func interact_stop_rotate_unit():
	if state == STATE_NONE:
		return
	update_message_box()
	rotated_unit = null
	interact_select_unit(null, false)


## Rotates the unit to face the target cell.
func interact_rotate_unit(target_cell: Vector2):
	if state == STATE_NONE:
		return
	update_message_box()
	rotated_unit.face_towards(target_cell)


## Starts unit drag interaction.
func interact_start_drag_unit(unit: Unit):
	if state == STATE_NONE:
		return
	update_message_box()
	var from_unit_list := unit.get_position() == Map.OUT_OF_BOUNDS

	dragged_unit = unit
	
	unit_drag_start = unit.get_global_position()

	if from_unit_list:
		unit_drag_offset = battle.screen_to_global(unit.get_map_object().grab_offset())
	else:
		unit_drag_offset = battle.screen_to_global(get_viewport().get_mouse_position() - get_viewport().canvas_transform*unit_drag_start)
	
	drag_prev_selected_unit = selected_unit
	if selected_unit:
		interact_select_unit(dragged_unit)
		

## Stops unit drag interaction.
func interact_stop_drag_unit():
	if state == STATE_NONE:
		return
	update_message_box()

	remove_ghost()

	var drop_point := dragged_unit.cell()
	var drag_start := Map.cell(battle.world().as_uniform(unit_drag_start))

	dragged_unit.set_position(drag_start)
	
	if (drop_point == drag_start or drag_prev_selected_unit) and (drag_start != Map.OUT_OF_BOUNDS):
		interact_select_unit.call_deferred(dragged_unit)
	
	if drop_point != drag_start:
		interact_place_unit(dragged_unit, drop_point)
		
	dragged_unit = null


## Moves the unit.
func interact_drag_unit(screen_pos: Vector2):
	if state == STATE_NONE:
		return
	dragged_unit.set_global_position(battle.screen_to_global(screen_pos) - unit_drag_offset)
	battle.set_cursor_pos(dragged_unit.cell())

	var target_cell := dragged_unit.cell()
	var ghost_cell := battle.world().as_uniform(unit_drag_start)

	if dragged_unit and battle.is_occupied(target_cell, dragged_unit) and is_spawn_cell(target_cell):
		var occupant := battle.get_unit_at(target_cell, dragged_unit)
		set_ghost(occupant, ghost_cell)
	else:
		remove_ghost()

	
## Adds unit to play.
func interact_place_unit(unit: Unit, cell: Vector2):
	if state == STATE_NONE:
		return
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
	if state == STATE_NONE:
		return
	update_message_box()
	if unit:
		push_undo_action(RemoveUnitAction.new(unit))


## Moves pointer.
func interact_move_pointer(screen_pos: Vector2):
	if state == STATE_NONE:
		return
	var unit := interaction_handler.get_hovered_unit()

	battle.level.cursor.unit_mode = unit and not rotated_unit and not dragged_unit and can_select(unit)

	if can_select(unit):
		interact_move_cursor(unit.cell())
	else:
		interact_move_cursor(battle.screen_to_cell(screen_pos))


func get_interactable_bounds() -> Rect2:
	return Rect2(-4, -4, battle.world().map_size.x + 8, battle.world().map_size.y + 8)

## Moves the cursor to the specified position.
func interact_move_cursor(cell: Vector2):
	if state == STATE_NONE:
		return
	
	if not get_interactable_bounds().has_point(cell):
		return

	battle.set_cursor_pos(cell)

	match state:
		STATE_BATTLE_SELECTING_MOVE:
			if selected_unit.can_move():
				battle.draw_unit_path(selected_unit, cell)

		STATE_BATTLE_SELECTING_TARGET:
			multicast_targets[-1] = cell
			mutlicast_rotations[-1] = 0
			last_target_cell = fix_melee_targeting(selected_unit, active_attack, multicast_targets, mutlicast_rotations, last_target_cell)
			battle.draw_unit_attack_target(selected_unit, active_attack, multicast_targets, mutlicast_rotations)


## Fixes melee targeting. This should definitely be a method for unit. Fix this later.
func fix_melee_targeting(unit: Unit, attack: Attack, target: Array[Vector2], _rotation: Array[float], last_valid_target_cell: Vector2) -> Vector2:
	if attack.melee:
		var facing_cell := target[-1]

		# this is to avoid weird spazz when hovering over self on melee
		if facing_cell == unit.cell():
			unit.face_towards(last_valid_target_cell)
		else:
			unit.face_towards(facing_cell)
		
		# reposition target to the proper cell
		target[-1] = unit.cell() + Map.DIRECTIONS[unit.get_heading()] * unit.attack_range(attack)
		battle.set_cursor_pos(target[-1])

	return target[-1]


## Selects the cell.
func interact_select_cell(cell: Vector2):
	if state == STATE_NONE:
		return
	update_message_box()
	battle.set_cursor_pos(cell)
	match state:
		STATE_PREP_STANDBY, STATE_BATTLE_STANDBY:
			interact_select_unit(battle.get_unit_at(cell))

		STATE_BATTLE_SELECTING_MOVE:
			if selected_unit.can_move():
				if battle.check_unit_move(selected_unit, cell) == 0:
					push_undo_action(UnitMoveAction.new(selected_unit, cell))
				else:
					Game.play_error_sound()
					update_message_box('Cannot move there.')
			else:
				interact_select_unit(null)

		STATE_BATTLE_SELECTING_TARGET:
			last_target_cell = fix_melee_targeting(selected_unit, active_attack, multicast_targets, mutlicast_rotations, last_target_cell)
			interact_select_target(last_target_cell)


## Selects the unit.
func interact_select_unit(unit: Unit, draw_overlays := true):
	if state == STATE_NONE:
		return
	update_message_box()

	if selected_unit:
		selected_unit.get_map_object().highlight = UnitMapObject.Highlight.NONE

	# select (or deselect) unit
	interaction_handler.select_unit(unit)
	selected_unit = unit

	clear_targeting()
	if draw_overlays:
		battle.clear_overlays()
	
	# deselect unit
	if not unit:
		if battle.is_battle_phase():
			change_state(STATE_BATTLE_STANDBY)
		else:
			change_state(STATE_PREP_STANDBY)
		return
	
	selected_unit.get_map_object().highlight = UnitMapObject.Highlight.NORMAL

	# update cursor and overlays
	battle.set_cursor_pos(unit.cell())
	if draw_overlays:
		draw_unit_overlays(unit)
	
	# if we can move, make sure to switch to states
	if battle.is_battle_phase():
		if unit.is_player_owned() and unit.can_act():
			change_state(STATE_BATTLE_SELECTING_MOVE)
		else:
			change_state(STATE_BATTLE_STANDBY)
	else:
		change_state(STATE_PREP_STANDBY)


## Clears unit targeting.
func clear_targeting():
	# reset targeting and overlays
	multicast_targets = [battle.get_cursor_pos()]
	mutlicast_rotations = [0]


## Draws unit overlays.
func draw_unit_overlays(unit: Unit, attack: Attack = null):
	if attack:
		battle.draw_unit_attack_range(unit, attack)

	# skips drawing pathable and paths on invalid state
	if unit.cell() == Map.OUT_OF_BOUNDS or state == STATE_BATTLE_SELECTING_TARGET:
		return
	
	# border edges are always drawn
	# TODO maybe put this in config
	battle.draw_unit_non_pathable_cells(unit)

	# only draw pathable cells when not in any interactions
	if unit != dragged_unit and unit != rotated_unit and unit.can_move():
		battle.draw_unit_placeable_cells(unit, not unit.is_player_owned())
	
	# state includes both attack and move so make sure to only draw if unit can move
	if state == STATE_BATTLE_SELECTING_MOVE and can_reposition(unit):
		battle.draw_unit_path(unit, unit.cell())


## Selects the attack.
func interact_select_attack(attack: Attack):
	if state == STATE_NONE:
		return
	update_message_box()

	# allow regrabbing focus
	if active_attack:
		Battle.instance().hud().set_selected_attack(null)
		
	if attack:
		Battle.instance().hud().set_selected_attack(attack)

	# prevent flickering when spammed
	if active_attack == attack:
		return
	
	# update attack
	active_attack = attack
	clear_targeting()
	state = STATE_BATTLE_SELECTING_TARGET if attack else STATE_BATTLE_SELECTING_MOVE

	# update overlays
	battle.clear_overlays()
	draw_unit_overlays(selected_unit, attack)

	if attack:
		if attack.melee:
			multicast_targets[-1] = selected_unit.cell() + Map.DIRECTIONS[selected_unit.get_heading()] * selected_unit.attack_range(attack)
			battle.set_cursor_pos(multicast_targets[-1])
		battle.draw_unit_attack_target(selected_unit, attack, multicast_targets, mutlicast_rotations)


## Selects the attack target.
func interact_select_target(cell: Vector2):
	if state == STATE_NONE:
		return
	update_message_box()
	# TODO target, rotation then -> multicast_target/rotation
	multicast_targets[-1] = cell
	var rotation := mutlicast_rotations[-1]

	# check if target is valid
	var err := battle.check_unit_attack(selected_unit, active_attack, cell, rotation)

	if err == Battle.OK:
		# add to multicast
		multicast_targets.push_back(Vector2.ZERO)
		mutlicast_rotations.push_back(0)
		battle.draw_unit_attack_target(selected_unit, active_attack, multicast_targets, mutlicast_rotations)

		# execute attack
		if multicast_targets.size() - 1 > active_attack.multicast:
			multicast_targets.pop_back()
			mutlicast_rotations.pop_back()
			use_attack(selected_unit, active_attack, multicast_targets, mutlicast_rotations)
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


@warning_ignore("redundant_await")
func use_attack(unit: Unit, attack: Attack, target: Array[Vector2], rotation: Array[float]):
	battle.clear_overlays()
	clear_undo_stack()
	interact_select_attack(null)
	interact_select_unit(null)
	state = STATE_NONE
	await battle.unit_action_attack(unit, attack, target, rotation)
	state = STATE_BATTLE_STANDBY
	


##################################################################################################################
#endregion Interactions
##################################################################################################################


## Pushes the action to the undo stack.
func push_undo_action(action: Action):
	if undo_stack.size() > undo_stack_size:
		undo_stack.pop_front()

	action.execute()
	battle.hud().undo_button.disabled = false
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


## Changes input modes.
func set_mouse_input_mode(mouse_input_mode: bool):
	var camera = battle.get_active_battle_scene().camera # hack
	camera.drag_horizontal_enabled = mouse_input_mode
	camera.drag_vertical_enabled = mouse_input_mode
	if mouse_input_mode:
		battle.set_camera_target(null)
	else: # todo haxx
		battle.set_camera_target(battle.get_active_battle_scene().level.cursor)


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
		battle.clear_overlays(Battle.PLACEABLE_CELLS)


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
		and battle.on_turn() == empire
		and unit.can_move())


func can_rotate(unit: Unit) -> bool:
	return (unit
		and unit.is_player_owned()
		and not unit.has_meta('preplaced')
		and battle.on_turn() == empire)


func can_select(unit: Unit) -> bool:
	if not (unit and unit.is_selectable()):
		return false
	if state == STATE_BATTLE_SELECTING_TARGET:
		return false
	if state == STATE_BATTLE_SELECTING_MOVE:
		return not selected_unit.can_move()
	return true
		

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
	# get_viewport().set_input_as_handled() # button events are somehow getting consumed too, so don't


func _on_prep_cancelled(unit: Unit):
	assert(unit == dragged_unit)
	interact_stop_drag_unit()
	prep_remove_unit(unit)
	get_viewport().set_input_as_handled() # stop event from propagating to _unhandled_input


func _on_rest_button_pressed():
	pass # TODO


func _on_fight_button_pressed():
	interact_select_attack(selected_unit.basic_attack())

	
func _on_deify_button_pressed():
	interact_select_attack(selected_unit.special_attack())


## Base class for undoable actions.
class Action:

	var agent: PlayerAgent = Battle.instance().agents[Battle.instance().player()]

	func execute():
		pass

	func undo():
		pass

	func type_tag() -> String:
		return ''

	
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

	@warning_ignore("redundant_await")
	func execute():
		assert(agent.state == STATE_BATTLE_SELECTING_MOVE)
		agent.selected_unit = null
		Battle.instance().clear_overlays(Battle.UNIT_PATH)
		agent.change_state(STATE_NONE)
		await Battle.instance().unit_action_move(unit, target)
		agent.change_state(STATE_BATTLE_SELECTING_MOVE)
		if unit.can_attack():
			agent.interact_select_unit(unit)

	func undo():
		unit.load_state(state)
		agent.interact_select_unit(unit)
		Battle.instance().set_camera_target(unit.get_global_position())

	func type_tag() -> String:
		return 'move'
