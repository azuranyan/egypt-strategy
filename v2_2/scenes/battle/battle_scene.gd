class_name BattleScene
extends GameScene


signal _ctc


func _input(event) -> void:
	if not is_active():
		return
		
	if event.is_action_pressed('ui_accept') or event is InputEventMouseButton and event.is_pressed():
		Game.battle.stop_battle()
