extends Node
class_name BattleAgent


## Reference to the battle object.
var battle: Battle

## Reference to the empire this agent is controlling.
var empire: Empire

## A flag set when the turn should end.
var should_end := false


## To be overriden. Called before the battle starts.
func initialize():
	pass


## Called by the engine to fill in units.
func prepare_units():
	pass


## Called by the engine for doing the agent's turn.
func do_turn():
	# while not should_end:
	#  await do_action(your_custom_action)
	await do_action(Util.do_nothing)
	
	
## Wraps the callable action with necessary calls and waits for it to finish.
func do_action(action: Callable, args := []):
	# check before taking action, because sometimes this can be true before
	# taking any action (e.g. units dying from poison)
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
	
	# need to re-evaluate after every action
	if battle._evaluate_victory_conditions():
		should_end = true
		return
