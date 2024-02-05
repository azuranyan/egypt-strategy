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


var _kwargs: Dictionary
func scene_enter(kwargs := {}):
	_kwargs = kwargs.duplicate()
	
	await _ctc
	scene_return('fade_to_black')
	# TODO hacks just to make it work
	if not Game._battle_context:
		var ctx := BattleContext.new()
		ctx.attacker = _kwargs.attacker
		ctx.defender = _kwargs.defender
		ctx.territory = _kwargs.territory
		ctx.map_id = _kwargs.map_id
		ctx.units = Game.units
		ctx.territories = Game._overworld_context.territories
		ctx.empires = Game._overworld_context.empires
		Game._battle_context = ctx
	#{
		#result = BattleResult.new(BattleResult.ATTACKER_VICTORY, attacker, defender, territory, map_id),
		#message = 'you are kakkoi',
	#})
	
	
func scene_exit():
	print('battle scene exit')
	var result := BattleResult.new(BattleResult.ATTACKER_VICTORY, _kwargs.attacker, _kwargs.defender, _kwargs.territory, _kwargs.map_id)
	#Game._battle_context.result = BattleResult.ATTACKER_VICTORY
	Game.battle_ended.emit(result)


func _input(event):
	if event.is_action_pressed('ui_accept') or event is InputEventMouseButton and event.is_pressed():
		_ctc.emit()
		set_process_input(false)
