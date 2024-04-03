class_name SaveSlot
extends Control

signal pressed
signal close_pressed

@export var slot: int


func _ready():
	initialize(null, false)


func initialize(save: SaveState, newest: bool):
	if save:
		$Occupied.visible = true
		$Empty.visible = false
		$Occupied/TimestampLabel.text = Time.get_datetime_string_from_datetime_dict(save.timestamp, true)
		$Occupied/PreviewRect.texture = save.preview
		# TODO change depending on active context
		$Occupied/ChapterLabel.text = 'Chapter 1'
		$Occupied/EventLabel.text = 'Learning the basics.'
		$Occupied/TurnLabel.text = 'Turn 1'
	else:
		$Occupied.visible = false
		$Empty.visible = true
		
	$NewLabel.visible = newest
	$NumberLabel.text = str(slot)


func _on_focus_entered():
	$Highlight.show()


func _on_focus_exited():
	$Highlight.hide()


func _on_button_pressed():
	close_pressed.emit()
	

func _on_gui_input(event):
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event.is_action_pressed('ui_accept')):
		accept_event()
		pressed.emit()
		


func _on_mouse_entered():
	$Highlight.show()


func _on_mouse_exited():
	$Highlight.visible = has_focus()
