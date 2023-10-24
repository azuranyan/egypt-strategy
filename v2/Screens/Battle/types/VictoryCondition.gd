extends Resource
class_name VictoryCondition


func evaluate(battle: Battle) -> Battle.Result:
	if battle.get_owned_units(battle.context.defender).is_empty():
		return Battle.Result.AttackerVictory
		
	if battle.get_owned_units(battle.context.attacker).is_empty():
		return Battle.Result.DefenderVictory
		
	return Battle.Result.None
	

func win_description() -> String:
	return 'Defeat all enemies.'


func loss_description() -> String:
	return 'All units defeated.'
