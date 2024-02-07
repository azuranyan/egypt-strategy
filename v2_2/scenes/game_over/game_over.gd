extends CanvasLayer


@export var game_over_message: String = "Game Over"


func _ready():
	Util.bb_big_caps($Control/Panel/VBoxContainer/RichTextLabel, game_over_message, {
		all_caps = true,
		font_size = 64,
		outline_size = 4,
		outline_color = Color.BLACK,
	})


func _on_last_checkpoint_button_pressed():
	$Control/VBoxContainer/LastCheckpointButton.disabled = true
	$Control/VBoxContainer/QuitToTitleButton.disabled = true
	# TODO should be last checkpoint, but we'll use last save for now
	Game.load_state(SaveManager.get_last_save())
	queue_free()


func _on_quit_to_title_button_pressed():
	$Control/VBoxContainer/LastCheckpointButton.disabled = true
	$Control/VBoxContainer/QuitToTitleButton.disabled = true
	SceneManager.load_new_scene(SceneManager.scenes.main_menu, 'fade_to_black')
	queue_free()
