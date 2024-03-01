extends Node



func _ready():
	OverworldEvents.overworld_scene_entered.connect(func(): print('Overworld started!'))
	OverworldEvents.overworld_scene_exiting.connect(func(): print('Overworld ended!'))
	
	OverworldEvents.cycle_started.connect(func(count): print('Cycle %s started' % count))
	OverworldEvents.cycle_ended.connect(func(count): print('Cycle %s ended' % count))
	
	OverworldEvents.turn_started.connect(func(empire): print('%s turn started' % empire.leader_id))
	OverworldEvents.turn_ended.connect(func(empire): print('%s turn ended' % empire.leader_id))

	OverworldEvents.empire_defeated.connect(empire_defeated)
	
	BattleEvents.battle_started.connect(func(_a, _d, _t, _m): print('Battle Started'))
	BattleEvents.battle_ended.connect(show_parsed_result)


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
		return
		
	# show Game Over screen
	var instance := preload("res://scenes/game_over/game_over.tscn").instantiate()
	if empire.is_boss():
		instance.game_over_message = 'Game Finished'
	get_tree().root.add_child(instance)
		
