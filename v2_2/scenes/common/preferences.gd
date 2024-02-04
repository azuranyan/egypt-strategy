extends Node

const SAVE_PATH := 'user://preferences.tscn'


@export var defeat_if_home_territory_captured: bool = true

@export var show_intro: bool = true


func _ready():
	reload()
	
	
func _enter_tree():
	add_to_group('game_event_listeners')
		
		
func on_quit(_should_end: Array):
	save_data()
		
		
## Reloads persistent data.
func reload():
	if FileAccess.file_exists(SAVE_PATH):
		if load_from_file(SAVE_PATH) != OK:
			printerr('failed to load preferences.')
	else:
		clear_data() 
	
	
## Saves persistent data.
func save_data():
	if save_to_file(SAVE_PATH) != OK:
		printerr('failed to save preferences.')
	
	
## Resets persistent data.
func clear_data():
	defeat_if_home_territory_captured = true
	show_intro = true
	save_data()
	

## Saves the persistent data to file.
func save_to_file(path: String) -> Error:
	var scene := PackedScene.new()
	scene.pack(self)
	return ResourceSaver.save(scene, path)
	
	
## Loads persistent data from file.
func load_from_file(path: String) -> Error:
	var scene := ResourceLoader.load(path)
	if not (scene and scene is PackedScene and scene.can_instantiate()):
		return FAILED
	var node: Object = scene.instantiate() 
	if not (node and node.get_script() == get_script()):
		return FAILED
	# TODO there should be an automated way to do this with property list
	defeat_if_home_territory_captured = node.defeat_if_home_territory_captured
	show_intro = node.show_intro
	return OK
	

