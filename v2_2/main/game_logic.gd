extends Node

# temporary location for glue logic

func _ready():
	#var dir := DirAccess.open('res://units')
	#var file := dir.get_next()
	#while file:
	#	var 
	#	file = dir.get_next()
	Game.game_started.connect(_on_game_started)

	OverworldEvents.overworld_scene_entered.connect(func(): print('Overworld started!'))
	OverworldEvents.overworld_scene_exiting.connect(func(): print('Overworld ended!'))
	
	OverworldEvents.cycle_started.connect(_on_overworld_cycle_start)
	OverworldEvents.cycle_ended.connect(func(count): print('Cycle %s ended' % count))
	
	OverworldEvents.turn_started.connect(func(empire): print('%s turn started' % empire.leader_id))
	OverworldEvents.turn_ended.connect(_on_overworld_turn_end)

	OverworldEvents.empire_defeated.connect(_on_empire_defeated)
	
	BattleEvents.battle_started.connect(func(_a, _d, _t, _m): print('Battle Started'))
	BattleEvents.battle_ended.connect(_on_battle_ended)
	

func show_parsed_result(result: BattleResult):
	print("result={value}; attacker={attacker}; defender={defender}; territory={territory}; player_participating={player_participating}; player_won={player_won}".format({
		value = result.value,
		attacker = result.attacker.leader_id,
		defender = result.defender.leader_id,
		territory = result.territory.name,
		player_participating = result.is_player_participating(),
		player_won = result.player_won(),
	}))


func _on_game_started():
	print('Game started')
	Dialogue.instance().register_event(load('res://units/alara/story_event_1.tres'), load('res://units/alara/chara.tres'))
	Dialogue.instance().register_event(load('res://units/alara/story_event_2.tres'), load('res://units/alara/chara.tres'))	
	Dialogue.instance().register_event(load('res://units/alara/story_event_3.tres'), load('res://units/alara/chara.tres'))


func _on_battle_ended(result: BattleResult):
	show_parsed_result(result)
	if Dialogue.instance().refresh_event_queue():
		DialogueEvents.new_event_unlocked.emit(Dialogue.instance().event_queue.front())


func _on_overworld_cycle_start(count: int):
	print('Cycle %s started' % count)
	if Dialogue.instance().refresh_event_queue():
		DialogueEvents.new_event_unlocked.emit(Dialogue.instance().event_queue.front())


func _on_overworld_turn_end(empire: Empire):
	print('%s turn ended' % empire.leader_id)


func _on_empire_defeated(empire: Empire):
	print('%s defeated' % empire.leader_name())
	if empire.is_random():
		return
		
	# show Game Over screen
	var instance := preload("res://scenes/game_over/game_over.tscn").instantiate()
	if empire.is_boss():
		instance.game_over_message = 'Game Finished'
	get_tree().root.add_child(instance)
		
