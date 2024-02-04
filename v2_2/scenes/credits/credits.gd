extends GameScene


func _unhandled_input(event):
	if event.is_action_pressed('ui_accept') or event.is_action_pressed('ui_cancel') or (event is InputEventMouseButton and event.pressed):
		scene_return()
