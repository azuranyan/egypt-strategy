extends Node
class_name BattleActionController


## Initializes the controller. Called once every battle start.
func initialize(_battle: Battle, _empire: Empire) -> void:
	pass


## Called when action has to be executed.
func do_action() -> void:
	print('do nothing ', self)
	await get_tree().create_timer(1.0).timeout
	
	
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
