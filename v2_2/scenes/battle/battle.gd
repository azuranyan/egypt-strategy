class_name Battle
extends GameScene


var _context: BattleContext


signal _ctc


func start_battle(ctx: BattleContext):
	_context = ctx
	scene_return({
		result = BattleResult.new(BattleResult.ATTACKER_VICTORY, ctx.attacker, ctx.defender, ctx.territory, 0),
		message = 'you are kakkoi',
	})


func scene_enter(kwargs := {}):
	Game._battle = self
	Game._battle_context.attacker = kwargs.attacker
	Game._battle_context.defender = kwargs.defender
	Game._battle_context.territory = kwargs.territory
	Game._battle_context.map_id = kwargs.map_id
	
	
func scene_exit():
	var result := BattleResult.new(BattleResult.ATTACKER_VICTORY, Game._battle_context.attacker, Game._battle_context.defender, Game._battle_context.territory, Game._battle_context.map_id)
	Game.battle_ended.emit(result)


func _input(event) -> void:
	if not is_active():
		return
	if event.is_action_pressed('ui_accept') or event is InputEventMouseButton and event.is_pressed():
		return scene_return()
