extends Node
class_name BattleAgent


var battle: Battle
var empire: Empire

var should_end := false


func initialize():
	pass


func prepare_units():
	pass


func do_turn():
	await do_action(Util.do_nothing)
	
	
func do_action(action: Callable, args := []):
	# things can happen before doing any actions so make sure to check
	if battle._evaluate_victory_conditions():
		should_end = true
		return
		
	await action.callv(args)
	
	await battle.wait_for_death_animations()
	
	# check for auto end turn
	if Globals.prefs.auto_end_turn:
		var units := battle.get_owned_units()
		for u in units:
			if battle.can_move(u) or battle.can_attack(u):
				should_end = false
				break
	
	# things can happen after doing an action so make sure to check
	if battle._evaluate_victory_conditions():
		should_end = true
		return
