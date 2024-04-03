class_name Battle
extends CanvasLayer


signal _resumed


## Battle states.
enum State {
	## Battle is waiting to start a battle.
	STANDBY = 0,
	
	## Battle has been initiated.
	STARTED,
	
	## Player preparation phase.
	PREPARATION,
	
	## Battle phase.
	BATTLE,
	
	## Battle is being ended.
	ENDING,
}


enum Result {
	ERROR = -2,
	
	CANCELLED = -1,
	
	NONE = 0,
	
	ATTACKER_VICTORY,
	
	DEFENDER_VICTORY,
	
	ATTACKER_WITHDRAW,
	
	DEFENDER_WITHDRAW,
}


var context: BattleContext
var suspended: bool

@onready var level := %Level as Level


static func player_battle_result_message(is_attacker: bool, result: Result) -> String:
	if is_attacker:
		match result:
			Result.ATTACKER_VICTORY:
				return 'Territory Taken!'
			Result.DEFENDER_VICTORY:
				return 'Conquest Failed.'
			Result.ATTACKER_WITHDRAW:
				return 'Battle Forfeited.'
			Result.DEFENDER_WITHDRAW:
				return 'Enemy Withdraw!'
	else:
		match result:
			Result.ATTACKER_VICTORY:
				return 'Territory Lost.'
			Result.DEFENDER_VICTORY:
				return 'Defense Success!'
			Result.ATTACKER_WITHDRAW:
				return 'Enemy Withdraw!'
			Result.DEFENDER_WITHDRAW:
				return 'Territory Surrendered.'
	return ''


func _ready():
	if Game.test_individual_scenes:
		_test.call_deferred()


func start_battle(attacker: Empire, defender: Empire, territory: Territory, map_id: int):
	if context:
		push_error("Battle has already started.")
		return
	print("[Battle] Battle started!")
	context = _create_context(attacker, defender, territory, map_id)
	
	var quick := not (context.attacker.is_player_owned() or context.defender.is_player_owned())
	
	context.state = State.STARTED
	BattleEventBus.battle_started.emit(quick)
	await _wait_for_resume()
	
	if quick:
		await _quick_battle()
	else:
		await _real_battle()
		
	BattleEventBus.battle_ended.emit()
	await _wait_for_resume()
	context = null
	
	
func _create_context(attacker: Empire, defender: Empire, territory: Territory, map_id: int) -> BattleContext:
	var ctx := BattleContext.new()
	ctx.state = State.STANDBY
	ctx.on_turn = null
	ctx.result = Battle.Result.NONE
	ctx.attacker = attacker
	ctx.defender = defender
	ctx.territory = territory
	ctx.map_id = map_id
	ctx.empire_units[attacker] = []
	ctx.empire_units[defender] = []
	ctx.battle = self
	ctx.map = null
	return ctx
	
	
func _quick_battle():
	print("[Battle] Quick battling.")
	context.result = Battle.Result.ATTACKER_VICTORY # todo
	
	
func _real_battle():
	print("[Battle] Entering battle.")
	set_agent(context.attacker, create_agent(context.attacker))
	set_agent(context.defender, create_agent(context.defender))
		
	if await _load_map(context.territory.maps[context.map_id]):
		if await _prepare_units():
			await _real_battle_main()
			
			var message := Battle.player_battle_result_message(context.attacker.is_player_owned(), context.result)
			if message != '':
				var node := preload("res://scenes/battle/battle_result_screen.tscn").instantiate()
				get_tree().root.add_child.call_deferred(node)
				node.text = message
				node.battle_won = context.get_winner() == context.player()
				await node.animation_finished
				node.queue_free()
		
	delete_agent(get_agent(context.attacker))
	delete_agent(get_agent(context.defender))
	level.unload_map()
	

func _load_map(map: PackedScene) -> bool:
	if not level.load_map(map):
		end_battle(Battle.Result.ERROR)
		return false
		
	_redistribute_units()
	
	context.on_turn = context.ai()
	await get_agent(context.ai()).prepare_units()
	return true
	
	
func _redistribute_units():
	print("[Battle] Redistributing units.")
	for u in level.get_objects('unit'):
		if not u.has_meta('default_owner'):
			print('[Battle] Pre-placed unit missing default_owner metadata.')
			u.queue_free()
			continue
		
		var empire := context.get_empire(u.get_meta('default_owner'))
		if empire:
			# we just assume that u is of type Unit. this isn't ideal but
			# using strings for level.get_objects() isn't either, anyway.
			# here's an assert for everyone's peace of mind.
			assert(u is Unit, 'MapObject is tagged "unit" but is not a MapUnit')
			u.set_meta("Battle_unit_pre_placed", true)
			spawn_unit(u.unit_type, empire, {map_unit=u, map_position=u.map_position})
		else:
			u.queue_free()


func _prepare_units() -> bool:
	context.state = State.PREPARATION
	context.on_turn = context.player()
	await get_agent(context.player()).prepare_units()
	return not context.should_end()
	
	
func _real_battle_main():
	print("[Battle] Battle started!")
	context.state = State.BATTLE
	for u in level.get_objects('unit'):
		u.stats.hp = maxi(1, int(u.empire.hp_multiplier * u.stats.maxhp))
		
	while not context.should_end():
		BattleEventBus.turn_cycle_started.emit()
		await _wait_for_resume()
		
		for empire in [context.attacker, context.defender]:
			if context.should_end():
				break
			
			context.on_turn = empire
			for u in context.get_empire_units(empire):
				pass # TODO
		
	print("[Battle] Battle ended.")
	
	
## Creates the agent for the empire.
func create_agent(empire: Empire) -> BattleAgent:
	if empire.is_player_owned():
		return BattleAgent.new()
	else:
		return BattleAgent.new()
		
	
## Sets the agent for empire.
func set_agent(empire: Empire, agent: BattleAgent):
	$Agents.add_child(agent)
	agent.initialize(self, empire)
	empire.set_meta("Battle_agent", agent)
	
		
## Deletes the agent.
func delete_agent(agent: BattleAgent):
	$Agents.remove_child(agent)
	agent.empire.remove_meta("Battle_agent")
	agent.queue_free()
	
	
## Returns the agent for the empire if available.
func get_agent(empire: Empire) -> BattleAgent:
	if not empire.has_meta("Battle_agent"):
		return null # get_meta produces an error if null
	return empire.get_meta("Battle_agent")
	
	
	
## Sets the battle to ending state and gracefully quits.
func end_battle(result: Result):
	context.result = result
	context.state = State.ENDING
	get_agent(context.on_turn).force_end()
	
	
## Suspends the battle execution on the next checkpoint.
func queue_suspend():
	suspended = true
	
	
## Resumes the battle execution.
func resume():
	if suspended:
		suspended = false
		_resumed.emit()
		
	
func _wait_for_resume():
	if suspended:
		await _resumed
	
	
#region UnitState Functions
func create_unit(unit_type: UnitType, empire: Empire, prop := {}) -> Unit:
	assert(empire == context.attacker or empire == context.defender)
	var unit := preload("res://scenes/battle/map/map_objects/unit.tscn").instantiate() as Unit
	prop.empire = empire
	unit.unit_state = UnitState.new(unit_type, prop)
	return unit


## Spawns a unit.
func spawn_unit(unit_type: UnitType, empire: Empire, prop := {}) -> Unit:
	assert(empire == context.attacker or empire == context.defender)
	var unit := create_unit(unit_type, empire, prop)
	context.empire_units[unit.empire].append(unit)
	return unit
	
	
## Removes a unit from the map and frees its resources.
func delete_unit(unit: UnitState):
	if not is_instance_valid(unit):
		return # erase does nothing if not exist
	assert(unit.empire == context.attacker or unit.empire == context.defender)
	
	#if UnitState.get_unit(unit.map_unit) != unit:
	#	push_error('"%s" not spawned with spawn_unit' % unit)
	#	return
		
	unit.map_unit.queue_free()
	unit.map_unit = null
	unit.free()


## Starts the driver and returns it.
func create_unit_driver(unit: Unit, path: PackedVector2Array) -> UnitDriver:
	var driver := preload("res://scenes/battle/unit/unit_driver.tscn").instantiate() as UnitDriver
	driver.target = unit
	driver.world = context.map.world
	add_child(driver)
	driver.start_driver(path)
	return driver

#endregion UnitState Functions
		

func _test():
	var a := CharacterInfo.new()
	a.set_meta('player', true)
	
	var b := CharacterInfo.new()
	b.set_meta('ai', true)
	
	var attacker := Empire.new()
	attacker.leader = a
	
	var defender := Empire.new()
	defender.leader = b
	
	var territory := Territory.new()
	territory.maps = [preload("res://maps/starting_zone/starting_zone.tscn")]
	
	start_battle(attacker, defender, territory, 0)
