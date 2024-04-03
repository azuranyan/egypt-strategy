extends Node


@export var start_scene_name: StringName = &'intro'

const scene_registry := {
	battle = 'res://scenes/battle/battle_scene.tscn',
	credits = 'res://scenes/credits/credits.tscn',
	game_over = 'res://scenes/game_over/game_over.tscn',
	intro = 'res://scenes/intro/intro.tscn',
	main_menu = 'res://scenes/main_menu/main_menu.tscn',
	overworld = 'res://scenes/overworld/overworld_scene.tscn',
	settings = 'res://scenes/common/settings_scene.tscn',
	save_load = 'res://scenes/save_load/save_load.tscn',
	strategy_room = 'res://scenes/strategy_room/strategy_room.tscn',
}


func _ready() -> void:
	launch_game.call_deferred()


## The actual start point of the game.[br]
## This scene will be replaced by the first scene, so no persistent data.
func launch_game() -> void:
	SceneManager.scenes = scene_registry
	
	# initialize run args here
	var kwargs := {
		start_scene_path = SceneManager.scenes[start_scene_name],
	}
	
	var game_logic := preload("res://main/game_logic.gd").new()
	game_logic.name = 'GameLogic'
	Game.add_child(game_logic)
	
	# start the game
	Game._main(kwargs)

	


