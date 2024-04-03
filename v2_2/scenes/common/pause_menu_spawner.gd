class_name PauseMenuSpawner
extends Node
## A simple component that spawns a pause menu (or dialog).


static var _pause_menu_instances := {}


## The [PauseMenu] or [PauseDialog] scene to use.
@export var pause_menu_scene: PackedScene

## The node to spawn the pause menu on.
@export var spawn_node_path: NodePath

## The action for opening and closing.
@export var toggle_action: StringName = 'ui_cancel'

## Whether the spawner is disabled.
@export var disabled: bool:
	set(value):
		disabled = value
		set_process_unhandled_input(not disabled)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action):
		toggle_pause_menu()


## Opens the pause menu.
func open_pause_menu() -> void:
	close_pause_menu()

	var pause_menu := pause_menu_scene.instantiate()
	var spawn_node := get_node(spawn_node_path)

	pause_menu.closed.connect(func(): _pause_menu_instances.erase(pause_menu_scene))
	spawn_node.add_child(pause_menu)
	_pause_menu_instances[pause_menu_scene] = pause_menu


## Closes the pause menu.
func close_pause_menu() -> void:
	if is_pause_menu_open():
		_pause_menu_instances[pause_menu_scene].close()


## Returns whether the pause menu is open.
func is_pause_menu_open() -> bool:
	return pause_menu_scene in _pause_menu_instances


## Toggles the pause menu.
func toggle_pause_menu() -> void:
	if is_pause_menu_open():
		close_pause_menu()
	else:
		open_pause_menu()
