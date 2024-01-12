extends Resource
class_name VictoryCondition

# TODO 
func evaluate(battle: Battle) -> Battle.Result:
	if battle.empire_units[battle.defender].is_empty():
		return Battle.Result.AttackerVictory
		
	if battle.empire_units[battle.attacker].is_empty():
		return Battle.Result.DefenderVictory
		
	return Battle.Result.None
	

func win_description() -> String:
	return 'Defeat all enemies.'


func loss_description() -> String:
	return 'All units defeated.'
