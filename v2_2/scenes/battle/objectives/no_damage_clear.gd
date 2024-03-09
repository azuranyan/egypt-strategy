class_name NoDamageClearObjective
extends Objective


func _process(_delta: float) -> void:
	# TODO this is horrible, just checking every tick 
	for unit in Game.get_units(Battle.instance().player()):
		if unit.get_stat('hp') < unit.get_stat('maxhp'):
			objective_failed(BattleResult.NONE)
		else:
			objective_completed(BattleResult.NONE)


func description() -> String:
	return "Clear battle without taking any damage."