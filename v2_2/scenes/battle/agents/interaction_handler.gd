extends Node
class_name InteractionHandler
## InteractionHandler derived from:
## https://forum.godotengine.org/t/is-it-possible-to-prevent-mouse-collisions-on-multiple-overlapping-area2d-signals/37301/6
## Various unit inputs are raw and unmanaged. [InteractionHandler] is the object that figures out unit selection and such.

signal selected_unit_changed(unit: Unit, selected: bool)


var _selected_units_list: Array[Unit] = []


func _enter_tree():
	assert(Game._interaction_handler == null)
	Game._interaction_handler = self


func _exit_tree():
	assert(Game._interaction_handler == self)
	Game._interaction_handler = null


## Returns the last selected unit.
func get_selected_unit() -> Unit:
	if _selected_units_list.is_empty():
		return null
	return _selected_units_list.back()
	

## Selects a unit.
func select_unit(unit: Unit):
	if not unit.is_selectable() or unit in _selected_units_list:
		return

	# necessary to do filter (or duplicate if doing the normal way)
	for other in _selected_units_list.filter(func(_other): return _other != unit):
		_set_selected_unit(other, false)
			
	_set_selected_unit(unit, true)


## Deselects a unit.
func deselect_unit(unit: Unit):
	if not unit.is_selectable() or unit not in _selected_units_list:
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

