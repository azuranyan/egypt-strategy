class_name BattleAgentPlayerv2
extends BattleAgent


signal _done_prep
signal _done_turn

enum {
	STATE_NONE = 0,
	STATE_PREP,
	STATE_BATTLE,
	STATE_BATTLE_SELECT_MOVE,
	STATE_BATTLE_MOVING,
	STATE_ROTATE,
}

const STATE_NAMES := [
	"STATE_NONE",
	"STATE_PREP",
	"STATE_BATTLE",
	"STATE_BATTLE_SELECT_MOVE",
	"STATE_BATTLE_MOVING",
	"STATE_ROTATE",
]

var state: int
var state_stack := []

var selected_unit: Unit
var rotated_unit: Unit

var relocating: bool
var relocated_original_cell: Vector2

var drag_offset: Vector2

var cursor_pos: Vector2:
	set(value):
		if cursor_pos == value:
			return
		cursor_pos = value
		if state != STATE_NONE:
			battle.cursor.position = battle.map.world.as_global(cursor_pos)
			
var alt_held := false

var spawn_points := []

var undo_stack := []


## To be overriden. Called before the battle starts.
func initialize():
	push_state(STATE_NONE)
	
	
func prepare_units():
	for roster_unit in empire.units:
		var unit = battle.spawn_unit("res://Screens/Battle/map_types/unit/Unit.tscn", empire, roster_unit)
		unit.mouse_button_pressed.connect(on_unit_mouse_button_pressed)
		battle.prep_unit_list.add_unit(unit)
	
	battle.get_node("HUD/UndoPlaceButton").pressed.connect(pop_undo_action)
	battle.get_node("HUD/StartBattleButton").pressed.connect(start_battle)
	battle.get_node("HUD/StartBattleButton").visible = true
	
	battle.prep_unit_list.visible = true
	battle.prep_unit_list.unit_selected.connect(on_prep_unit_list_unit_selected)
	spawn_points.assign(battle.map.get_spawn_points('Player'))
	for spawn_point in spawn_points:
		spawn_point.no_show = false
		
	push_state(STATE_PREP)
	await _done_prep
	
	battle.get_node("HUD/UndoPlaceButton").visible = false
	battle.get_node("HUD/StartBattleButton").visible = false
	battle.prep_unit_list.visible = false
	for spawn_point in spawn_points:
		spawn_point.no_show = true
	
	pop_state()


func do_turn():
	push_state(STATE_BATTLE)
	#while not should_end:
	#	await do_action(Util.do_nothing)
	
	await _done_turn
	pop_state()
	

func _input(event):
	if event is InputEventMouseMotion and not alt_held:
		set_mouse_input_mode(true)
		cursor_pos = battle.map.cell(battle.map.world.as_uniform(battle.screen_to_global(event.position)))
		
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
				
	match state:
		STATE_PREP:
			if event is InputEventMouseMotion:
				if selected_unit:
					update_drag_unit(selected_unit, battle.screen_to_global(event.position))
					
		STATE_BATTLE:
			if event is InputEventMouseButton and event.pressed:
				interact_select_unit(battle.get_unit_at(cursor_pos))
				
		STATE_BATTLE_SELECT_MOVE:
			if event is InputEventMouseMotion:
				battle.map.unit_path.draw(selected_unit.cell(), cursor_pos)
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				interact_select_move(cursor_pos)
						
		STATE_ROTATE:
			if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
				pop_state()
			if event is InputEventMouseMotion:
				rotated_unit.face_towards(battle.map.world.as_uniform(battle.screen_to_global(event.position)))
		
	
	
func push_state(new_state: int):
	state_stack.push_back(new_state)
	state = new_state
	battle.get_node("HUD/PlayerControllerInfo/StateLabel").text = STATE_NAMES[state]
	
	
func pop_state():
	state_stack.pop_back()
	state = state_stack[-1]
	battle.get_node("HUD/PlayerControllerInfo/StateLabel").text = STATE_NAMES[state]
	
	
func is_spawn_point(cell: Vector2) -> bool:
	for spawn_point in spawn_points:
		if cell == spawn_point.map_pos:
			return true
	return false
	
		
func on_prep_unit_list_unit_selected(unit: Unit):
	if unit:
		var pos := battle.screen_to_global(get_viewport().get_mouse_position())
		interact_drag_unit(unit, pos, false)
	else:
		if selected_unit:
			interact_place_unit(selected_unit, selected_unit.position)
	selected_unit = unit
		
	
func interact_drag_unit(unit: Unit, pos: Vector2, on_board: bool):
	relocating = on_board
	if relocating:
		relocated_original_cell = unit.cell()
	else:
		relocated_original_cell = Vector2.ZERO
		unit.position = pos
	drag_offset = pos - unit.position
	update_drag_unit(unit, pos)
	

func update_drag_unit(unit: Unit, pos: Vector2):
	unit.position = pos - drag_offset
	if is_spawn_point(unit.cell()):
		unit.get_node("Highlight").play("highlight")
	else:
		unit.get_node("Highlight").play("highlight_red")
		
		
func interact_place_unit(unit: Unit, pos: Vector2):
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
		battle.prep_unit_list.remove_unit(unit)
	else:
		interact_remove_unit(unit)
		
	
func interact_remove_unit(unit: Unit):
	battle.prep_unit_list.add_unit(unit)
	battle.set_unit_standby(unit, true)
	
	
func start_battle():
	if not await battle.fulfills_prep_requirements(empire, battle.territory):
		var str := "\n".join(battle._warnings)
		battle.show_pause_box(str, "Confirm", null)
		return
		
	_done_prep.emit()
	
	
func push_undo_action(action: Variant):
	undo_stack.append(action)
	battle.get_node("HUD/UndoPlaceButton").visible = true
	if undo_stack.size() > 24:
		undo_stack.pop_front()
			
	
func pop_undo_action():
	var action = undo_stack.pop_back()
	if action is PlaceUnitAction:
		interact_remove_unit(action.unit)
		if action.swap:
			battle.set_unit_standby(action.swap, false)
			action.swap.map_pos = action.cell
			battle.prep_unit_list.remove_unit(action.swap)
	elif action is RelocateUnitAction:
		action.unit.map_pos = action.old_cell
		if action.swap:
			action.swap.map_pos = action.new_cell
	
	if undo_stack.is_empty():
		battle.get_node("HUD/UndoPlaceButton").visible = false
		
	
func set_mouse_input_mode(mouse_input_mode: bool):
	battle.camera.drag_horizontal_enabled = mouse_input_mode
	battle.camera.drag_vertical_enabled = mouse_input_mode
	
	
func interact_select_unit(unit: Unit):
	battle.set_selected_unit(unit)
	battle.map.unit_path.clear()
	battle.map.pathing_overlay.clear()
	if unit:
		if unit.is_player_owned():
			if not unit.has_moved:
				battle.draw_unit_pathable_cells(unit, false)
				battle.map.unit_path.initialize(unit.get_pathable_cells(true))
				selected_unit = unit
				push_state(STATE_BATTLE_SELECT_MOVE)
		else:
			battle.draw_unit_pathable_cells(unit, true)
	else:
		selected_unit = null
		battle.map.pathing_overlay.clear()
	

func interact_select_move(cell: Vector2):
	if cell in selected_unit.get_pathable_cells(true):
		battle.map.unit_path.clear()
		battle.map.pathing_overlay.clear()
		push_state(STATE_BATTLE_MOVING)
		await battle.unit_action_walk(selected_unit, cell)
		pop_state()
		pop_state()
		if not selected_unit.has_attacked:
			interact_select_unit(selected_unit)
		else:
			interact_select_unit(null)
	else:
		battle.play_error()
	
	
func on_unit_mouse_button_pressed(unit: Unit, button: int, position: Vector2, pressed: bool):
	print("FUCKING PRESSED")
	match state:
		STATE_PREP:
			if button == MOUSE_BUTTON_LEFT:
				if pressed:
					interact_drag_unit(unit, position, true)
					selected_unit = unit
				else:
					interact_place_unit(unit, unit.position)
					selected_unit = null
			if button == MOUSE_BUTTON_RIGHT and pressed:
				battle.prep_unit_list.add_unit(unit)
				battle.set_unit_standby(unit, true)
			if button == MOUSE_BUTTON_MIDDLE and pressed:
				rotated_unit = unit
				push_state(STATE_ROTATE)
		
		STATE_BATTLE:
			if button == MOUSE_BUTTON_LEFT and pressed:
				interact_select_unit(battle.get_unit_at(unit.cell()))
		
		STATE_ROTATE:
			if button == MOUSE_BUTTON_MIDDLE and not pressed:
				pop_state()


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
	
