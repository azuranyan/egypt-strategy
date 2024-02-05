class_name TestOverlay
extends CanvasLayer



func _on_load_button_pressed():
	Game._load_state(SaveManager.load_data('user://saves/0.res'))


func _on_save_button_pressed():
	SaveManager.save_data(Game._save_state(), 'user://saves/0.res')


func _on_quit_button_pressed():
	Game.quit_game()


func _on_button_pressed():
	print_orphan_nodes()
