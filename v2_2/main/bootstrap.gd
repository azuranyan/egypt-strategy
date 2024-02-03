extends Node


@export var start_scene_name: StringName = &'intro'

@export var scene_registry: Array[SceneRegistryEntry]


func _ready():
	launch_game.call_deferred()


## The actual start point of the game.[br]
## This scene will be replaced by the first scene, so no persistent data.
func launch_game():
	for entry in scene_registry:
		SceneManager.scenes[entry.scene_name] = entry.scene_path
	
	# initialize run args here
	var args := {
		start_scene_path = SceneManager.scenes[start_scene_name],
	}
	
	# start the game
	Game._main(args)


