class_name AllUnitsDefeatedTrigger
extends Trigger


func _activated() -> void:
	UnitEvents.died.connect(_on_unit_defeated)
	BattleEvents.turn_ended.connect(_on_turn_ended)


func _deactivated() -> void:
	UnitEvents.died.disconnect(_on_unit_defeated)
	BattleEvents.turn_ended.disconnect(_on_turn_ended)


func check_if_empire_defeated(empire: Empire) -> bool:
	if Game.get_empire_units(empire).is_empty():
		Battle.instance().stop_battle(BattleResult.empire_defeat(empire))
		return true
	return false


func _on_unit_defeated(unit: Unit) -> void:
	check_if_empire_defeated(unit.get_empire())


func _on_turn_ended(_empire: Empire) -> void:
	# check defender first, this way if it ends in mutual defeat the attacker still gets the win
	for empire in [Battle.instance().defender(), Battle.instance().attacker()]:
		if check_if_empire_defeated(empire):
			return
