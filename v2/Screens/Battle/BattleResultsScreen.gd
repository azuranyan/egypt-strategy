extends CanvasLayer


signal animation_finished

signal _text_changed

signal _battle_won_changed


var text: String:
	set(value):
		text = value
		_text_changed.emit()
		
var battle_won: bool = true:
	set(value):
		battle_won = value
		_battle_won_changed.emit()


func _on__text_changed():
	$Control2/Control/Label.text = text


func _on__battle_won_changed():
	if battle_won:
		$Control2/Banner.modulate = Color(0.2, 0.565, 0.525)
	else:
		$Control2/Banner.modulate = Color(0.537, 0.169, 0.224)
	

func _unhandled_input(event):
	# allow the player to cancel
	if event is InputEventKey or InputEventMouseButton:
		$AnimationPlayer.advance(99)
		get_viewport().set_input_as_handled()
		set_process_unhandled_input(false)
