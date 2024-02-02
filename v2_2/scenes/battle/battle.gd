class_name Battle
extends CanvasLayer


var _context: BattleContext


signal _ctc
func start_battle(ctx: BattleContext):
	_context = ctx
	await _ctc

	var result := BattleResult.new(BattleResult.ATTACKER_VICTORY, ctx.attacker, ctx.defender, ctx.territory, 0)
	Game.battle_ended.emit(result)


func _input(event):
	if event.is_action_pressed('ui_accept') or event is InputEventMouseButton and event.is_pressed():
		_ctc.emit()
