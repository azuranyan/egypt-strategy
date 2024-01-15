extends Control

@export var unit: Unit


func _gui_input(event):
	if event is InputEventMouseButton:
		if unit.selectable:
			#var pos: Vector2 = event.position + position + unit.position
			#unit.mouse_button_pressed.emit(unit, event.button_index, pos, event.pressed)
			#event = unit.make_input_local(event)
			# WHY IS THIS SO FUCKING HARD TO GET LIKE JESUS FUCKING CHRIST
			unit.mouse_button_pressed.emit(unit, event.button_index, get_viewport().get_mouse_position(), event.pressed)
	
