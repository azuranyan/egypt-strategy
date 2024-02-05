extends GameScene

signal closed

	
func scene_enter(_kwargs := {}):
	get_tree().paused = true 
	# TODO Game.is_saveable_context()
	%SaveButton.disabled = false
	

func scene_exit():
	pass
	


func _unhandled_input(event) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		get_tree().paused = false
		get_viewport().set_input_as_handled()
		return scene_return()


func _on_main_menu_button_pressed():
	pass


func _on_save_button_pressed():
	get_tree().paused = false
	scene_call('save_load', 'fade_to_black', {save_data = Game._save_state()})


func _on_load_button_pressed():
	get_tree().paused = false
	scene_call('save_load')


func _on_settings_button_pressed():
	pass # Replace with function body.


func _on_save_quit_button_pressed():
	pass # Replace with function body.
