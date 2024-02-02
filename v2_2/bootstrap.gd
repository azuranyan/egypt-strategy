extends Node


func _ready():
	launch_game.call_deferred()


## The actual start point of the game.
func launch_game():
	# initialize run args here
	var args := {
		test_string = 'Hello World!',
	}

	# start the game
	Game.game_ended.connect(quit_game, CONNECT_DEFERRED)
	Game._main(args)
	

## Quits the game.
func quit_game():
	get_tree().quit()
