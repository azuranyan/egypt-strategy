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
	reset_units(Game._battle_context.attacker)
	reset_units(Game._battle_context.defender)
	Game.battle_ended.emit(result)
	
	
func reset_units(e: Empire):
	for u in e.units:
		var base_stats := u.base_stats()
		for stat in base_stats:
			u.stats[stat] = base_stats[stat]
		u.status_effects.clear()
		u.map_position = Map.OUT_OF_BOUNDS
		u.heading = Map.Heading.EAST


func _input(event) -> void:
	if not is_active():
		return
	if event.is_action_pressed('ui_accept') or event is InputEventMouseButton and event.is_pressed():
		return scene_return()
