extends Control

@export var unit: Unit


func _gui_input(event):
	if event is InputEventMouseButton:
		unit.mouse_button_pressed.emit(event.button_index, event.position, event.pressed)
	
