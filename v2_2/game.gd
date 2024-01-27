@tool
extends Node

signal game_started
signal game_ended


var test_individual_scenes := true


## Returns the viewport size.
func get_viewport_size() -> Vector2:
	# TODO get_viewport().size doesn't work, even with stretch mode set to
	# viewport. despite what godot says, it doesn't change the viewport to
	# project settings set size if window is launched with a fixed size 
	# like maximized and force window size.
	return Vector2(1920, 1080)
	
	
	
func start_game(args := {}):
	test_individual_scenes = false
	game_started.emit()
	_main(args)
	game_ended.emit()
	
	
func _main(_args := {}):
	pass
