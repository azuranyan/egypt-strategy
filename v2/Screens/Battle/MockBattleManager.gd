extends BattleManager
class_name MockBattleManager


func initiate_attack(empire: Empire, territory: Territory):
	var win_chance := 1.0 if empire.is_player_owned() else 0.50
	var withdraw := randf() < 0.3
	if randf() <= win_chance:
		if withdraw:
			OverworldEvents.emit_signal("battle_result", empire, territory, Result.DefenderWithdraw)
		else:
			OverworldEvents.emit_signal("battle_result", empire, territory, Result.AttackerVictory)
	else:
		if withdraw:
			OverworldEvents.emit_signal("battle_result", empire, territory, Result.AttackerWithdraw)
		else:
			OverworldEvents.emit_signal("battle_result", empire, territory, Result.DefenderVictory)
