extends ColorRect
class_name PauseOverlay


signal _result_ready(result: bool)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == 2:
			$HBoxContainer/NoButton.set_pressed(true)
			
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			$HBoxContainer/YesButton.set_pressed(true)


func show_pause(message: String, pause_text := 'Paused', yes_text := 'Yes', no_text := 'No') -> bool:
	get_tree().paused = true
	$Label.text = pause_text
	$Label2.text = message
	$HBoxContainer/YesButton.text = yes_text
	$HBoxContainer/NoButton.text = no_text
	self.visible = true
	var result: bool = await _result_ready
	self.visible = false
	return result


func _on_yes_button_pressed():
	# we need this here because because signals are also paused when the
	# game is paused, so we need to unpause first.
	get_tree().paused = false
	_result_ready.emit(true)


func _on_no_button_pressed():
	# we need this here because because signals are also paused when the
	# game is paused, so we need to unpause first.
	get_tree().paused = false
	_result_ready.emit(false)
