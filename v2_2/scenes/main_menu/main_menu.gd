extends CanvasLayer

signal start_selected
signal continue_selected
signal load_selected
signal settings_selected
signal extras_selected
signal credits_selected
signal exit_selected

signal _close


func _ready():
	if Util.is_f6(self):
		show_main_menu.call_deferred()


func show_main_menu():
	$Control/HBoxContainer/Button1.release_focus()
	$Control/HBoxContainer/Button2.release_focus()
	$Control/HBoxContainer/Button3.release_focus()
	$Control/HBoxContainer/Button4.release_focus()
	$Control/HBoxContainer/Button5.release_focus()
	$Control/HBoxContainer/Button6.release_focus()
	$Control/HBoxContainer/Button7.release_focus()
	# TODO do title screen animation, wait for input to skip
	
	await _close


func _on_button_1_pressed():
	_close.emit()
	Game._load_state(Game.create_new_data())
	#SceneManager.call_scene('overworld', 'fade_to_black')


func _on_button_2_pressed():
	_close.emit()


func _on_button_3_pressed():
	_close.emit()


func _on_button_4_pressed():
	_close.emit()


func _on_button_5_pressed():
	_close.emit()


func _on_button_6_pressed():
	_close.emit()


func _on_button_7_pressed():
	Game.quit_game()
	_close.emit()
