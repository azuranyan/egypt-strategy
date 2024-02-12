extends Control


@onready var resume_button := %ResumeButton
@onready var forfeit_button := %ForfeitButton
@onready var save_button := %SaveButton
@onready var load_button := %LoadButton
@onready var settings_button := %SettingsButton
@onready var quit_to_title_button := %QuitToTitleButton


func _ready():
	hide()
	
	
func _input(event):
	if event.is_action_pressed('back') and visible:
		hide()
		get_viewport().set_input_as_handled()


func _on_visibility_changed():
	if not is_node_ready():
		return
	if visible:
		Game.push_pause()
		resume_button.grab_focus()
		%SaveButton.disabled = Game.battle and not Game.battle.saving_allowed()
	else:
		Game.pop_pause()
		if get_viewport().gui_get_focus_owner():
			get_viewport().gui_get_focus_owner().release_focus()
		

func _on_resume_button_pressed():
	hide()
