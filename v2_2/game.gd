@tool
extends Node

signal game_started
signal game_ended


const OVERWORLD_SCENE := preload("res://scenes/overworld/overworld.tscn")
var test_individual_scenes := true


var overworld: Overworld
var empires: Array[Empire]
var territories: Array[Territory]


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
	var state := create_new_state()
	load_state(state)
	state = save_state()
	load_state(state)


func create_new_state() -> State:
	print('[Game] Creating new save.')
	var state := State.new()
	state.overworld = OVERWORLD_SCENE
	# TODO
	return state
	
	
func save_state() -> State:
	print('[Game] Saving...')
	assert(is_instance_valid(overworld), 'tried to save without a valid Overworld!')
	var state := State.new()
	state.overworld = PackedScene.new()
	state.overworld.pack(overworld)
	# TODO
	return state
	
	
func load_state(state: State):
	print('[Game] Loading...')
	if is_instance_valid(overworld):
		remove_child(overworld)
		overworld.queue_free()
	overworld = state.overworld.instantiate()
	add_child(overworld)
	empires = overworld.empires
	territories = overworld.territories
	# TODO
	
	
class State extends Resource:
	@export var overworld: PackedScene
