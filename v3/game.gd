@tool
extends Node

signal game_started
signal game_ended

signal transition_started
signal transition_finished


const DUMMY_SCENE := preload("res://scenes/dummy/dummy_scene.tscn")

const LOADING_SCENE := preload("res://scenes/loading/loading_screen.tscn")

const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")

var debug := true
var test_individual_scenes := true

var loading_screen: LoadingScreen

var transition: SceneTransition = null
var current_scene: Node = null


## Starts the overworld cycle.
func start_overworld():
	pass
	
	
## Returns the viewport size.
func get_viewport_size() -> Vector2:
	# TODO get_viewport().size doesn't work, even with stretch mode set to
	# viewport. despite what godot says, it doesn't change the viewport to
	# project settings set size if window is launched with a fixed size 
	# like maximized and force window size.
	return Vector2(1920, 1080)
	
	
## Starts the battle.
func start_battle(attacker: Empire, defender: Empire, territory: Territory, map_id := 0):
	test_individual_scenes = false
	var battle := BATTLE_SCENE.instantiate() as Battle
	
	
func show_loading_screen():
	hide_loading_screen()
	loading_screen = LOADING_SCENE.instantiate()
	get_tree().root.add_child(loading_screen)
	
	
func hide_loading_screen():
	if not is_instance_valid(loading_screen):
		return
	get_tree().root.remove_child(loading_screen)
	loading_screen.queue_free()
	loading_screen = null
	
	
	
func transition_to(new_scene: Node, _transition: SceneTransition) -> Node:
	print('Transitioning from "%s" to "%s"' % [current_scene, new_scene])
	
	# add dummy of the old screen
	var dummy := Game.DUMMY_SCENE.instantiate() as Node
	get_tree().root.add_child(dummy)
	
	var old_scene := current_scene
	# remove old screen
	if old_scene:
		get_tree().root.remove_child(old_scene)
		
	# add new scene
	get_tree().root.add_child.call_deferred(new_scene)
	
	
	return old_scene
	
	
func wait_for_screen_transition():
	if transition != null:
		await transition_finished


func game_start(_args := {}):
	pass
