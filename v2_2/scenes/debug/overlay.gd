class_name TestOverlay
extends CanvasLayer


func _ready():
	refresh_load_button()
	

func _on_load_button_pressed():
	Game.load_state(SaveManager.load_from_slot(save_slot()))
	

func _on_save_button_pressed():
	SaveManager.save_to_slot(Game.save_state(), save_slot())
	refresh_load_button()
	
	
func save_slot() -> int:
	if ($OptionButton.selected == 0) or (Persistent.newest_save_slot == -1):
		return 0
	return Persistent.newest_save_slot
	
	
func refresh_load_button():
	$HBoxContainer/LoadButton.disabled = not SaveManager.is_slot_in_use(save_slot())
	

func _on_quit_button_pressed():
	Game.quit_game()


func _on_button_pressed():
	print_orphan_nodes()
