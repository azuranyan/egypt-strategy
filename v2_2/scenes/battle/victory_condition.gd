class_name VictoryCondition
extends Resource


func evaluate() -> BattleResult:
	if Game.get_empire_units(Game.battle.defender()).is_empty():
		return BattleResult.attacker_victory()
		
	if Game.get_empire_units(Game.battle.attacker()).is_empty():
		return BattleResult.defender_victory()
		
	return null
	

func win_description() -> String:
	return 'Defeat all enemies.'


func loss_description() -> String:
	return 'All units defeated.'
