extends BattleAgent


signal _ctc


## Called on initialize.
func _initialize():
	pass
	

## Called on start preparation.
func _enter_prepare_units():
	await _ctc
	end_prepare_units()
	
	
## Called on end preparation.
func _exit_prepare_units():
	pass
	
	
## Called on turn start.
func _enter_turn():
	end_turn()
	
	
### Called on turn end.
func _exit_turn():
	pass
	

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		_ctc.emit()