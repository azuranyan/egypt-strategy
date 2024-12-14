class_name InteractionHandler
extends Node
## InteractionHandler derived from:
## https://forum.godotengine.org/t/is-it-possible-to-prevent-mouse-collisions-on-multiple-overlapping-area2d-signals/37301/6
## Various unit inputs are raw and unmanaged. [InteractionHandler] is the object that figures out unit selection and such.

signal selected_unit_changed(unit: Unit, selected: bool)


enum {
	## Marker for none/invalid state.
	STATE_NONE,

	## Idle state during prep phase.
	STATE_PREP_STANDBY,

	## Idle state during battle phase.
	STATE_BATTLE_STANDBY,

	## Unit has been selected and is allowed to select a move (or attack).
	STATE_BATTLE_SELECTING_MOVE,

	## An attack has been selected and is allowed to select a target.
	STATE_BATTLE_SELECTING_TARGET,
}


## A special flag for ignoring mouse inputs.
var mouse_alt_mode: bool = false

var state: int = STATE_NONE


func _unhandled_input(event: InputEvent) -> void:
	# we are on a different branch of the tree so we need to make the input
	# relative to the world by calling make_input_local to get the correct
	# mouse and viewport calculations.
	event = Game.battle.world().make_input_local(event)
	
	match state:
		STATE_PREP_STANDBY:
			handle_input_prep_standby(event)
		STATE_BATTLE_STANDBY:
			handle_input_battle_standby(event)
		STATE_BATTLE_SELECTING_MOVE:
			handle_input_battle_selecting_move(event)
		STATE_BATTLE_SELECTING_MOVE:
			handle_input_battle_selecting_target(event)


func handle_input_prep_standby(event: InputEvent) -> void:
	return


func handle_input_battle_standby(event: InputEvent) -> void:
	return


func handle_input_battle_selecting_move(event: InputEvent) -> void:
	return


func handle_input_battle_selecting_target(event: InputEvent) -> void:
	return



	if event.is_action("mouse_alt_mode"):
		mouse_alt_mode = event.is_pressed()
	elif event.is_action_pressed("up"):
		pass
	elif event.is_action_pressed("down"):
		pass
	elif event.is_action_pressed("left"):
		pass
	elif event.is_action_pressed("right"):
		pass
	elif event.is_action_pressed("select_cell"):
		pass
	elif event.is_action_pressed("select_unit"):
		pass
	elif event.is_action_pressed("select_attack"):
		pass




enum interactions {
	start_battle,
	quit,
	end,
	cancel,
	undo,
	start_rotate_unit,
	stop_rotate_unit,
	start_drag_unit,
	stop_drag_unit,
	drag_unit,
	place_unit,
	remove_unit,
	move_pointer,
	move_cursor,
	select_cell,
	select_unit,
	select_attack,
	select_target,
}

# move_up
# move_down
# move_left
# move_right
# select_cell
# select_unit
# select_attack


@export var rotation_deadzone := 0.2

@export var interactable: Node


var _selected_units_list: Array[Unit] = []
var _aimed_target := {}

var _mouse_input_mode: bool


var _handlers := {}


func _ready():
	set_rotate_unit_handlers_enabled(true)
	set_drag_unit_handlers_enabled(true)
	set_global_handlers_enabled(true)

	UnitEvents.input_event.connect(_on_unit_input_event)

	set_battle_remote_unhandled_input_handler(self)

	BattleEvents.battle_scene_exiting.connect(func():
		set_process_unhandled_input(false)
		set_physics_process(false)
	)


func _exit_tree() -> void:
	set_battle_remote_unhandled_input_handler(null)


func asd(event):
	if _is_battle_scene_not_running_workaround():
		return

	event = Battle.instance().world().make_input_local(event)

	if event is InputEventKey and event.keycode == KEY_ALT:
		mouse_alt_mode = event.pressed
	
	if mouse_alt_mode:
		get_viewport().set_input_as_handled()
		return 

	for handler in _handlers:
		if _handlers[handler] and handler.call(event):
			get_viewport().set_input_as_handled()
			return


func _is_battle_scene_not_running_workaround() -> bool:
	return not is_instance_valid(Battle.instance().level)


func _physics_process(_delta):
	if _is_battle_scene_not_running_workaround():
		return

	# issue: unhandled_input is handled before physics input (aka model detectors)
	# https://www.reddit.com/r/godot/comments/zpy38w/advice_for_raycasting_on_input/

	# solution:
	# https://github.com/godotengine/godot-proposals/issues/1058

	# issue: viewport with object picking = true and handle_inputs_locally = false
	# will cause input to be handled even if no objects are picked/collided
	# https://github.com/godotengine/godot/issues/79897

	# more issues (unrelated) - logical panels are a fucking nightmare
	# https://github.com/godotengine/godot-proposals/issues/8200

	var space_state = Battle.instance().world().get_world_2d().direct_space_state
	
	var mouse_pos := Battle.instance().world().get_global_mouse_position()
	var params = PhysicsRayQueryParameters2D.new()
	params.from = mouse_pos
	params.to = mouse_pos + Vector2(-1, -1)
	params.collide_with_areas = true
	params.hit_from_inside = true
	params.collision_mask = 1
	
	_aimed_target = space_state.intersect_ray(params)

	var unit := _get_hovered_unit(_aimed_target)

	# an ugly hack for ghosts and other unselectables by setting target to {} if unit is null
	# because duplicate() with input_pickable is unreliable
	if unit:
		_aimed_target.unit = unit
	else:
		_aimed_target = {}


func _notification(what) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		mouse_alt_mode = false

	elif what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		mouse_alt_mode = false


func set_battle_remote_unhandled_input_handler(node: Node):
	if Battle.instance() and Battle.instance().get_active_battle_scene():
		Battle.instance().get_active_battle_scene().get_node('%UnhandledInputListener').remote_path = node.get_path() if is_instance_valid(node) else NodePath('')
	else:
		push_warning('attempt to set unhandled input handler without active battle scene')


func has_hovered_unit() -> bool:
	return _aimed_target.has('collider')


func get_hovered_unit() -> Unit:
	return _aimed_target.get('unit', null)


func _get_hovered_unit(data: Dictionary) -> Unit:
	if data.is_empty():
		return null
	var p = data.collider.get_parent()
	while p != null and not p is Map:
		if p is UnitMapObject:
			return p.unit
		p = p.get_parent()
	return null


## Returns the last selected unit.
func get_selected_unit() -> Unit:
	if _selected_units_list.is_empty():
		return null
	return _selected_units_list.back()
	

## Selects a unit.
func select_unit(unit: Unit):
	if not unit:
		deselect_unit(get_selected_unit())
		return
		
	if not unit.is_selectable() or unit in _selected_units_list:
		return

	# necessary to do filter (or duplicate if doing the normal way)
	for other in _selected_units_list.filter(func(_other): return _other != unit):
		_set_selected_unit(other, false)
			
	_set_selected_unit(unit, true)


## Deselects a unit.
func deselect_unit(unit: Unit):
	if not unit or not unit.is_selectable() or unit not in _selected_units_list:
		return

	_set_selected_unit(unit, false)
	
	if not _selected_units_list.is_empty():
		_set_selected_unit(unit, true)


func _set_selected_unit(unit: Unit, is_selected: bool):
	if is_selected:
		_selected_units_list.append(unit)
	else:
		_selected_units_list.erase(unit)
	selected_unit_changed.emit(unit, is_selected)
	UnitEvents.selected.emit(unit, is_selected)


## Sets whether global handlers should be enabled.
func set_global_handlers_enabled(enabled: bool):
	_handlers[handle_move_cursor] = enabled
	_handlers[handle_select_unit] = enabled
	_handlers[handle_select_cell] = enabled
	_handlers[handle_cancel] = enabled
	_handlers[handle_esc] = enabled


## Sets whether rotate handlers should be enabled.
func set_rotate_unit_handlers_enabled(enabled: bool):
	_handlers[handle_start_rotate_unit] = enabled
	_handlers[handle_stop_rotate_unit] = enabled
	_handlers[handle_rotate_unit] = enabled


## Sets whether drag handlers should be enabled.
func set_drag_unit_handlers_enabled(enabled: bool):
	_handlers[handle_start_drag_unit] = enabled
	_handlers[handle_stop_drag_unit] = enabled
	_handlers[handle_drag_unit] = enabled
	

func set_mouse_input_mode(mouse_input_mode: bool):
	if _mouse_input_mode == mouse_input_mode:
		return
	_mouse_input_mode = mouse_input_mode
	interactable.set_mouse_input_mode(mouse_input_mode)


## Handles rotation interaction.
func handle_start_rotate_unit(event) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed and not interactable.rotated_unit:
		if has_hovered_unit() and interactable.can_rotate(get_hovered_unit()):
			interactable.interact_start_rotate_unit(get_hovered_unit())
			return true

	return false


## Handles rotation interaction.
func handle_stop_rotate_unit(event) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed and interactable.rotated_unit:
		interactable.interact_stop_rotate_unit()
		return true

	return false


## Rotates the unit.
func handle_rotate_unit(event) -> bool:
	if event is InputEventMouseMotion and interactable.rotated_unit:
		var mpos := Battle.instance().screen_to_uniform(event.position)
		if interactable.rotated_unit.get_position().distance_squared_to(mpos) > rotation_deadzone*rotation_deadzone:
			set_mouse_input_mode(true)
			interactable.interact_rotate_unit(mpos)
			return true

	return false


## Handles drag interaction.
func handle_start_drag_unit(event) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not interactable.dragged_unit:
		if has_hovered_unit() and interactable.can_reposition(get_hovered_unit()):
			interactable.interact_start_drag_unit(get_hovered_unit())
			return true

	return false


## Handles drag interaction.
func handle_stop_drag_unit(event) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and interactable.dragged_unit:
		interactable.interact_stop_drag_unit()
		return true

	return false


## Moves the unit.
func handle_drag_unit(event) -> bool:
	if event is InputEventMouseMotion and interactable.dragged_unit:
		set_mouse_input_mode(true)
		interactable.interact_drag_unit(event.position)
		return true

	return false


## Moves the cursor.
func handle_move_cursor(event) -> bool:
	# handle mouse
	if event is InputEventMouseMotion:
		set_mouse_input_mode(true)
		interactable.interact_move_pointer(event.position)
		return false

	# handle non-mouse input
	const ACTIONS := ['right', 'down', 'left', 'up']
	for i in 4:
		if event.is_action_pressed(ACTIONS[i]):
			set_mouse_input_mode(false)
			var new_pos := Battle.instance().get_cursor_pos() + Map.DIRECTIONS[i]
			interactable.interact_move_cursor(new_pos)
			return true

	return false


## Selects unit.
func handle_select_unit(event) -> bool:
	# for now only mouse can directly select unit
	# this should be changed via focus group or better controller support (e.g. unit list for deployed units)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and interactable.can_select(get_hovered_unit()):
		set_mouse_input_mode(true)
		interactable.interact_select_unit(get_hovered_unit())
		return true

	return false


## Select cell.
func handle_select_cell(event) -> bool:
	# handle mouse input
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		set_mouse_input_mode(true)
		interactable.interact_select_cell(Battle.instance().screen_to_cell(event.position))
		return true
	
	# handle non-mouse input
	if event.is_action_pressed('accept'):
		set_mouse_input_mode(false)
		interactable.interact_select_cell(Battle.instance().get_cursor_pos())
		return true

	return false


## Cancel interaction.
func handle_cancel(event) -> bool:
	# handle mouse input
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		set_mouse_input_mode(true)
		interactable.interact_cancel()
		return true

	# handle non-mouse input
	if event.is_action_pressed('cancel'):
		set_mouse_input_mode(false)
		interactable.interact_cancel()
		return true

	return false


## Quit.
func handle_esc(event) -> bool:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		interactable.interact_quit()
		return true

	return false
		

func _on_unit_clicked(unit: Unit, _mouse_pos: Vector2, _button_index: int, pressed: bool):
	if pressed:
		select_unit(unit)
	else:
		deselect_unit(unit)


func _on_unit_input_event(_unit: Unit, event: InputEvent):
	_unhandled_input(event)
	
