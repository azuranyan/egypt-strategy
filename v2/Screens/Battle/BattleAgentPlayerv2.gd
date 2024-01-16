class_name BattleAgentPlayerv2
extends BattleAgent


signal _done_prep
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
var moved_unit: Unit
var active_attack: Attack

var multicast_targets := []
var multicast_rotations := []

var relocating: bool
var relocated_original_cell: Vector2

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


func transition_to(new_state: int):
	exit_state(state)
	enter_state(new_state)
	state = new_state
	
	
func enter_state(_st: int):
	pass
	
	
func exit_state(_st: int):
	pass


func initialize():
	state = STATE_NONE

	
func prepare_units():
	state = STATE_PREP
	for roster_unit in empire.units:
		var unit = battle.spawn_unit(roster_unit, empire, roster_unit)
		unit.mouse_button_pressed.connect(_on_unit_mouse_button_pressed)
		battle.hud.prep_unit_list.add_unit(unit)
	
	battle.hud.undo_place_pressed.connect(pop_undo_action)
	battle.hud.start_battle_pressed.connect(start_battle)
	battle.hud.attack_pressed.connect(interact_select_attack)
	
	battle.show_hud(true)
	battle.hud.prep_unit_list.unit_selected.connect(_on_prep_unit_list_unit_selected)
	battle.hud.prep_unit_list.unit_dragged.connect(_on_prep_unit_list_unit_dragged)
	spawn_points.assign(battle.map.get_spawn_points('Player'))
	for spawn_point in spawn_points:
		spawn_point.no_show = false
		
	await _done_prep
	
	battle.show_hud(false)
	for spawn_point in spawn_points:
		spawn_point.no_show = true


func do_turn():
	await _done_turn

	
func _unhandled_input(event):
	if event is InputEventMouse:
		if alt_held:
			return
			
	# global functionality
	if event is InputEventMouseMotion:
		set_mouse_input_mode(true)
		cursor_pos = battle.map.cell(battle.map.world.as_uniform(battle.screen_to_global(event.position)))
		
		if rotated_unit:
			rotated_unit.face_towards(battle.map.world.as_uniform(battle.screen_to_global(event.position)))
			
	if event is InputEventKey:
		if event.keycode == KEY_ALT:
			alt_held = event.pressed
		else:
			if event.pressed:
				set_mouse_input_mode(false)
				match event.keycode:
					KEY_W:
						cursor_pos += Vector2.UP
					KEY_S:
						cursor_pos += Vector2.DOWN
					KEY_A:
						cursor_pos += Vector2.LEFT
					KEY_D:
						cursor_pos += Vector2.RIGHT
	
	# phase specific functionality			
	if event is InputEventMouseMotion:
		if active_attack:
			battle.draw_unit_attack_targets(selected_unit, active_attack, cursor_pos, 0, false)
			return
		
		if selected_unit:
			battle.map.unit_path.clear()
			if selected_unit.is_player_owned() and not selected_unit.has_moved:
				battle.map.unit_path.draw(selected_unit.cell(), cursor_pos)
			return
			
	if event is InputEventMouseButton and event.pressed:
		if active_attack:
			interact_select_attack_target(cursor_pos)
			return
			
		if selected_unit and selected_unit.is_player_owned():
			if event.button_index == MOUSE_BUTTON_LEFT:
				if selected_unit.is_player_owned() and not selected_unit.has_moved:
					interact_select_move(cursor_pos)
			return
			
		interact_select_unit(battle.get_unit_at(cursor_pos))
		return
				
	
func is_spawn_point(cell: Vector2) -> bool:
	for spawn_point in spawn_points:
		if cell == spawn_point.map_pos:
			return true
	return false
	
	
func start_battle():
	if not await battle.fulfills_prep_requirements(empire, battle.territory):
		var str := "\n".join(battle._warnings)
		battle.show_pause_box(str, "Confirm", null)
		return
		
	_done_prep.emit()
	
	
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
			battle.set_unit_standby(action.swap, false)
			action.swap.map_pos = action.cell
			battle.hud.prep_unit_list.remove_unit(action.swap)
	elif action is RelocateUnitAction:
		action.unit.map_pos = action.old_cell
		if action.swap:
			action.swap.map_pos = action.new_cell
	
	if undo_stack.is_empty():
		battle.hud.get_node("UndoPlaceButton").visible = false
		
	
## Starts a drag unit interaction.
func interact_drag_unit(unit: Unit, pos: Vector2, on_board: bool):
	battle.hide_message_box()
	relocating = on_board
	if relocating:
		relocated_original_cell = unit.cell()
	else:
		relocated_original_cell = Vector2.ZERO
		unit.position = pos
	drag_offset = pos - unit.position
	update_drag_unit(unit, pos)
	

## Updates the dragged unit.
func update_drag_unit(unit: Unit, pos: Vector2):
	battle.hide_message_box()
	unit.position = pos - drag_offset
	if is_spawn_point(unit.cell()):
		unit.get_node("Highlight").play("highlight")
	else:
		unit.get_node("Highlight").play("highlight_red")
		
		
## Places unit to the field. Only works in prep.
func interact_place_unit(unit: Unit, pos: Vector2):
	battle.hide_message_box()
	unit.get_node("Highlight").play("RESET")
	var cell := battle.map.cell(battle.map.world.as_uniform(pos))
	if is_spawn_point(cell):
		var swap: Unit = null
		for obj in battle.map.get_objects_at(cell):
			if obj is Unit and obj != unit:
				swap = obj
				if relocating:
					obj.map_pos = relocated_original_cell
				else:
					interact_remove_unit(obj)
		if relocating:
			push_undo_action(RelocateUnitAction.new(unit, swap, relocated_original_cell, cell))
		else:
			push_undo_action(PlaceUnitAction.new(unit, swap, cell))
		unit.map_pos = cell
		battle.hud.prep_unit_list.remove_unit(unit)
	else:
		interact_remove_unit(unit)
		
	
## Removes unit from the field. Only works in prep.
func interact_remove_unit(unit: Unit):
	battle.hide_message_box()
	battle.hud.prep_unit_list.add_unit(unit)
	battle.set_unit_standby(unit, true)
	
	
## Selects a unit. Deselects unit if null.
func interact_select_unit(unit: Unit):
	battle.hide_message_box()
	battle.hud.set_selected_unit(unit)
	battle.map.unit_path.clear()
	battle.map.pathing_overlay.clear()
	if unit:
		if unit.is_player_owned():
			if not unit.has_moved:
				battle.draw_unit_pathable_cells(unit, false)
				battle.map.unit_path.initialize(unit.get_pathable_cells(true))
		else:
			battle.draw_unit_pathable_cells(unit, true)
	else:
		battle.map.pathing_overlay.clear()
	selected_unit = unit
	

## Selects the location to move the selected unit towards.
func interact_select_move(cell: Vector2):
	battle.hide_message_box()
	if cell in selected_unit.get_pathable_cells(true):
		battle.map.unit_path.clear()
		battle.map.pathing_overlay.clear()
		var unit := selected_unit
		interact_select_unit(null)
		await battle.unit_action_walk(unit, cell)
		if not unit.has_attacked:
			interact_select_unit(unit)
	else:
		battle.play_error()
	
	
## Selects an attack. Deselects attack if null.
func interact_select_attack(unit: Unit, attack: Attack):
	battle.hide_message_box()
	battle.hud.set_selected_attack(attack)
	battle.map.pathing_overlay.clear()
	multicast_targets.clear()
	multicast_rotations.clear()
	if attack:
		if attack.melee:
			pass
		else:
			battle.draw_unit_attack_range(unit, attack)
	if selected_unit != unit:
		# TODO for some reason this function is reachable without selected unit.
		# that shouldn't be the case. as a workaround, we just set it as selected.
		interact_select_unit(unit)
	active_attack = attack
		
		
## Selects the attack target for the previously selected attack.
func interact_select_attack_target(cell: Vector2):
	battle.hide_message_box()
	var err := selected_unit.check_use_attack(active_attack, cell, 0)
	if err == Unit.ATTACK_OK:
		if active_attack.multicast:
			if multicast_targets.size() <= active_attack.multicast:
				multicast_targets.push_back(cell)
				multicast_rotations.push_back(0)
			else:
				var unit := selected_unit
				var attack := active_attack
				battle.map.attack_overlay.clear()
				battle.map.target_overlay.clear()
				interact_select_unit(null)
				interact_select_attack(null, null)
				await battle.unit_action_attack(unit, attack, multicast_targets, multicast_rotations)
		else:
			var unit := selected_unit
			var attack := active_attack # TODO cleanup
			battle.map.attack_overlay.clear()
			battle.map.target_overlay.clear()
			interact_select_unit(null)
			interact_select_attack(null, null)
			await battle.unit_action_attack(unit, attack, cell, 0)
	else:
		battle.play_error()
		match err:
			Unit.ATTACK_OK:
				pass
			Unit.ATTACK_NOT_UNLOCKED:
				battle.show_message_box("Ability not unlocked.")
			Unit.ATTACK_TARGET_INSIDE_MIN_RANGE:
				battle.show_message_box("Target inside minimum range.")
			Unit.ATTACK_TARGET_OUT_OF_RANGE:
				battle.show_message_box("Target outside range.")
			Unit.ATTACK_NO_TARGETS:
				battle.show_message_box("No target.")
			Unit.ATTACK_INVALID_TARGET:
				battle.show_message_box("Invalid target.")

	
func _on_unit_mouse_button_pressed(unit: Unit, button: int, position: Vector2, pressed: bool):
	if rotated_unit and not pressed:
		rotated_unit = null
		return
		
	if active_attack:
		return
		
	if not battle._battle_phase:
		match button:
			MOUSE_BUTTON_LEFT:
				if pressed:
					interact_drag_unit(unit, position, true)
					selected_unit = unit
				else:
					interact_place_unit(unit, unit.position)
					selected_unit = null
			MOUSE_BUTTON_RIGHT:
				if pressed:
					battle.hud.prep_unit_list.add_unit(unit)
					battle.set_unit_standby(unit, true)
			MOUSE_BUTTON_MIDDLE:
				if pressed:
					rotated_unit = unit
	else:
		match button:
			MOUSE_BUTTON_LEFT:
				if pressed:
					interact_select_unit(battle.get_unit_at(unit.cell()))


func _on_prep_unit_list_unit_selected(unit: Unit):
	if unit:
		var pos := battle.screen_to_global(get_viewport().get_mouse_position())
		interact_drag_unit(unit, pos, false)
	else:
		if selected_unit:
			interact_place_unit(selected_unit, selected_unit.position)
	selected_unit = unit
	
	
func _on_prep_unit_list_unit_dragged(unit: Unit, position: Vector2):
	update_drag_unit(unit, battle.screen_to_global(position))
	

class PlaceUnitAction:
	var unit: Unit
	var swap: Unit
	var cell: Vector2
	
	func _init(unit: Unit, swap: Unit, cell: Vector2):
		self.unit = unit
		self.swap = swap
		self.cell = cell
	

class RelocateUnitAction:
	var unit: Unit
	var swap: Unit
	var old_cell: Vector2
	var new_cell: Vector2
	
	func _init(unit: Unit, swap: Unit, old_cell: Vector2, new_cell: Vector2):
		self.unit = unit
		self.swap = swap
		self.old_cell = old_cell
		self.new_cell = new_cell
	
