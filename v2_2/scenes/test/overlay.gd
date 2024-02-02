class_name TestOverlay
extends CanvasLayer

signal save_button_pressed
signal load_button_pressed
signal quit_button_pressed


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_load_button_pressed():
	load_button_pressed.emit()


func _on_save_button_pressed():
	save_button_pressed.emit()


func _on_quit_button_pressed():
	quit_button_pressed.emit()
