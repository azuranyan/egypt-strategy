extends Node


@export_file("*.tscn") var start_scene_path: String

@export var scene_registry: Array[SceneRegistryEntry]


func _ready():
	launch_game.call_deferred()


## The actual start point of the game.[br]
## This scene will be replaced by the first scene, so no persistent data.
func launch_game():
	# initialize run args here
	var args := {
		test_string = 'Hello World!',
		start_scene_path = start_scene_path,
	}
	
	for entry in scene_registry:
		SceneManager.scenes[entry.scene_name] = entry.scene_path
	
	# start the game
	Game._main(args)


