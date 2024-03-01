class_name BattleAgent extends Node
## The "player" controller object that participates in the battle.


signal _prepare_units_done
signal _turn_done


enum State {
	STANDBY,
	PREPARE_UNITS,
	ON_TURN,
}


## Reference to the empire this agent is controlling
var empire: Empire

## Battle agent state.
var _agent_state: State


func _ready():
	set_process_input(false)
	
	
## Called before the battle starts and before the map is loaded.
func initialize(_empire: Empire):
	_agent_state = State.STANDBY
	empire = _empire
	print("[%s]: initializing" % agent_name())
	_initialize()
	_agent_state = State.STANDBY
	
	
## Called by the engine to fill units in.
func prepare_units():
	set_process_input(true)
	_agent_state = State.PREPARE_UNITS
	_enter_prepare_units.call_deferred()
	print("[%s]: preparing units" % agent_name())
	await _prepare_units_done
	_agent_state = State.STANDBY
	_exit_prepare_units()
	set_process_input(false)
	
	
## Unconditionally ends prepare unit phase.
func end_prepare_units():
	if _agent_state == State.PREPARE_UNITS:
		_prepare_units_done.emit()
	
	
## Called by the engine for doing the agent's turn.
func start_turn():
	set_process_input(true)
	_agent_state = State.ON_TURN
	_enter_turn.call_deferred()
	print("[%s]: doing turn" % agent_name())
	await _turn_done
	_agent_state = State.STANDBY
	_exit_turn()
	set_process_input(false)
	
	
## Unconditionally ends the turn phase.
func end_turn():
	if _agent_state == State.ON_TURN:
		_turn_done.emit()


## Unconditionally ends either phase.
func force_end():
	end_prepare_units()
	end_turn()
		
		
## Returns the agent name.
func agent_name() -> String:
	return "<%s:%s>" % [get_script().get_path().get_file().get_basename(), empire.leader_id]
	
	
## Called on initialize.
func _initialize():
	pass
	

## Called on start preparation.
func _enter_prepare_units():
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
	
