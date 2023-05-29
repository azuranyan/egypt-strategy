extends Node

signal UI_ACTIVE(active)
signal BOSS_ENABLED(value)

var empires = []
var boss_empire: Node = null
var current_turn: int = 0
var territory_antee = []
var agressor_empire 
var defender_empire

var UI_active = true

func _ready():
	pass

func start_turn():
	var current_empire = empires[current_turn]
	emit_signal("UI_ACTIVE", false)
	UI_active = false

	if current_turn == 0:
		player_turn()
	else:
		ai_empire_turn(current_empire)

func determine_next_turn():
	while(true):
		current_turn = (current_turn + 1 % empires.size)
		if empires[current_turn].has_been_beaten() == false : 
			break
	determine_boss_active()
	start_turn()

func determine_boss_active():
	var remaining_empires = 0
	for empire in empires:
		if not empire.has_been_beaten():
			remaining_empires += 1 
	if remaining_empires <= 1:
		emit_signal("BOSS_ENABLED", true)

func player_turn():
	emit_signal("UI_ACTIVE", true)
	UI_active = true

func ai_empire_turn(empire: Node):
	emit_signal("UI_ACTIVE", false)
	UI_active = false
	if empire.hp_multiplier > 0.79:
		var aggression = empire.aggression_rating + randf()
		if aggression >= 1:
			var target_territory = empire.get_adjacent_territories()[randi() % empire.get_adjacent_territories().size()]
			
			territory_antee = target_territory
			agressor_empire = empire
			defender_empire = target_territory.owner_territory
			$Pre_SRPG_BATTLE_MANAGER.start_battle(agressor_empire, defender_empire ,target_territory)
		else:
			empire.aggression_rating += 0.05
			empire.rest_action()
	else:
		empire.rest_action()

	determine_next_turn()
	

enum BattleOutcome { DEFENDER_VICTORY, ATTACKER_WITHDRAWAL, ATTACKER_VICTORY, DEFENDER_WITHDRAWAL }
func _on_Pre_SRPG_BATTLE_MANAGER_battle_outcome(outcome):
		if(outcome == BattleOutcome.DEFENDER_VICTORY):
			agressor_empire.set_hp_multiplier(0.1)
				
		if(outcome == BattleOutcome.ATTACKER_WITHDRAWAL):
			pass

		if(outcome == BattleOutcome.ATTACKER_VICTORY):
			for each_territory in territory_antee:
				defender_empire.lose_territory(each_territory)
				agressor_empire.win_territory(each_territory)
			defender_empire.set_hp_multiplier(0.1)
			
		if(outcome == BattleOutcome.DEFENDER_WITHDRAWAL):
			for each_territory in territory_antee:
				defender_empire.lose_territory(each_territory)
				agressor_empire.win_territory(each_territory)
			


func _on_Zetennu_Area_Klicked(location):
	if UI_active:
		if location in empires[0].get_adjacent_territories():
			territory_antee = location
			agressor_empire = empires[0]
			defender_empire = location.owner_territory
			$Pre_SRPG_BATTLE_MANAGER.start_battle(agressor_empire, defender_empire ,location)
			determine_next_turn()


func _on_NeruKhisi_Area_Klicked(location):
	if UI_active:
		if location in empires[0].get_adjacent_territories():
			territory_antee = location
			agressor_empire = empires[0]
			defender_empire = location.owner_territory
			$Pre_SRPG_BATTLE_MANAGER.start_battle(agressor_empire, defender_empire ,location)
			determine_next_turn()


func _on_Satayi_Area_Klicked(location):
	if UI_active:
		if location in empires[0].get_adjacent_territories():
			territory_antee = location
			agressor_empire = empires[0]
			defender_empire = location.owner_territory
			$Pre_SRPG_BATTLE_MANAGER.start_battle(agressor_empire, defender_empire ,location)
			determine_next_turn()
