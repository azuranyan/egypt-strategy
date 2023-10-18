extends Node
class_name BattleActionController


## Initializes the controller. Called once every battle start.
func initialize(_battle: Battle, _empire: Empire) -> void:
	pass


## Called when action has to be executed.
func do_action() -> void:
	push_error('no action implemented!')
	
	
## Called when turn starts.
func turn_start() -> void:
	pass
	

## Called when turn ends.
func turn_end() -> void:
	pass

	
## Called when action is started.
func action_start() -> void:
	pass
	

## Called when action is ended.
func action_end() -> void:
	pass
