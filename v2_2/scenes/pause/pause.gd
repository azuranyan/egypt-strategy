extends GameScene

signal closed


var _save_data: SaveState
	
	
func scene_enter(kwargs := {}):
	get_tree().paused = true 
	_save_data = kwargs.get('save_data')
	%SaveButton.disabled = _save_data == null
	

func scene_exit():
	pass
	


func _unhandled_input(event) -> void:
	if not is_active():
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		get_tree().paused = false
		get_viewport().set_input_as_handled()
		return scene_return()


func _on_main_menu_button_pressed():
	pass


func _on_save_button_pressed():
	get_tree().paused = false
	scene_call('save_load', {save_data = _save_data})


func _on_load_button_pressed():
	get_tree().paused = false
	scene_call('save_load')


func _on_settings_button_pressed():
	var settings = load('res://scenes/common/settings_scene.tscn').instantiate()
	get_tree().root.add_child(settings, true)
	settings.initialize(Game.settings)


func _on_save_quit_button_pressed():
	pass # Replace with function body.
