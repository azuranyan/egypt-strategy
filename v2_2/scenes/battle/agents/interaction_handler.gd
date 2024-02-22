class_name InteractionHandler
extends Node
## InteractionHandler derived from:
## https://forum.godotengine.org/t/is-it-possible-to-prevent-mouse-collisions-on-multiple-overlapping-area2d-signals/37301/6
## Various unit inputs are raw and unmanaged. [InteractionHandler] is the object that figures out unit selection and such.

signal selected_unit_changed(unit: Unit, selected: bool)


var _selected_units_list: Array[Unit] = []
var _aimed_target := {}


func _enter_tree():
	assert(Game._interaction_handler == null)
	Game._interaction_handler = self


func _exit_tree():
	assert(Game._interaction_handler == self)
	Game._interaction_handler = null


func _physics_process(_delta):
	# issue: unhandled_input is handled before physics input (aka model detectors)
	# https://www.reddit.com/r/godot/comments/zpy38w/advice_for_raycasting_on_input/

	# solution:
	# https://github.com/godotengine/godot-proposals/issues/1058

	# issue: viewport with object picking = true and handle_inputs_locally = false
	# will cause input to be handled even if no objects are picked/collided
	# https://github.com/godotengine/godot/issues/79897

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


func set_battle_remote_unhandled_input(node: Node):
	Battle.instance().get_active_battle_scene().get_node('%UnhandledInputListener').remote_path = node.get_path() if is_instance_valid(node) else NodePath('')


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


func _on_unit_clicked(unit: Unit, _mouse_pos: Vector2, _button_index: int, pressed: bool):
	if pressed:
		select_unit(unit)
	else:
		deselect_unit(unit)
