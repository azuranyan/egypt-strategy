extends GameScene


@export_file("*.tscn") var next_scene_path: String

@export var next_scene: StringName


var _done: bool


func _on_timer_timeout():
	_next_scene()
	

func _unhandled_input(event):
	if not is_active():
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		_next_scene()


func _next_scene():
	if not _done:
		$Timer.stop()
		_done = true
		scene_call(next_scene)
		#SceneManager.call_scene(next_scene_path, 'fade_to_black')
