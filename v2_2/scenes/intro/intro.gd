extends CanvasLayer


@export_file("*.tscn") var next_scene_path: String


var _done: bool


func _on_timer_timeout():
	_next_scene()
	

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		_next_scene()


func _next_scene():
	if not _done:
		$Timer.stop()
		SceneManager.call_scene(next_scene_path, 'fade_to_black')
		_done = true
