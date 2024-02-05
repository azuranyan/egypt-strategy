extends GameScene

signal _close


@onready var start_button = $Control/HBoxContainer/StartButton
@onready var continue_button = $Control/HBoxContainer/ContinueButton
@onready var load_button = $Control/HBoxContainer/LoadButton
@onready var settings_button = $Control/HBoxContainer/SettingsButton
@onready var extras_button = $Control/HBoxContainer/ExtrasButton
@onready var credits_button = $Control/HBoxContainer/CreditsButton
@onready var exit_button = $Control/HBoxContainer/ExitButton


func _ready():
	if Util.is_f6(self):
		Game.create_testing_context()
		scene_enter.call_deferred()


func scene_enter(_kwargs := {}):
	extras_button.disabled = Persistent.extras_unlocked
	continue_button.disabled = Persistent.newest_save_slot == -1
	# TODO hack, put into SaveManager
	var savedir := DirAccess.open('user://saves')
	var count := 0
	savedir.list_dir_begin()
	while true:
		var filename := savedir.get_next()
		if not filename:
			break
		count += 1
	savedir.list_dir_end()
	load_button.disabled = count <= 0
	
	
func scene_exit():
	pass


func _on_start_button_pressed():
	Game.load_state(Game.create_new_data())


func _on_continue_button_pressed():
	Game.load_state(SaveManager.load_from_slot(Persistent.newest_save_slot))


func _on_load_button_pressed():
	scene_call('save_load')


func _on_settings_button_pressed():
	pass # Replace with function body.


func _on_extras_button_pressed():
	scene_call('save_load', 'fade_to_black', {save_data=Game.save_state()})


func _on_credits_button_pressed():
	scene_call('credits')


func _on_exit_button_pressed():
	Game.quit_game()
