class_name Battle
extends GameScene


var _context: BattleContext


signal _ctc


func start_battle(ctx: BattleContext):
	_context = ctx
	await _ctc

	scene_return('fade_to_black', {
		result = BattleResult.new(BattleResult.ATTACKER_VICTORY, ctx.attacker, ctx.defender, ctx.territory, 0),
		message = 'you are kakkoi',
	})


func scene_enter(kwargs := {}):
	await _ctc
	scene_return('fade_to_black')
	# TODO hacks just to make it work
	if not Game._battle_context:
		Game._battle_context = BattleContext.new()
	Game._battle_context.attacker = kwargs.attacker
	Game._battle_context.defender = kwargs.defender
	Game._battle_context.territory = kwargs.territory
	Game._battle_context.map_id = kwargs.map_id
	Game._battle_context.units = Game.units
	Game._battle_context.territories = Game._overworld_context.territories
	Game._battle_context.empires = Game._overworld_context.empires
	
	
func scene_exit():
	var result := BattleResult.new(BattleResult.ATTACKER_VICTORY, Game._battle_context.attacker, Game._battle_context.defender, Game._battle_context.territory, Game._battle_context.map_id)
	Game.battle_ended.emit(result)


func _input(event):
	if event.is_action_pressed('ui_accept') or event is InputEventMouseButton and event.is_pressed():
		_ctc.emit()
		set_process_input(false)
