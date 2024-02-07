extends Node



func _ready():
	Game.overworld_started.connect(func(): print('Overworld started!'))
	Game.overworld_ended.connect(func(): print('Overworld ended!'))
	
	Game.overworld_cycle_started.connect(func(count): print('Cycle %s started' % count))
	Game.overworld_cycle_ended.connect(func(count): print('Cycle %s ended' % count))
	
	Game.overworld_turn_started.connect(func(empire): print('%s turn started' % empire.leader_name()))
	Game.overworld_turn_ended.connect(func(empire): print('%s turn ended' % empire.leader_name()))

	Game.battle_ended.connect(show_parsed_result)
	Game.empire_defeated.connect(empire_defeated)


func show_parsed_result(result: BattleResult):
	print("result={value}; attacker={attacker}; defender={defender}; territory={territory}; player_participating={player_participating}; player_won={player_won}".format({
		value = result.value,
		attacker = result.attacker.leader_id,
		defender = result.defender.leader_id,
		territory = result.territory.name,
		player_participating = result.is_player_participating(),
		player_won = result.player_won(),
	}))
	
	
func empire_defeated(empire: Empire):
	print('%s defeated' % empire.leader_name())
	if empire.is_random():
		# if one random still remains that isn't defeated, pass
		for e in Game._overworld_context.active_empires:
			if e.is_random() and e not in Game._overworld_context.defeated_empires:
				return
				
		# spawn boss
		var boss := Game._overworld_context.boss_empire
		var connections := ["Forsaken Temple", "Ruins of Atesh", "Nekhet's Rest"]
		for conn in connections:
			# TODO remove _overworld_context to front facing api
			Game._overworld.connect_territories(Game._overworld_context, boss.home_territory, Game._overworld_context.get_territory_by_name(conn))
			#Game._overworld.add_child(Game._overworld_context.get_territory_by_name())
		Game._overworld_context.active_empires.append(boss)
		# force refresh
		SceneManager.load_new_scene(SceneManager.scenes.overworld, 'fade_to_black')
	else:
		# show Game Over screen
		var game_over_inst := preload("res://scenes/game_over/game_over.tscn").instantiate()
		if empire.is_boss():
			game_over_inst.game_over_message = 'Game Finished'
		get_tree().root.add_child(game_over_inst)
		
