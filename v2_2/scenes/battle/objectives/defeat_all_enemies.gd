class_name DefeatAllEnemiesObjective
extends Objective
## All enemies must be defeated.


func _activated() -> void:
	UnitEvents.died.connect(_on_unit_defeated)
	BattleEvents.turn_ended.connect(_on_turn_ended)


func _deactivated() -> void:
	UnitEvents.died.disconnect(_on_unit_defeated)
	BattleEvents.turn_ended.disconnect(_on_turn_ended)


## Returns the description.
func description() -> String:
	return "Defeat all enemies" + countdown_suffix()


func is_enemy_defeated() -> bool:
	return Game.get_empire_units(Battle.instance().ai()).is_empty()


func _on_unit_defeated(_unit: Unit) -> void:
	if is_enemy_defeated():
		objective_completed(BattleResult.empire_victory(Battle.instance().player()))


func _on_turn_ended(_empire: Empire) -> void:
	# we check every turn if they are defeated
	if is_enemy_defeated():
		objective_completed(BattleResult.empire_victory(Battle.instance().player()))


		