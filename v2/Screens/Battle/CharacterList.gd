extends Control
class_name CharacterList

## Emitted when selected unit drag is initiated.
signal unit_drag_started(unit, pos)

## Emitted when selected unit is dragged outside of the frame.
signal unit_dragged(unit, pos)

## Emitted when a unit is selected.
signal unit_selected(unit)

## Emitted when selected unit is released.
signal unit_released(unit)


var units: Array[Unit] = []


@onready var container = $ScrollContainer/VBoxContainer
	

func add_unit(unit: Unit):
	var cb := load("res://Screens/Battle/CharacterButton.tscn").instantiate() as CharacterButton
	cb.portrait = unit.unit_type.chara.portrait
	cb.display_name = unit.unit_name
	cb.set_meta("unit", unit)
	cb.selected.connect(func(): _on_selected(cb))
	cb.released.connect(func(): _on_released(cb))
	cb.dragged.connect(func(pos: Vector2): _on_dragged(cb, pos))
	cb.drag_started.connect(func(pos: Vector2): _on_drag_started(cb, pos))
	container.add_child(cb)
	units.append(unit)
	

func remove_unit(unit: Unit):
	for cb in container.get_children():
		if cb.get_meta("unit") == unit:
			remove_child(cb)
			cb.queue_free()
	units.erase(unit)


func clear_units():
	for cb in container.get_children():
		remove_child(cb)
		cb.queue_free()
	units.clear()
	

func set_selected(unit):
	pass
	

func get_selected():
	pass
	

func _on_selected(which: CharacterButton):
	for cb in container.get_children():
		if cb.state != CharacterButton.State.IDLE and which != cb:
			cb.set_selected(false, true)
	print(which.display_name, " selected")
	unit_selected.emit(which.get_meta("unit"))
	
	
func _on_released(which: CharacterButton):
	print(which.display_name, " released")
	unit_released.emit(which.get_meta("unit"))
	
func _on_dragged(which: CharacterButton, pos: Vector2):
	print(which.display_name, " dragged ", pos)
	unit_dragged.emit(which.get_meta("unit"), pos)

func _on_drag_started(which: CharacterButton, pos: Vector2):
	for cb in container.get_children():
		if cb.state != CharacterButton.State.IDLE and which != cb:
			cb.set_selected(false, true)
	print(which.display_name, " drag started ", pos)
	unit_drag_started.emit(which.get_meta("unit"), pos)
