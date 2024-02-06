class_name Overworld
extends GameScene


signal _player_choose_action


var _context: OverworldContext
var _should_end: bool

var territory_buttons: Array[TerritoryButton]


func _ready():
	territory_buttons.clear()
	for i in get_child_count():
		var button := get_child(i) as TerritoryButton
		if not button:
			continue
		territory_buttons.append(button)
		button.attack_pressed.connect(_on_territory_button_attack_pressed)
		button.rest_pressed.connect(_on_territory_button_rest_pressed)
		button.train_pressed.connect(_on_territory_button_train_pressed)


func scene_enter(kwargs := {}):
	pass
	# TODO currently a hack
	Game._overworld = self
	start_overworld_cycle(Game._overworld_context)


func scene_exit():
	pass


## Returns the empire nodes.
func get_empire_nodes() -> Array[EmpireNode]:
	var arr: Array[EmpireNode] = []
	for child in $Empires.get_children():
		if child is EmpireNode:
			arr.append(child)
	return arr


## Returns the random empire nodes.
func get_random_empire_nodes() -> Array[EmpireNode]:
	var arr:Array[EmpireNode] = []
	for child in $RandomEmpireSelection.get_children():
		if child is EmpireNode:
			arr.append(child)
	return arr
	

## Returns the territory node for the empire.
func find_territory_button(territory: Territory) -> TerritoryButton:
	for t in territory_buttons:
		if t.get_territory(_context) == territory:
			return t
	return null

	
## Returns a new context.
func create_new_context() -> OverworldContext:
	if not is_node_ready():
		push_error('create_new_context() requires Overworld to be in the tree')
		return
	var ctx := OverworldContext.new()
	ctx.overworld_scene = PackedScene.new()
	ctx.overworld_scene.pack(self)
	
	_save_territories(ctx)
	_save_empires(ctx)
	
	if not ctx.player_empire:
		push_error('player_empire not found %s' % self)
	if not ctx.boss_empire:
		push_error('boss_empire not found in %s' % self)
	
	ctx.active_empires.append(ctx.player_empire)
	for e in ctx.empires:
		if e.is_random():
			ctx.active_empires.append(e)
			
	#ctx.state = OverworldContext.State.READY
	return ctx


## Saves the territories to ctx.
func _save_territories(ctx: OverworldContext):
	ctx.territories.clear()
	for button in territory_buttons:
		var node: TerritoryNode = button.territory_node
		var t := Territory.new()
		t.name = node.name
		for adj in node.adjacent:
			t.adjacent.append(adj.name)
		t.maps = node.maps.duplicate()
		t.units = node.get_unit_entries()
		ctx.territories.append(t)
	

## Saves the empire to ctx.
func _save_empires(ctx: OverworldContext):
	ctx.empires.clear()
	for node in get_empire_nodes():
		if not node.home_territory_node:
			push_error('"%s" included in Empires, but has no home territory set' % node.name)
			continue
		var e := _create_empire_from_node(ctx, node)
		var home_territory := node.home_territory_node.get_territory(ctx)
		_set_empire_territory(ctx, e, home_territory, true)
		_add_empire_to_context(ctx, e)
	
	_distribute_empires(ctx)
	
	
## Creates the empire from node. Note that this doesn't set the territories or units.
func _create_empire_from_node(_ctx: OverworldContext, node: EmpireNode) -> Empire:
	var e := Empire.new()
	e.type = node.type
	e.leader = node.leader
	e.hero_unit = node.hero_unit
	e.base_aggression = node.base_aggression
	# units and territory will be set later
	e.aggression = node.base_aggression
	return e
	
	
## Adds territory to empire.
func _set_empire_territory(_ctx: OverworldContext, empire: Empire, territory: Territory, home: bool):
	if home:
		empire.home_territory = territory
	if territory not in empire.territories:
		empire.territories.insert(0 if home else empire.territories.size(), territory)
	_cache_territory_units(empire)
	
	
## Removes territory from empire.
func _unset_empire_territory(_ctx: OverworldContext, empire: Empire, territory: Territory):
	empire.territories.erase(territory)
	_cache_territory_units(empire)


## Creates the list of units in empire.
func _cache_territory_units(empire: Empire):
	for t in empire.territories:
		for unit_name in t.units:
			var count: int = t.units[unit_name]
			for i in count:
				var tag := _generate_unit_tag(unit_name, t, i)
				var u := Game.load_unit(unit_name, tag)
				empire.units.append(u)


## Generates wrangled name for units from territory.
func _generate_unit_tag(unit_name: String, territory: Territory, id: int) -> String:
	return '_'.join([unit_name, territory, id])

	
## Adds the empire to context.
func _add_empire_to_context(ctx: OverworldContext, empire: Empire):
	if empire not in ctx.empires:
		ctx.empires.append(empire)
	if empire.is_player_owned():
		ctx.player_empire = empire
	if empire.is_boss():
		ctx.boss_empire = empire
	
	
## Distributes the empires to territories.
func _distribute_empires(ctx: OverworldContext):
	# take territories with no empires assigned yet
	var grabs: Array[Territory] = []
	for t in ctx.territories:
		if ctx.get_territory_owner(t) == null:
			grabs.append(t)
	if grabs.is_empty():
		return
		
	# create the selection of random empires
	var selection: Array[Empire] = []
	for node in get_random_empire_nodes():
		var empire := _create_empire_from_node(ctx, node)
		selection.append(empire)
		if selection.size() > grabs.size():
			break
	selection.shuffle()
	
	# every empire gets their home territory
	for empire in selection:
		var random_territory: Territory = grabs.pop_at(randi_range(0, grabs.size() - 1))
		_set_empire_territory(ctx, empire, random_territory, true)
		_add_empire_to_context(ctx, empire)
		
	# the rest will be distributed randomly
	for territory in grabs:
		var empire: Empire = selection.pick_random()
		_set_empire_territory(ctx, empire, territory, false)
		
		
## Connects territories a and b.
func connect_territories(_ctx: OverworldContext, a: Territory, b: Territory):
	if b not in a.adjacent:
		a.adjacent.append(b)
	if a not in b.adjacent:
		b.adjacent.append(a)
	
	
## Returns true if the overworld is running.
func is_running() -> bool:
	return _context != null
	
	
## Starts the overworld cycle.
func start_overworld_cycle(ctx: OverworldContext) -> void:
	if is_running():
		push_error('overworld is already running.')
		return
	_context = ctx
	_should_end = false
	
	for btn in territory_buttons:
		btn.initialize(_context, btn.get_territory(_context))
		if btn.get_territory(_context) == _context.boss_empire.home_territory:
			btn.visible = _context.is_boss_active()
	
	Game.overworld_started.emit()
	# TODO
	if not ctx.state:
		ctx.state = _cont_cycle_start.get_method()
	
	# next is needed for cps, but here we need to directly call the function
	get_continuation(ctx.state).call()
	
	
## Stops the overworld cycle.
func stop_overworld_cycle():
	_should_end = true
	# TODO add check for player wait action state
	_player_choose_action.emit(null)


####################################################################################################
#region Continuations
####################################################################################################

## Returns the matching continuation from state.
func get_continuation(state: StringName) -> Callable:
	assert(has_method(state))
	return Callable(self, state)
	
	
## Calls the next continuation.
func next(cont: Callable) -> void:
	if _should_end:
		return
	_context.state = cont.get_method()
	cont.call_deferred()
	
	
## The start of a new turn cycle.
func _cont_cycle_start() -> void:
	Game.overworld_cycle_started.emit(_context.cycle_count)
	await Game.wait_for_resume()
	return next(_cont_turn_start)
	
	
## The start of an empire's turn.
func _cont_turn_start() -> void:
	Game.overworld_turn_started.emit(_context.on_turn())
	await Game.wait_for_resume()
	return next(_cont_take_action)
	

## Lets the empire on turn do their action.
func _cont_take_action() -> void:
	# wait for action
	var action: EmpireAction
	if _context.on_turn().is_player_owned():
		print('waiting for player action...')
		$InputBlocker.mouse_filter = 2
		action = await _player_choose_action
		$InputBlocker.mouse_filter = 0
	else:
		action = await Game.delay_function(get_ai_action, 2, [_context.on_turn()])
		
	# execute action
	if action is AttackAction:
		print("%s attacks %s (%s)!" % [action.empire.leader_name(), action.target.name, action.target_empire.leader_name()])
		scene_call('battle', {
			attacker = action.empire,
			defender = action.target_empire,
			territory = action.target,
			map_id = action.map_id,
		})
		return next(_cont_wait_for_battle_result)
		
	if action is RestAction:
		print("%s rests. HP recovered." % _context.on_turn().leader_name())
		_context.on_turn().hp_multiplier = 1.0
		return next(_cont_turn_end)
		
	if action is TrainingAction:
		print('%s trains units (TODO does nothing)' % _context.on_turn().leader_name())
		return next(_cont_turn_end)
		
		
## Waits for the battle to finish.
func _cont_wait_for_battle_result() -> void:
	var result: BattleResult = await Game.battle_ended
	match result.value:
		BattleResult.CANCELLED:
			return next(_cont_take_action)
			
		BattleResult.NONE:
			push_warning('result == BattleResult.NONE')
			
		BattleResult.ATTACKER_VICTORY:
			transfer_territory(result.defender, result.attacker, result.territory)
			result.defender.hp_multiplier = 0.1
			
		BattleResult.DEFENDER_VICTORY:
			result.attacker.hp_multiplier = 0.1
			
		BattleResult.ATTACKER_WITHDRAW:
			pass
			
		BattleResult.DEFENDER_WITHDRAW:
			transfer_territory(result.defender, result.attacker, result.territory)
			
	return next(_cont_turn_end)
	
	
## Ends the turn and emits the signal
func _cont_turn_end() -> void:
	Game.overworld_turn_ended.emit(_context.on_turn())
	await Game.wait_for_resume()
	
	# finds the first valid and active empire
	var end_turn_cycle = false
	while true:
		_context.turn_index += 1
		if _context.turn_index >= _context.active_empires.size():
			_context.turn_index = 0
			end_turn_cycle = true
			break
		if _context.on_turn() not in _context.defeated_empires:
			break
	
	if end_turn_cycle:
		return next(_cont_cycle_end)
	else:
		return next(_cont_turn_start)
		
		
## Ends the current cycle and starts a new one.
func _cont_cycle_end() -> void:
	Game.overworld_cycle_ended.emit(_context.cycle_count)
	await Game.wait_for_resume()
	for defeated in _context.defeated_empires:
		_context.active_empires.erase(defeated)
	_context.cycle_count += 1
	return next(_cont_cycle_start)


####################################################################################################
#endregion Continuations
####################################################################################################
	
	
func get_ai_action(empire: Empire) -> EmpireAction:
	# if hurt, rest
	if empire.hp_multiplier < 0.8:
		return RestAction.new(_context, empire)
		
	# increase aggression
	empire.aggression += empire.base_aggression + randf()
	
	if empire.aggression >= 1:
		empire.aggression = 0
		var adjacent := empire.get_adjacent(_context.territories)
		
		# basic sanity check
		if adjacent.is_empty():
			push_warning('empire "%s" has no adjacent territories' % empire.leader_name())
			return RestAction.new(_context, empire)
		
		# attack
		var target: Territory = adjacent.pick_random()
		return AttackAction.new(_context, empire, _context.get_territory_owner(target), target, 0)
	
	# rest
	return RestAction.new(_context, empire)
	

## Called by actions to transfer territory.
func transfer_territory(old_owner: Empire, new_owner: Empire, territory: Territory):
	if old_owner == new_owner:
		return
	_transfer_territory(old_owner, new_owner, territory)
	
	if territory == old_owner.home_territory:
		if Preferences.defeat_if_home_territory_captured:
			while not old_owner.territories.is_empty():
				var t: Territory = old_owner.territories.pop_back()
				_transfer_territory(old_owner, new_owner, t)
		else:
			pass # no action taken for losing home territory yet
			
	if old_owner.is_defeated():
		_context.defeated_empires.append(old_owner)
		if old_owner.is_player_owned():
			Game.player_defeated.emit()
		elif old_owner.is_boss():
			Game.boss_defeated.emit()
		else:
			Game.empire_defeated.emit(old_owner)
		await Game.wait_for_resume()
		
	
func _transfer_territory(old_owner: Empire, new_owner: Empire, territory: Territory):
	print('transfer %s from %s to %s' % [territory.name, old_owner.leader_name() if old_owner else '(null)', new_owner.leader_name()])
	if old_owner:
		_unset_empire_territory(_context, old_owner, territory)
	_set_empire_territory(_context, new_owner, territory, false)
	for btn in territory_buttons:
		if btn.get_territory(_context) == territory:
			btn.initialize(_context, territory)
	
	
func _on_territory_button_attack_pressed(button: TerritoryButton):
	if not _context.on_turn().is_player_owned():
		push_warning('attack button pressed when not on turn!')
		return
	var territory := button.get_territory(_context)
	var attacker := _context.on_turn()
	var defender := _context.get_territory_owner(territory)
	_player_choose_action.emit(AttackAction.new(_context, attacker, defender, territory))
	
	
func _on_territory_button_rest_pressed(_button: TerritoryButton):
	if not _context.on_turn().is_player_owned():
		push_warning('rest button pressed when not on turn!')
		return
	_player_choose_action.emit(RestAction.new(_context, _context.on_turn()))
	
	
func _on_territory_button_train_pressed(_button: TerritoryButton):
	if not _context.on_turn().is_player_owned():
		push_warning('train button pressed when not on turn!')
		return
	_player_choose_action.emit(TrainingAction.new(_context, _context.on_turn()))
	
	
func _unhandled_input(event) -> void:
	if not is_active():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		return scene_call('pause', {save_data = Game.save_state()})
	
	
## Base class for actions
class EmpireAction extends Resource:
	var context: OverworldContext
	var empire: Empire
	var description: String
	var cycle: int
	var turn_index: int
	
	func _init(_context: OverworldContext, _empire: Empire, _description: String):
		context = _context
		empire = _empire
		description = _description
		cycle = _context.cycle_count
		turn_index = _context.turn_index
		
	func _to_string() -> String:
		return '<[%s:%s] id=%s leader="%s" action="%s">' % [cycle, turn_index, empire.id, empire.leader_name(), description]
	
	
## Attack action
class AttackAction extends EmpireAction:
	var target_empire: Empire
	var target: Territory
	var map_id: int
	
	func _init(_context: OverworldContext, _empire: Empire, _target_empire: Empire, _target: Territory, _map_id := 0):
		super(_context, _empire, 'Attack')
		target_empire = _target_empire
		target = _target
		map_id = _map_id
	
	
## Rest action
class RestAction extends EmpireAction:
	
	func _init(_context: OverworldContext, _empire: Empire):
		super(_context, _empire, 'Rest')
		
	
## Training action
class TrainingAction extends EmpireAction:
	
	func _init(_context: OverworldContext, _empire: Empire):
		super(_context, _empire, 'Train')
		
