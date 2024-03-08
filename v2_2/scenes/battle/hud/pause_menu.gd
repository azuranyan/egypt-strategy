class_name BattlePauseMenu
extends Control


var _opened := false


@onready var resume_button := %ResumeButton
@onready var forfeit_button := %ForfeitButton
@onready var save_button := %SaveButton
@onready var load_button := %LoadButton
@onready var settings_button := %SettingsButton
@onready var quit_to_title_button := %QuitToTitleButton


func _ready():
	Game.push_pause()
	resume_button.grab_focus()
	_opened = true
	

func _exit_tree() -> void:
	close()

	
func close():
	if not _opened:
		return
	Game.pop_pause()
	if get_viewport().gui_get_focus_owner():
		get_viewport().gui_get_focus_owner().release_focus()
	queue_free()


func _input(event):
	if event.is_action_pressed('cancel') and visible:
		close()
		get_viewport().set_input_as_handled()


func _on_resume_button_pressed():
	close()
