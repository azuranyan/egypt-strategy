class_name PrepUnitList
extends Control


signal unit_selected(unit: Unit)
signal unit_dragged(unit: Unit, position: Vector2)


var buttons := {}

var active_button: PrepUnitButton


## Adds a unit to the list.
func add_unit(unit: Unit):
	if unit in buttons:
		return
	var button := preload("res://Screens/Battle/PrepUnitButton.tscn").instantiate() as PrepUnitButton
	button.prep_unit_list = self
	button.unit = unit
	$ScrollContainer/VBoxContainer.add_child(button)
	buttons[unit] = button
	$ScrollContainer/VBoxContainer.sort_children
	
	
## Remove a unit from the list.
func remove_unit(unit: Unit):
	if unit not in buttons:
		return
	$ScrollContainer/VBoxContainer.remove_child(buttons[unit])
	buttons.erase(unit)


## Returns the selected unit.
func get_selected_unit() -> Unit:
	return active_button.unit if active_button else null


## Called by the button when it's selected.
func button_selected(button: PrepUnitButton, selected: bool):
	if selected:
		active_button = button
		for btn in buttons.values():
			if button != btn:
				btn.selected = false
	else:
		if active_button == button:
			active_button = null
	unit_selected.emit(get_selected_unit())
			
			


