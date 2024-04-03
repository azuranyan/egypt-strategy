extends GameScene

signal _close


@export var bgm: AudioStream


var music_player: AudioStreamPlayer


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

	music_player = AudioManager.play_music(bgm)
	
	
func scene_exit():
	# TODO it shouldn't be necessary to fade out the music ourselves, also it's really troublesome to call this
	AudioManager.fade_out(music_player)


func _on_start_button_pressed():
	Game.start_new_game()


func _on_continue_button_pressed():
	Game.load_state(SaveManager.load_from_slot(Persistent.newest_save_slot))


func _on_load_button_pressed():
	scene_call('save_load')


func _on_settings_button_pressed():
	var settings = load('res://scenes/common/settings_scene.tscn').instantiate()
	get_tree().root.add_child(settings, true)


func _on_extras_button_pressed():
	pass


func _on_credits_button_pressed():
	scene_call('credits')


func _on_exit_button_pressed():
	Game.quit_game()
