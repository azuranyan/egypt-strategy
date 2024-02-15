class_name ForfeitDialog
extends Control

signal forfeited(value: bool)


var _value: bool


@onready var confirm_button = %ForfeitConfirmButton
@onready var cancel_button = %ForfeitCancelButton


func _ready():
	hide()
	
	
func _input(event):
	if event.is_action_pressed('back') and visible:
		_close(false)
		get_viewport().set_input_as_handled()


func _close(value: bool):
	_value = value
	hide()


func _on_visibility_changed():
	if not is_node_ready():
		return
	if visible:
		Game.push_pause()
		cancel_button.grab_focus()
	else:
		Game.pop_pause()
		if get_viewport().gui_get_focus_owner():
			get_viewport().gui_get_focus_owner().release_focus()
	forfeited.emit(_value)


func _on_forfeit_confirm_button_pressed():
	_close(true)


func _on_forfeit_cancel_button_pressed():
	_close(false)
