class_name BattleManager

enum Result {
	# Attacker wins
	AttackerVictory,
	
	# Attacker loss
	DefenderVictory,
	
	# Attacker loss via withdraw
	AttackerWithdraw,
	
	# Attacker wins via defender withdraw
	DefenderWithdraw,
}

func initiate_attack(empire: Empire, territory: Territory):
	OverworldEvents.emit_signal("battle_result", empire, territory, Result.AttackerVictory)
