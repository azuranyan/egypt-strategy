class_name PlayerAgent extends BattleAgent



enum {
	STATE_NONE,
	STATE_PREP,
	STATE_BATTLE_STANDBY,
	STATE_BATTLE_SELECTING_MOVE,
	STATE_BATTLE_SELECTING_TARGET,
}

@export var undo_stack_size := 30


var battle: Battle
var spawn_points: Array[SpawnPoint]
var state := STATE_NONE
var ghost: Ghost

var selected_unit: Unit:
	set(value):
		Game.deselect_unit(selected_unit)
		selected_unit = value
		Game.select_unit(value)
var rotated_unit: Unit
var active_attack: Attack
var multicast_targets: Array[Vector2]
var multicast_rotations: Array[float]

var repositioned_unit: Unit
var unit_drag_start: Vector2
var unit_drag_offset: Vector2

var alt_held := false
var undo_stack: Array[Action] = []


func _process(_delta):
	if rotated_unit:
		const ROTATION_DEADZONE := 0.2
		var mpos := battle.world().as_uniform(get_viewport().get_mouse_position())
		if rotated_unit.get_position().distance_squared_to(mpos) >= ROTATION_DEADZONE*ROTATION_DEADZONE:
			rotated_unit.face_towards(mpos)

	if repositioned_unit:
		repositioned_unit.set_global_position(get_viewport().get_mouse_position() - unit_drag_offset)
		var new_pos := repositioned_unit.cell()

		#repositioned_unit.get_map_object().highlight = UnitMapObject.Highlight.RED if repositioned_unit.is_pathable(new_pos) else UnitMapObject.Highlight.NORMAL

		if battle.is_occupied(new_pos, repositioned_unit) and is_spawn_cell(new_pos):
			var occupant := battle.get_unit_at(new_pos, repositioned_unit)
			create_ghost(occupant, occupant.get_map_object().world.as_uniform(unit_drag_start))
		else:
			remove_ghost()


func _input(event):
	# idr why this has to be on _input but oh well
	if event is InputEventMouseMotion and is_instance_valid(rotated_unit):
		const ROTATION_DEADZONE := 0.2
		var mpos := battle.world().as_uniform(get_viewport().get_mouse_position())
		if rotated_unit.get_position().distance_squared_to(mpos) >= ROTATION_DEADZONE*ROTATION_DEADZONE:
			rotated_unit.face_towards(mpos)
	

# func _unhandled_input(event):
# 	if event is InputEventMouse and alt_held:
# 		return

# 	# global functionality
# 	if event is InputEventMouseMotion:
# 		set_mouse_input_mode(true)
# 		interact_move_mouse(battle.world().as_global(event.position))
	
# 	if event is InputEventMouseButton and event.pressed:
# 		if event.button_index == MOUSE_BUTTON_LEFT:
# 			set_mouse_input_mode(true)
# 			interact_select_cell(battle.get_cursor_pos())

# 	if event is InputEventKey:
# 		if event.keycode == KEY_ALT:
# 			alt_held = event.pressed
# 		else:
# 			if event.pressed:
# 				match event.keycode:
# 					KEY_ESCAPE:
# 						interact_quit()
# 					KEY_W:
# 						set_mouse_input_mode(false)
# 						interact_move_cursor(cursor_pos + Vector2.UP)
# 					KEY_S:
# 						set_mouse_input_mode(false)
# 						interact_move_cursor(cursor_pos + Vector2.DOWN)
# 					KEY_A:
# 						set_mouse_input_mode(false)
# 						interact_move_cursor(cursor_pos + Vector2.LEFT)
# 					KEY_D:
# 						set_mouse_input_mode(false)
# 						interact_move_cursor(cursor_pos + Vector2.RIGHT)


## Called on initialize.
func _initialize():
	battle = Game.battle
	battle.hud().end_button.pressed.connect(interact_end)
	battle.hud().undo_button.pressed.connect(interact_cancel)
	battle.hud().prep_unit_list.unit_selected.connect(_on_prep_unit_selected)
	battle.hud().prep_unit_list.unit_released.connect(_on_prep_unit_released)
	battle.hud().prep_unit_list.unit_dragged.connect(_on_prep_unit_dragged)
	battle.hud().prep_unit_list.cancelled.connect(_on_prep_cancelled)

	spawn_points = battle.get_spawn_points(SpawnPoint.Type.PLAYER)


## Called on start preparation.
func _enter_prepare_units():
	clear_undo_stack()
	UnitEvents.clicked.connect(global_on_unit_clicked)
	UnitEvents.clicked.connect(prep_on_unit_clicked)
	state = STATE_PREP
	
	
## Called on end preparation.
func _exit_prepare_units():
	UnitEvents.clicked.disconnect(global_on_unit_clicked)
	UnitEvents.clicked.disconnect(prep_on_unit_clicked)
	undo_stack.clear()
	state = STATE_NONE
	
	
## Called on turn start.
func _enter_turn():
	UnitEvents.clicked.connect(global_on_unit_clicked)
	UnitEvents.clicked.connect(battle_on_unit_clicked)
	state = STATE_BATTLE_STANDBY
	
	
### Called on turn end.
func _exit_turn():
	UnitEvents.clicked.disconnect(global_on_unit_clicked)
	UnitEvents.clicked.disconnect(battle_on_unit_clicked)
	state = STATE_NONE


## Starts the battle.
func interact_start_battle():
	if not is_hero_deployed():
		Game.create_pause_dialog('%s required.' % empire.leader_name(), 'Confirm', '')
		return
	end_prepare_units()


## Ends the battle.
func interact_quit():
	battle.show_forfeit_dialog()

	
## Ends the turn (or prep phase).
func interact_end():
	if not battle.is_battle_phase():
		interact_start_battle()
	else:
		end_turn()
		

## Cancels current interaction.
func interact_cancel():
	undo_action()


## Adds unit to play.
func interact_place_unit(unit: Unit, cell: Vector2):
	update_message_box()
	var old_pos := Map.cell(battle.world().as_uniform(unit_drag_start))
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
			unit.set_position(old_pos)


## Removes unit from play.
func interact_remove_unit(unit: Unit):
	update_message_box()
	push_undo_action(RemoveUnitAction.new(unit))


## Moves the cursor to the specified position.
func interact_move_cursor(cell: Vector2):
	update_message_box()
	battle.set_cursor_pos(cell)
	match state:
		STATE_NONE:
			pass
		STATE_PREP:
			pass
		STATE_BATTLE_STANDBY:
			pass
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
	match state:
		STATE_NONE:
			pass
		STATE_PREP:
			interact_select_unit(battle.get_unit_at(cell))
		STATE_BATTLE_STANDBY:
			interact_select_unit(battle.get_unit_at(cell))
		STATE_BATTLE_SELECTING_MOVE:
			_select_move(cell)
		STATE_BATTLE_SELECTING_TARGET:
			_select_target(cell)


## Selects the unit.
func interact_select_unit(unit: Unit):
	update_message_box()
	match state:
		STATE_NONE:
			pass
		STATE_PREP:
			pass
		STATE_BATTLE_STANDBY:
			_select_unit(unit)
		STATE_BATTLE_SELECTING_MOVE:
			_select_unit(unit)
		STATE_BATTLE_SELECTING_TARGET:
			_select_target(unit.cell())


## Selects the attack.
func interact_select_attack(unit: Unit, attack: Attack):
	update_message_box()
	_select_attack(unit, attack)


func _select_unit(unit: Unit):
	battle.clear_overlays()
	
	if unit:
		battle.draw_unit_placeable_cells(unit, not unit.is_player_owned())
		if unit.is_player_owned() and unit.can_move():
			state = STATE_BATTLE_SELECTING_MOVE
	else:
		state = STATE_BATTLE_STANDBY
	
	selected_unit = unit


func _select_move(cell: Vector2):
	if selected_unit.is_placeable(cell):
		push_undo_action(UnitMoveAction.new(selected_unit, cell))
	else:
		Game.play_error_sound()
		update_message_box('Cannot move there.')
		

func _select_attack(unit: Unit, attack: Attack):
	_select_unit(unit)
	multicast_targets.clear()
	multicast_rotations.clear()
	if attack:
		battle.draw_unit_attack_range(unit, attack)
		state = STATE_BATTLE_SELECTING_TARGET
	active_attack = attack


func _select_target(cell: Vector2):
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
			

## Pushes the action to the undo stack.
func push_undo_action(action: Action):
	if undo_stack.size() > undo_stack_size:
		undo_stack.pop_front()
	battle.hud().undo_button.disabled = false
	action.execute()
	undo_stack.append(action)
	update_undo_text()


## Undo's an action.
func undo_action():
	if undo_stack.is_empty():
		return
	var action: Action = undo_stack.pop_back()
	action.undo()
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
		var text: String = undo_stack.back().ui_text()
		label.text = 'UNDO\n%s' % text.to_upper()


## Updates the message box.
func update_message_box(message := ''):
	battle.hud().show_message(message)



func set_mouse_input_mode(mouse_input_mode: bool):
	# TODO hack
	var camera = battle.get_active_battle_scene().camera
	camera.drag_horizontal_enabled = mouse_input_mode
	camera.drag_vertical_enabled = mouse_input_mode


## Creates a unit ghost at position.
func create_ghost(unit: Unit, cell := Map.OUT_OF_BOUNDS) -> Ghost:
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
	return (unit.is_player_owned()
		and not unit.has_meta('preplaced')
		and battle.on_turn() == empire)


func can_rotate(unit: Unit) -> bool:
	return (unit.is_player_owned()
		and not unit.has_meta('preplaced')
		and battle.on_turn() == empire
		and Game.get_selected_unit() == null)


func can_move(unit: Unit) -> bool:
	return (unit.is_player_owned()
		and unit.can_move())


## Accepts interacted event from unit.
func global_on_unit_clicked(unit: Unit, _mouse_pos: Vector2, button_index: int, pressed: bool):
	if button_index == MOUSE_BUTTON_MIDDLE:
		if pressed and can_rotate(unit):
			rotated_unit = unit
		elif not pressed and unit == rotated_unit: 
			rotated_unit = null

		
## Accepts interacted event from unit.
func prep_on_unit_clicked(unit: Unit, mouse_pos: Vector2, button_index: int, pressed: bool):
	if button_index == MOUSE_BUTTON_LEFT:
		if pressed and can_reposition(unit):
			Game.select_unit(unit)
			unit_drag_start = unit.get_global_position()
			unit_drag_offset = mouse_pos - unit.get_global_position() 
			repositioned_unit = unit
		elif not pressed and unit == repositioned_unit:
			interact_place_unit(unit, unit.cell())
			Game.deselect_unit(unit)
			remove_ghost()
			repositioned_unit = null

	if button_index == MOUSE_BUTTON_RIGHT and pressed and can_reposition(unit):
		interact_remove_unit(unit)
		Game.deselect_unit(unit)
		remove_ghost()


## Accepts interacted event from unit.
func battle_on_unit_clicked(unit: Unit, mouse_pos: Vector2, button_index: int, pressed: bool):
	if button_index == MOUSE_BUTTON_LEFT and pressed:
		Game.select_unit(unit)
		
	
func is_hero_deployed() -> bool:
	for unit in Game.get_empire_units(empire):
		if unit.chara() == empire.leader:
			return true
	return false
	


func _on_prep_unit_selected(unit: Unit):
	Game.select_unit(unit)
	unit_drag_start = battle.world().as_global(Map.OUT_OF_BOUNDS)
	unit_drag_offset = Vector2.ZERO # unit sprite height or drag_offset maybe?


func _on_prep_unit_released(unit: Unit):
	interact_place_unit(unit, unit.cell())
	Game.deselect_unit(unit)
	battle.hud().set_selected_unit(null)


func _on_prep_unit_dragged(unit: Unit, pos: Vector2):
	unit.set_global_position(pos + unit_drag_offset)


func _on_prep_cancelled(unit: Unit):
	battle.hud().set_selected_unit(null)
	interact_remove_unit(unit)


## Base class for undoable actions.
class Action:

	var agent: PlayerAgent

	func _init():
		# this is a hack but im too lazy to pass this around as a param
		agent = Battle.instance().agents[Battle.instance().player()]
	
	func execute():
		pass

	func undo():
		pass

	func ui_text() -> String:
		return ''

	
## Places unit on the field.
class PlaceUnitAction extends Action:

	var unit: Unit
	var cell: Vector2

	func _init(_unit: Unit, _cell: Vector2):
		super._init()
		unit = _unit
		cell = _cell
	
	func execute():
		agent.prep_add_unit(unit, cell)

	func undo():
		agent.prep_remove_unit(unit)

	func ui_text() -> String:
		return 'Place'


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
	
	func execute():
		agent.prep_remove_unit(other)
		agent.prep_add_unit(unit, other_pos)

	func undo():
		agent.prep_remove_unit(unit)
		agent.prep_add_unit(other, other_pos)

	func ui_text() -> String:
		return 'Replace'


## Swaps unit positions.
class SwapUnitAction extends Action:
	
	var unit: Unit
	var unit_pos: Vector2
	var other: Unit
	var other_pos: Vector2

	func _init(_unit: Unit, _other: Unit):
		super._init()
		unit = _unit
		unit_pos = Map.cell(Battle.instance().world().as_uniform(agent.unit_drag_start))
		other = _other
		other_pos = _other.get_position()
	
	func execute():
		unit.set_position(other_pos)
		other.set_position(unit_pos)

	func undo():
		unit.set_position(unit_pos)
		other.set_position(other_pos)

	func ui_text() -> String:
		return 'Swap'


## Removes unit from the field.
class RemoveUnitAction extends Action:
	
	var unit: Unit
	var unit_pos: Vector2

	func _init(_unit: Unit):
		super._init()
		unit = _unit
		unit_pos = _unit.get_position()
	
	func execute():
		agent.prep_remove_unit(unit)

	func undo():
		agent.prep_add_unit(unit, unit_pos)

	func ui_text() -> String:
		return 'Remove'


## Selects a unit.
class SelectUnitAction extends Action:

	var unit: Unit
	var prev_selected_unit: Unit
	var prev_state: int

	func _init(_unit: Unit):
		super._init()
		unit = _unit
		prev_selected_unit = Game.get_selected_unit()
		prev_state = agent.state
	
	func execute():
		Battle.instance().draw_unit_placeable_cells(unit, not unit.is_player_owned())
		if unit.is_player_owned() and unit.can_move():
			agent.state = STATE_BATTLE_SELECTING_MOVE
		Game.select_unit(unit)

	func undo():
		Game.deselect_unit(unit)
		Game.select_unit(prev_selected_unit)
		agent.state = prev_state
		

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
	
	func execute():
		get_attack_button().set_pressed_no_signal(true)
		Battle.instance().draw_unit_attack_range(unit, attack)
		
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
	
	func execute():
		agent.multicast_targets.push_back(target)
		agent.multicast_rotations.push_back(rotation)
		Battle.instance().draw_unit_attack_target(unit, attack, agent.multicast_targets, agent.multicast_rotations)

	func undo():
		agent.multicast_targets.pop_back()
		agent.multicast_rotations.pop_back()
		Battle.instance().clear_overlays(Battle.TARGET_SHAPE_MASK)
	

## Issues a unit pass command.
class UnitPassAction extends Action:

	var unit: Unit
	var state: Dictionary
	var prev_state: int

	func _init(_unit: Unit):
		super._init()
		unit = _unit
		state = _unit.save_state()
	
	func execute():
		# _select_unit(null)
		# state = STATE_NONE
		# await battle.unit_action_pass(unit)
		# state = STATE_BATTLE_STANDBY
		pass
		
	func undo():
		# unit.load_state(state)
		# _select_unit(unit)
		# agent.state = prev_state
		pass

	func ui_text() -> String:
		return 'Rest'
	

## Issues a unit move command.
class UnitMoveAction extends Action:
	
	var unit: Unit
	var target: Vector2
	var state: Dictionary
	var prev_state: int

	func _init(_unit: Unit, _target: Vector2):
		super._init()
		unit = _unit
		target = _target
		state = unit.save_state()
		prev_state = agent.state

	func execute():
		# _select_unit(null)
		# state = STATE_NONE
		# await battle.unit_action_move(unit, target)
		# state = STATE_BATTLE_STANDBY
	
		# if unit.can_attack():
		# 	_select_unit(unit)
		pass

	func undo():
		# unit.load_state(state)
		# _select_unit(unit)
		# agent.state = prev_state
		pass

	func ui_text() -> String:
		return 'Move'