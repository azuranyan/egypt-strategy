extends Node
class_name BattleAgent


signal _prepare_units_done
signal _turn_done


enum {
	AGENT_STATE_STANDBY,
	AGENT_STATE_PREPARE_UNITS,
	AGENT_STATE_TURN,
}


## Reference to the battle object.
var battle: Battle

## Reference to the empire this agent is controlling.
var empire: Empire

var _state: int


func _ready():
	set_process_input(false)


## Called before the battle starts and before the map is loaded.
func initialize(_battle: Battle, _empire: Empire):
	print(self, ' initializing.')
	_state = AGENT_STATE_STANDBY
	battle = _battle
	empire = _empire
	_initialize()
	_state = AGENT_STATE_STANDBY


## Called by the engine to fill in units.
func prepare_units() -> Dictionary:
	print(self, ' preparing units.')
	set_process_input(true)
	_state = AGENT_STATE_PREPARE_UNITS
	_enter_prepare_units.call_deferred()
	await _prepare_units_done
	_state = AGENT_STATE_STANDBY
	_exit_prepare_units()
	var prep_errors := _get_errors()
	var re := {
		is_error = not prep_errors.is_empty(),
		errors = prep_errors,
	}
	set_process_input(false)
	return re


## Called by the engine for doing the agent's turn.
func do_turn():
	print(self, ' doing turn.')
	set_process_input(true)
	_state = AGENT_STATE_TURN
	_enter_turn.call_deferred()
	await _turn_done
	_state = AGENT_STATE_STANDBY
	_exit_turn()
	set_process_input(false)
	
	
## Unconditionally ends all processes.
func force_end():
	if _state == AGENT_STATE_PREPARE_UNITS:
		end_prepare_units()
	elif _state == AGENT_STATE_TURN:
		end_turn()
	
	
## Unconditionally ends prepare unit phase.
func end_prepare_units():
	if _state == AGENT_STATE_PREPARE_UNITS:
		_prepare_units_done.emit()
	
	
## Unconditionally ends the turn phase.
func end_turn():
	if _state == AGENT_STATE_TURN:
		_turn_done.emit()
		
	
func _initialize():
	pass
	
	
func _enter_prepare_units():
	pass
	
	
func _exit_prepare_units():
	pass
	
	
func _enter_turn():
	pass
	
	
func _exit_turn():
	pass
	
	
func _get_errors() -> PackedStringArray:
	return []
