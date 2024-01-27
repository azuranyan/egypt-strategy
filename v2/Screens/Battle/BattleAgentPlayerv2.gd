class_name BattleAgentPlayerv2
extends BattleAgent

# interact_* functions are called directly when corresponding input/action
# is generated. it is context sensitive and will do different things
# depending on the state of the game.
#
# TODO they should only work with the state they are subscibed to even though
# they only work and only called in that state. push warnings
#
# underlined functions are internal functions called by the interact functions
# to actually do the things they will be doing. both the interact and internal
# functions change the internal state of the game.
# 
# internal functions only call other internal functions and not iteract
#
# internal functions do not push or pop into the action queue. undo/redo is
# considered a part of the interact functionality and will not be called internally
#
# TODO ideally internal functions return status and message if it fails, because
# currently it calls outside directly to output errors. it shouldnt be their
# responsibility esp the error handling is also an interact

signal _done_turn


enum {
	STATE_NONE,
	STATE_PREP,
	STATE_BATTLE_STANDBY,
	STATE_BATTLE_SELECTING_MOVE,
	STATE_BATTLE_SELECTING_TARGET,
}

var state := STATE_NONE

var selected_unit: Unit
var rotated_unit: Unit
var active_attack: Attack

var multicast_targets: Array[Vector2] = []
var multicast_rotations: Array[float] = []

# dragging
var dragged_unit: Unit
var relocating: bool
var relocating_original_cell: Vector2
var drag_offset: Vector2

var cursor_pos: Vector2:
	set(value):
		if cursor_pos == value:
			return
		cursor_pos = value
		if battle:
			battle.cursor.position = battle.map.world.as_global(cursor_pos)
			
var alt_held := false

var spawn_points := []

var undo_stack := []


func _initialize():
	state = STATE_NONE
	battle.unit_added.connect(_on_battle_unit_added)
	battle.unit_removed.connect(_on_battle_unit_removed)

	battle.hud.undo_place_pressed.connect(interact_cancel)
	battle.hud.start_battle_pressed.connect(interact_start_battle)
	battle.hud.end_turn_pressed.connect(interact_end_turn)
	battle.hud.attack_pressed.connect(interact_select_attack)
	battle.hud.pass_pressed.connect(interact_pass)
	battle.hud.undo_move_pressed.connect(interact_cancel)
	
	battle.hud.prep_unit_list.visible = false

	
func _enter_prepare_units():
	state = STATE_PREP
	for roster_unit in empire.units:
		var unit = battle.spawn_unit(roster_unit, empire, roster_unit)
		battle.hud.prep_unit_list.add_unit(unit)
	battle.hud.prep_unit_list.visible = true
		
	battle.show_hud(true)
	battle.hud.prep_unit_list.unit_selected.connect(_on_prep_unit_list_unit_selected)
	battle.hud.prep_unit_list.unit_dragged.connect(_on_prep_unit_list_unit_dragged)
	
	spawn_points.assign(battle.map.get_spawn_points('Player'))
	for spawn_point in spawn_points:
		spawn_point.no_show = false


func _exit_prepare_units():
	state = STATE_NONE
	undo_stack.clear()
	
	battle.show_hud(false)
	for spawn_point in spawn_points:
		spawn_point.no_show = true
	

func _enter_turn():
	state = STATE_BATTLE_STANDBY
	
	
func _exit_turn():
	state = STATE_NONE
	undo_stack.clear()


func _get_errors() -> PackedStringArray:
	return []
	

func _input(event):
	# initiating rotate with mmb on the unit wont work if this isnt here
	# because control blocks the input and stops it from propagating
	if event is InputEventMouseMotion:
		if rotated_unit:
			rotated_unit.face_towards(battle.map.world.as_uniform(battle.screen_to_global(event.position)))
	
	
func _unhandled_input(event):
	if event is InputEventMouse:
		if alt_held:
			return
			
	# global functionality
	if event is InputEventMouseMotion:
		set_mouse_input_mode(true)
		interact_move_pointer(battle.screen_to_global(event.position))
			
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			interact_select_cell(cursor_pos)
		else:
			interact_cancel()
		
	if event is InputEventKey:
		if event.keycode == KEY_ALT:
			alt_held = event.pressed
		else:
			if event.pressed:
				match event.keycode:
					KEY_ESCAPE:
						interact_quit()
					KEY_W:
						set_mouse_input_mode(false)
						interact_move_cursor(cursor_pos + Vector2.UP)
					KEY_S:
						set_mouse_input_mode(false)
						interact_move_cursor(cursor_pos + Vector2.DOWN)
					KEY_A:
						set_mouse_input_mode(false)
						interact_move_cursor(cursor_pos + Vector2.LEFT)
					KEY_D:
						set_mouse_input_mode(false)
						interact_move_cursor(cursor_pos + Vector2.RIGHT)
	
	
func is_spawn_point(cell: Vector2) -> bool:
	for spawn_point in spawn_points:
		if cell == spawn_point.map_pos:
			return true
	return false
	
	
func set_mouse_input_mode(mouse_input_mode: bool):
	battle.camera.drag_horizontal_enabled = mouse_input_mode
	battle.camera.drag_vertical_enabled = mouse_input_mode
	
	
func push_undo_action(action: Variant):
	undo_stack.append(action)
	battle.hud.get_node("UndoPlaceButton").visible = true
	if undo_stack.size() > 24:
		undo_stack.pop_front()
			
	
func pop_undo_action():
	var action = undo_stack.pop_back()
	if action is PlaceUnitAction:
		interact_remove_unit(action.unit)
		if action.swap:
			action.swap.set_standby(false)
			action.swap.map_pos = action.cell
			battle.hud.prep_unit_list.remove_unit(action.swap)
	elif action is RelocateUnitAction:
		action.unit.map_pos = action.old_cell
		if action.swap:
			action.swap.map_pos = action.new_cell
	
	if undo_stack.is_empty():
		battle.hud.get_node("UndoPlaceButton").visible = false
		
		
func update_message_box(message := ""):
	if message != "":
		battle.show_message_box(message)
	else:
		battle.hide_message_box()


## Starts a drag unit interaction.
## Dragging is a fairly enclosed system and doesn't 
func initiate_dragging(unit: Unit, pos: Vector2, is_relocating: bool):
	update_message_box()
	relocating = is_relocating
	if relocating:
		relocating_original_cell = unit.cell()
	else:
		relocating_original_cell = Vector2.ZERO
		unit.position = pos
	drag_offset = pos - unit.position
	update_dragging(unit, pos)
	dragged_unit = unit
	

## Updates the dragged unit.
func update_dragging(unit: Unit, pos: Vector2):
	update_message_box()
	unit.position = pos - drag_offset
	if is_spawn_point(unit.cell()):
		unit.get_node("Highlight").play("highlight")
	else:
		unit.get_node("Highlight").play("highlight_red")
		
		
## Starts a drag unit interaction.
func release_dragging(unit: Unit, pos: Vector2):
	update_message_box()
	unit.get_node("Highlight").play("RESET")
	interact_place_unit(unit, pos)
	dragged_unit = null
	
	
func interact_start_battle():
	if battle.fulfills_prep_requirements(empire, battle.territory):
		end_prepare_units()
	else:
		var warnings := "\n".join(battle._warnings)
		battle.show_pause_box(warnings, "Confirm", null)
		return
		
		
func interact_quit():
	await battle.quit_battle(empire, "Forfeit?")
					
					
func interact_end_turn():
	end_turn()
			
			
func interact_pass():
	undo_stack.append(SavedUnitState.new(selected_unit))
	selected_unit.turn_flags |= Unit.TURN_DONE


func interact_cancel():
	if _agent_state == State.PREPARE_UNITS:
		pop_undo_action() # TODO unify interact_cancel and pop to one function
		return
		
	if active_attack:
		var unit := selected_unit
		_select_attack(null, null)
		_select_unit(unit)
	elif selected_unit:
		_select_unit(null)
	else:
		if not undo_stack.is_empty():
			var action = undo_stack.pop_back()
			
			action.unit.map_pos = action.cell
			action.unit.facing = action.facing
			action.unit.turn_flags = action.turn_flags
			_select_unit(action.unit)
		
		
## Places unit to the field.
func interact_place_unit(unit: Unit, pos: Vector2):
	update_message_box()
	var cell := battle.map.cell(battle.map.world.as_uniform(pos))
	if is_spawn_point(cell):
		unit.map_pos = Map.OUT_OF_BOUNDS
		
		var swap: Unit = battle.get_unit_at(cell)
		unit.map_pos = cell
		battle.hud.prep_unit_list.remove_unit(unit)
		
		if relocating:
			if swap:
				swap.map_pos = relocating_original_cell
			push_undo_action(RelocateUnitAction.new(unit, swap, relocating_original_cell, cell))
		else:
			if swap:
				interact_remove_unit(swap)
			push_undo_action(PlaceUnitAction.new(unit, swap, cell))
	else:
		interact_remove_unit(unit)
		
	
## Removes unit from the field.
func interact_remove_unit(unit: Unit):
	update_message_box()
	unit.set_standby(true)
	battle.hud.prep_unit_list.add_unit(unit)
	

## Moves the mouse cursor.
func interact_move_pointer(pos: Vector2):
	if dragged_unit:
		update_dragging(dragged_unit, pos)
	interact_move_cursor(battle.map.cell(battle.map.world.as_uniform(pos)))
	
	
## Moves the in-game cursor.
func interact_move_cursor(cell: Vector2):
	cursor_pos = cell
	match state:
		STATE_NONE:
			pass
		STATE_PREP:
			pass
		STATE_BATTLE_STANDBY:
			pass
		STATE_BATTLE_SELECTING_MOVE:
			battle.map.unit_path.draw(selected_unit.cell(), cell)
		STATE_BATTLE_SELECTING_TARGET:
			if active_attack.melee:
				selected_unit.face_towards(cursor_pos)
				cell = selected_unit.cell() - Unit.DIRECTIONS[selected_unit.get_heading()] * active_attack.range
				cursor_pos = cell
			
			battle.map.target_overlay.clear()
			battle.draw_unit_attack_target(selected_unit, active_attack, multicast_targets, multicast_rotations)
			battle.draw_unit_attack_target(selected_unit, active_attack, [cell], [0]) # TODO rotation
			
			
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
			_try_use_attack(cell)
	
	
## Selects a unit.
func interact_select_unit(unit: Unit):
	update_message_box()
	match state:
		STATE_NONE:
			pass
		STATE_PREP:
			pass # TODO allow showing move range on prep
		STATE_BATTLE_STANDBY:
			_select_unit(unit)
		STATE_BATTLE_SELECTING_MOVE:
			_select_unit(unit)
		STATE_BATTLE_SELECTING_TARGET:
			assert(unit != null, "interact_select_unit with target unit, but target unit is null")
			_try_use_attack(unit.cell())
		
		
## Selects an attack.
func interact_select_attack(unit: Unit, attack: Attack):
	update_message_box()
	_select_attack(unit, attack)
	
	
## (De)selects the unit.
func _select_unit(unit: Unit):
	battle.map.unit_path.clear()
	battle.map.pathing_overlay.clear()
	battle.hud.set_selected_unit(unit)
	
	if unit and unit.is_player_owned() and unit.can_move():
		battle.draw_unit_pathable_cells(unit, false)
		battle.map.unit_path.initialize(unit.get_pathable_cells(true))
		state = STATE_BATTLE_SELECTING_MOVE
	else:
		if unit and not unit.is_player_owned():
			battle.draw_unit_pathable_cells(unit, true)
		state = STATE_BATTLE_STANDBY
	selected_unit = unit
	

## Attempt to issue a move command.
func _select_move(cell: Vector2):
	if selected_unit.is_placeable(cell):
		update_message_box()
		var unit := selected_unit
		undo_stack.append(SavedUnitState.new(selected_unit))
		_select_unit(null)
		state = STATE_NONE
		await battle.unit_action_walk(unit, cell)
		state = STATE_BATTLE_STANDBY
		
		if unit.can_attack():
			_select_unit(unit)
	else:
		battle.play_error()
		update_message_box("Cannot move there.")
	
	
## Selects the attack to use.
func _select_attack(unit: Unit, attack: Attack):
	_select_unit(unit)
	multicast_targets.clear()
	multicast_rotations.clear()
	battle.hud.set_selected_attack(attack)
	battle.map.pathing_overlay.clear()
	battle.map.attack_overlay.clear()
	battle.map.target_overlay.clear()
	if attack:
		if attack.melee:
			pass
		else:
			battle.draw_unit_attack_range(unit, attack)
		state = STATE_BATTLE_SELECTING_TARGET
	active_attack = attack
		
		
## Attempt to use the attack.
func _try_use_attack(cell: Vector2):
	var err := selected_unit.check_use_attack(active_attack, cell, 0)
	if err == Unit.ATTACK_OK:
		multicast_targets.push_back(cell)
		multicast_rotations.push_back(0) # TODO rotation
		
		if active_attack.multicast <= 0 or multicast_targets.size() > active_attack.multicast:
			await _use_attack(selected_unit, active_attack, multicast_targets, multicast_rotations)
	else:
		const message := {
				Unit.ATTACK_NOT_UNLOCKED: "Ability not unlocked.",
				Unit.ATTACK_TARGET_INSIDE_MIN_RANGE: "Target inside minimum range.",
				Unit.ATTACK_TARGET_OUT_OF_RANGE: "Target outside range.",
				Unit.ATTACK_NO_TARGETS: "No target found.",
				Unit.ATTACK_INVALID_TARGET: "Invalid target.",
			}
		update_message_box(message.get(err, ""))
		battle.play_error()


## Actually uses the attack.
func _use_attack(unit: Unit, attack: Attack, target: Array[Vector2], target_rotation: Array[float]):
	battle.map.attack_overlay.clear()
	battle.map.target_overlay.clear()
	target = target.duplicate()
	target_rotation = target_rotation.duplicate()
	undo_stack.clear()
	_select_attack(null, null)
	state = STATE_NONE
	await battle.unit_action_attack(unit, attack, target, target_rotation)
	state = STATE_BATTLE_STANDBY


func _on_battle_unit_added(unit: Unit):
	battle.hud.prep_unit_list.remove_unit(unit)
	unit.mouse_button_pressed.connect(_on_unit_mouse_button_pressed)
	
	
func _on_battle_unit_removed(unit: Unit):
	battle.hud.prep_unit_list.add_unit(unit)
	unit.mouse_button_pressed.disconnect(_on_unit_mouse_button_pressed)
	
	
func _on_unit_mouse_button_pressed(unit: Unit, button: int, position: Vector2, pressed: bool):
	# unit inputs still go through even if _unhandled_input is offline because
	# these are separate entities and is not affected by input toggle.
	if state == STATE_NONE:
		pass
	elif button == MOUSE_BUTTON_MIDDLE and unit.is_player_owned():
		rotated_unit = unit if pressed else null
	elif button == MOUSE_BUTTON_RIGHT and pressed:
		interact_cancel()
	elif button == MOUSE_BUTTON_LEFT:
		match state:
			STATE_PREP:
				if unit.is_player_owned() and not unit.get_meta("Battle_unit_pre_placed", false):
					if pressed:
						initiate_dragging(unit, position, true)
					else:
						release_dragging(unit, unit.position)
			STATE_BATTLE_STANDBY:
				if pressed:
					interact_select_unit(unit)
			STATE_BATTLE_SELECTING_MOVE:
				if pressed:
					# qol: only click unit when it can move, otherwise ignore
					if unit.is_player_owned() and unit.can_move() and unit != selected_unit:
						interact_select_unit(unit)
					else:
						interact_select_cell(cursor_pos)
			STATE_BATTLE_SELECTING_TARGET:
				if pressed:
					interact_select_cell(cursor_pos)


func _on_prep_unit_list_unit_selected(unit: Unit):
	if unit:
		var pos := battle.screen_to_global(get_viewport().get_mouse_position())
		initiate_dragging(unit, pos, false)
	else:
		if selected_unit:
			release_dragging(selected_unit, selected_unit.position)
	selected_unit = unit
	
	
func _on_prep_unit_list_unit_dragged(unit: Unit, position: Vector2):
	update_dragging(unit, battle.screen_to_global(position))
	

class PlaceUnitAction:
	var unit: Unit
	var swap: Unit
	var cell: Vector2
	
	func _init(_unit: Unit, _swap: Unit, _cell: Vector2):
		unit = _unit
		swap = _swap
		cell = _cell
	

class RelocateUnitAction:
	var unit: Unit # TODO cleanup this ugly shit
	var swap: Unit
	var old_cell: Vector2
	var new_cell: Vector2
	
	func _init(_unit: Unit, _swap: Unit, _old_cell: Vector2, _new_cell: Vector2):
		unit = _unit
		swap = _swap
		old_cell = _old_cell
		new_cell = _new_cell
	

class SavedUnitState:
	var unit: Unit
	var facing: float
	var cell: Vector2
	var turn_flags: int
	
	func _init(save: Unit):
		unit = save
		facing = save.facing
		cell = save.cell()
		turn_flags = save.turn_flags
