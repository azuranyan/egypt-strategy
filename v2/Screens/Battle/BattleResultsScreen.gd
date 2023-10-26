extends CanvasLayer
class_name BattleResultsScreen


signal done


func show_result_for(empire: Empire, result: Battle.Result):
	# TODO there should be a smarter way to do this but my brain
	# cells are already fried.
	if empire == Globals.battle.context.attacker:
		match result:
			Battle.Result.AttackerVictory:
				$Control/Label.text = 'Battle Won!'
			Battle.Result.DefenderVictory:
				$Control/Label.text = 'Battle Lost.'
			Battle.Result.AttackerWithdraw:
				$Control/Label.text = 'Battle Forfeited.'
			Battle.Result.DefenderWithdraw:
				$Control/Label.text = 'Enemy Withdraw!'
			_:
				$Control/Label.text = ''
	else:
		match result:
			Battle.Result.AttackerVictory:
				$Control/Label.text = 'Battle Lost.'
			Battle.Result.DefenderVictory:
				$Control/Label.text = 'Battle Won!'
			Battle.Result.AttackerWithdraw:
				$Control/Label.text = 'Enemy Withdraw!'
			Battle.Result.DefenderWithdraw:
				$Control/Label.text = 'Battle Forfeited.'
			_:
				$Control/Label.text = ''
	
	
func _on_done():
	$AnimationPlayer.play('hide')
	await $AnimationPlayer.animation_finished
	queue_free()
	done.emit()
