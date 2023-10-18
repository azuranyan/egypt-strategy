extends BattleActionController

var battle: Battle

## Initializes the controller. Called once every battle start.
func initialize(_battle: Battle, _empire: Empire) -> void:
	battle = _battle
	
	
## Called when action has to be executed.
func do_action() -> void:
	await get_tree().create_timer(1.5).timeout
	battle.end_turn()
	
	
## Called when turn starts.
func turn_start() -> void:
	battle.cursor.visible = false
	

## Called when turn ends.
func turn_end() -> void:
	battle.cursor.visible = true

	
## Called when action is started.
func action_start() -> void:
	pass
	

## Called when action is ended.
func action_end() -> void:
	pass
