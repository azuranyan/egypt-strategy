extends Resource
class_name VictoryCondition

# TODO 
func evaluate(battle: BattleManager) -> BattleManager.Result:
	if battle.empire_units[battle.defender].is_empty():
		return BattleManager.Result.AttackerVictory
		
	if battle.empire_units[battle.attacker].is_empty():
		return BattleManager.Result.DefenderVictory
		
	return BattleManager.Result.None
	

func win_description() -> String:
	return 'Defeat all enemies.'


func loss_description() -> String:
	return 'All units defeated.'
