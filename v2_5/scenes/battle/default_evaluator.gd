class_name DefaultEvaluator
extends BattleResultEvaluator


func evaluate(context: BattleContext) -> Battle.Result:
	if context.get_unit_count(context.attacker) > 0:
		return Battle.Result.ATTACKER_VICTORY
	if context.get_unit_count(context.defender) > 0:
		return Battle.Result.DEFENDER_VICTORY
	return Battle.Result.NONE
	
	
func win_description() -> String:
	return "Defeat all enemies."
	
	
func lose_description() -> String:
	return "All units defeated."
