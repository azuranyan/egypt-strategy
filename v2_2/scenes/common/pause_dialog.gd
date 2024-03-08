@tool
class_name PauseDialog
extends CanvasLayer
## Generalized pause dialog.


## Emitted when closed.
signal closed(value: bool)


@export var default_message := 'Paused':
	set(value):
		default_message = value
		if not is_node_ready():
			await ready
		message_label.text = default_message

@export var default_confirm_text := 'Confirm':
	set(value):
		default_confirm_text = value
		if not is_node_ready():
			await ready
		confirm_button.text = default_confirm_text
		confirm_button.visible = default_confirm_text != ''

@export var default_cancel_text := 'Cancel':
	set(value):
		default_cancel_text = value
		if not is_node_ready():
			await ready
		cancel_button.text = default_cancel_text
		cancel_button.visible = default_cancel_text != ''

@export var show_background := true:
	set(value):
		show_background = value
		if not is_node_ready():
			await ready
		background.visible = show_background


var _is_open: bool


@onready var background = $Background
@onready var message_label = %MessageLabel
@onready var confirm_button = %ConfirmButton
@onready var cancel_button = %CancelButton


func _ready():
	if not Engine.is_editor_hint():
		hide()
	
	
func _input(event):
	if Engine.is_editor_hint():
		return
		
	if event.is_action_pressed('cancel') and visible:
		close_dialog()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	close_dialog()


## Shows dialog.
func open_dialog(message := default_message, confirm_text := default_confirm_text, cancel_text := default_cancel_text):
	close_dialog()

	# set ui
	message_label.text = message
	confirm_button.text = confirm_text
	confirm_button.visible = confirm_text != ''
	cancel_button.text = cancel_text
	cancel_button.visible = cancel_text != ''

	Game.push_pause()
	show()

	# grab focus if we can
	if cancel_button.visible:
		cancel_button.grab_focus()
	elif confirm_button.visible:
		confirm_button.grab_focus()

	_is_open = true


## Closes dialog.
func close_dialog(value: bool = confirm_button.visible and not cancel_button.visible):
	if not _is_open:
		return
	_is_open = false

	# release focus
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner == cancel_button or focus_owner == confirm_button:
		focus_owner.release_focus()

	hide()
	Game.pop_pause()
	
	queue_free()
	closed.emit(value)


func _on_forfeit_confirm_button_pressed():
	close_dialog(true)


func _on_forfeit_cancel_button_pressed():
	close_dialog(false)
