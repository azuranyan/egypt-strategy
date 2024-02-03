extends Node


func _ready():
	launch_game.call_deferred()


## The actual start point of the game.[br]
## This scene will be replaced by the first scene, so no persistent data.
func launch_game():
	# initialize run args here
	var args := {
		test_string = 'Hello World!',
	}
	
	var scenes := {
		battle = "res://scenes/battle/battle.tscn",
		overworld = "res://scenes/overworld/overworld.tscn",
		main_menu = "res://scenes/main_menu/main_menu.tscn",
	}
	
	SceneManager.scenes = scenes
	
	# start the game
	Game._main(args)
