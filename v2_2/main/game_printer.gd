extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	#Game.game_started.connect(func(): print('Game started!'))
	#Game.game_ended.connect(func(): print('Game ended!'))
	
	Game.overworld_started.connect(func():
		print('Overworld started! %s' % Game._overworld_context.state, ' ', Game._overworld_context.on_turn().leader_name())
	)
	Game.overworld_ended.connect(func(): print('Overworld ended!'))
	
	Game.overworld_cycle_started.connect(func(count): print('Cycle %s started' % count))
	Game.overworld_cycle_ended.connect(func(count): print('Cycle %s ended' % count))
	
	#Game.overworld_turn_started.connect(func(empire): print('%s turn started' % empire.leader_name()))
	#Game.overworld_turn_ended.connect(func(empire): print('%s turn ended' % empire.leader_name()))

	Game.empire_defeated.connect(func(empire): print('%s defeated' % empire.leader_name()))
	#Game.boss_defeated.connect(func(): print('boss defeated, yay!'))
	#Game.player_defeated.connect(func(): print('player defeated, ohno..'))

	#SceneManager.transition_started.connect(func(a, b): print('transition from "%s" to "%s"' % [a, b]))
	#SceneManager.transition_finished.connect(func(errmsg): print('transition finished %s' % errmsg))
