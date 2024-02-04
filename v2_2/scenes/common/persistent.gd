extends Node

const SAVE_PATH := 'user://persistent.tscn'


@export var extras_unlocked: bool = false

@export var newest_save_slot: int = -1


func _ready():
	reload_data()
	
	
func _enter_tree():
	add_to_group('game_event_listeners')
		
		
func on_save(_save: SaveState):
	save_data()
	
	
func on_load(_save: SaveState):
	reload_data()
		
		
func on_quit(_should_end: Array):
	save_data()
	
		
## Reloads persistent data.
func reload_data():
	if FileAccess.file_exists(SAVE_PATH):
		if load_from_file(SAVE_PATH) != 0:
			printerr('failed to load persistent data.')
	else:
		clear_data() 
	
	
## Saves persistent data.
func save_data():
	if save_to_file(SAVE_PATH) != OK:
		printerr('failed to save persistent data.')
	
	
## Resets persistent data.
func clear_data():
	extras_unlocked = false
	newest_save_slot = -1
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
	extras_unlocked = node.extras_unlocked
	newest_save_slot = node.newest_save_slot
	return OK
	
