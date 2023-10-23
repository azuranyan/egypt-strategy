extends Resource
class_name VictoryCondition


func evaluate(battle: Battle) -> Battle.Result:
	if battle.map.get_units().filter(func(x): return x.empire == battle.context.attacker).is_empty():
		return Battle.Result.DefenderVictory
		
	if battle.map.get_units().filter(func(x): return x.empire == battle.context.defender).is_empty():
		return Battle.Result.AttackerVictory
	
	return Battle.Result.None
	

func win_description() -> String:
	return 'Defeat all enemies.'


func loss_description() -> String:
	return 'All units defeated.'
