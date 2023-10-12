extends Control

## Interactive character (Unit) list.
class_name CharacterList

## Emitted when a unit is selected.
signal unit_selected(unit, pos)

## Emitted when selected unit is released.
signal unit_released(unit, pos)

## Emitted when selected unit is dragged outside of the frame.
signal unit_dragged(unit, pos)

## Emitted when interaction is cancelled.
signal unit_cancelled(unit)

## Emitted when interaction is cancelled.
signal unit_highlight_changed(unit, value)


var units: Array[String] = []
#var selected: Unit


@onready var container = $ScrollContainer/VBoxContainer
	

## Set the list of the units.
func set_units(arr: PackedStringArray):
	clear_units()
	for a in arr:
		add_unit(a)
	
	
## Adds a unit to the character list.
func add_unit(unit: String):
	if has_unit(unit):
		return
		
	var cb := load("res://Screens/Battle/CharacterButton.tscn").instantiate() as CharacterButton
	cb.portrait = Globals.unit_type[unit].chara.portrait
	cb.display_name = Globals.unit_type[unit].name
	cb.set_meta("unit", unit)
	
	cb.selected.connect(func(pos: Vector2): _on_selected(cb, pos))
	cb.released.connect(func(pos: Vector2): _on_released(cb, pos))
	cb.dragged.connect(func(pos: Vector2): _on_dragged(cb, pos))
	cb.cancelled.connect(func(): _on_cancelled(cb))
	cb.highlight_changed.connect(func(): _on_highlight_changed(cb))
	
	container.add_child(cb)
	units.append(unit)
	

## Removes a unit from the character list.
func remove_unit(unit: String):
	var cb = get_button(unit)
	if cb != null:
		container.remove_child(cb)
		cb.queue_free()
		units.erase(unit)


## Removes all the units in the character list.
func clear_units():
	for cb in container.get_children():
		remove_child(cb)
		cb.queue_free()
	units.clear()
	

## Returns true if the unit is in the list.
func has_unit(unit: String) -> bool:
	return get_button(unit) != null


## Returns the button associated with the unit.
func get_button(unit: String) -> CharacterButton:
	for cb in container.get_children():
		if cb.get_meta("unit") == unit:
			return cb
	return null


## Helper function to unselect everything that isn't the button.
func _unselect_others(which: CharacterButton):
	for cb in container.get_children():
		if cb.state != CharacterButton.State.IDLE and which != cb:
			cb.release()


func _on_selected(which: CharacterButton, pos: Vector2):
	_unselect_others(which)
#	selected = which.get_meta("unit")
#	unit_selected.emit(selected, pos)
	unit_selected.emit(which.get_meta("unit"), pos)
	
	
func _on_released(which: CharacterButton, pos: Vector2):
	unit_released.emit(which.get_meta("unit"), pos)
	
	
func _on_dragged(which: CharacterButton, pos: Vector2):
	unit_dragged.emit(which.get_meta("unit"), pos)


func _on_cancelled(which: CharacterButton):
	unit_cancelled.emit(which.get_meta("unit"))


func _on_highlight_changed(which: CharacterButton):
	unit_highlight_changed.emit(which.get_meta("unit"), which.highlight)
	
	
