class_name VictoryCondition
extends Resource


func evaluate() -> int:
	if Game.get_empire_units(Game.battle.defender()).is_empty():
		return BattleResult.ATTACKER_VICTORY
		
	if Game.get_empire_units(Game.battle.attacker()).is_empty():
		return BattleResult.DEFENDER_VICTORY
		
	return BattleResult.NONE
	

func win_description() -> String:
	return 'Defeat all enemies.'


func loss_description() -> String:
	return 'All units defeated.'
