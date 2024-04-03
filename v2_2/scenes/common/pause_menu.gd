class_name PauseMenu
extends Control
## A generalized, reusable pause menu.


## Emitted when the pause menu is closed.
signal closed


## Whether to automatically show upon ready.
@export var auto_show: bool = true


@export_group("Connections/Buttons")
@export var resume_button_path: NodePath
@export var save_button_path: NodePath
@export var load_button_path: NodePath
@export var settings_button_path: NodePath
@export var quit_to_title_button_path: NodePath


var _opened := false


@onready var resume_button: Button = get_node(resume_button_path)
@onready var save_button: Button = get_node(save_button_path)
@onready var load_button: Button = get_node(load_button_path)
@onready var settings_button: Button = get_node(settings_button_path)
@onready var quit_to_title_button: Button = get_node(quit_to_title_button_path)


func _ready() -> void:
	# connect resume
	resume_button.pressed.connect(close)

	# connect save
	save_button.disabled = true # TODO
	if not save_button.disabled:
		save_button.pressed.connect(func(): 
			SceneManager.call_scene(SceneManager.scenes.save_load, 'fade_to_black', {save_data=Game.save_state()})
		)

	# connect load
	load_button.pressed.connect(func():
		SceneManager.call_scene(SceneManager.scenes.save_load, 'fade_to_black', {save_data=null})
	)

	# connect settings
	settings_button.pressed.connect(func(): 
		# TODO this piece of code is being repeated in so many scenes, clean it up
		var settings = load(SceneManager.scenes.settings).instantiate()
		get_tree().root.add_child(settings, true)
	)

	# connect quit
	quit_to_title_button.pressed.connect(func():
		close()
		SceneManager.load_new_scene(SceneManager.scenes.main_menu, 'fade_to_black')
	)

	# start opened
	if auto_show:
		resume_button.grab_focus()
	visible = auto_show
	_opened = auto_show


func _exit_tree() -> void:
	close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_cancel') or event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		queue_free()
		get_viewport().set_input_as_handled()
		closed.emit()


## Closes the pause menu.
func close() -> void:
	if not _opened:
		return
	if get_viewport().gui_get_focus_owner():
		get_viewport().gui_get_focus_owner().release_focus()
	_opened = false
	queue_free()
	closed.emit()

