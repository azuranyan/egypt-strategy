extends GameScene

signal closed


func _ready():
	scene_enter.call_deferred()
	
	
func scene_enter():
	get_tree().paused = true
	await closed
	get_tree().paused = false
	scene_return()


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		
		closed.emit()
	get_viewport().set_input_as_handled()
