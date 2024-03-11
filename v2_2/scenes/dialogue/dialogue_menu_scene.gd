extends Control


var _opened := false

@onready var resume_button: Button = %ResumeButton
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_to_title_button: Button = %QuitToTitleButton


func _ready() -> void:
	resume_button.grab_focus()
	_opened = true


func _exit_tree() -> void:
	close()


func _input(event):
	if event.is_action_pressed('cancel') and visible:
		close()
		accept_event()


func close() -> void:
	if not _opened:
		return
	queue_free()


func _on_button_1_pressed() -> void:
	close()
