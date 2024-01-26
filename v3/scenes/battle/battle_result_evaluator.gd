class_name BattleResultEvaluator
extends Resource
## Base class for custom behavior for evaluating battle result.


## Returns the battle result.
func evaluate(_context: BattleContext) -> Battle.Result:
	return Battle.Result.NONE
	
	
## The message to be shown as victory condition or bonus goal.
func win_description() -> String:
	return ""
	
	
## The message to be shown as lose condition.
func lose_description() -> String:
	return ""
