extends Control

@export var unit: Unit


func _gui_input(event):
	if event is InputEventMouseButton:
		if unit.selectable:
			unit.mouse_button_pressed.emit(unit, event.button_index, get_viewport().get_mouse_position(), event.pressed)
			accept_event()
	

#func _input(event):
#	if event is InputEventMouseButton:
#		if get_global_rect().has_point(event.position) and unit.selectable:
#			unit.mouse_button_pressed.emit(unit, event.button_index, event.position, event.pressed)
	
