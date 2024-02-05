class_name TestOverlay
extends CanvasLayer

signal save_button_pressed
signal load_button_pressed
signal quit_button_pressed


func _on_load_button_pressed():
	load_button_pressed.emit()


func _on_save_button_pressed():
	save_button_pressed.emit()


func _on_quit_button_pressed():
	quit_button_pressed.emit()
