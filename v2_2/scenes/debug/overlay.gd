class_name TestOverlay
extends CanvasLayer


func _ready():
	$HBoxContainer/LoadButton.disabled = not SaveManager.is_slot_in_use(0)
	


func _on_load_button_pressed():
	Game.load_state(SaveManager.load_from_slot(0))
	

func _on_save_button_pressed():
	SaveManager.save_to_slot(Game.save_state(), 0)
	$HBoxContainer/LoadButton.disabled = not SaveManager.is_slot_in_use(0)
	

func _on_quit_button_pressed():
	Game.quit_game()


func _on_button_pressed():
	print_orphan_nodes()
