extends Control

signal _button_selected(v: bool)

	
func show_pause_box(message: String, confirm: Variant, cancel: Variant) -> bool:
	get_tree().paused = true
	if confirm:
		$HBoxContainer/ConfirmButton.text = confirm
	if cancel:
		$HBoxContainer/CancelButton.text = cancel
	$HBoxContainer/ConfirmButton.visible = confirm != null
	$HBoxContainer/CancelButton.visible = cancel != null
	$Label.text = message
	visible = true
	var re: bool = await _button_selected
	visible = false
	get_tree().paused = false
	return re


func _on_confirm_button_pressed():
	_button_selected.emit(true)


func _on_cancel_button_pressed():
	_button_selected.emit(false)
