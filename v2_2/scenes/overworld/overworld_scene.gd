class_name OverworldScene
extends GameScene

signal _player_choose_action(action: Dictionary)


@export var _state: StringName

var last_battle_result: BattleResult
var territory_buttons: Array[TerritoryButton]

var _should_end: bool
var overworld: Overworld

@onready var battle_result_banner = $BattleResultBanner


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
	overworld = Game.overworld
	overworld.territory_owner_changed.connect(func(_a, _b, _c): update_territory_buttons())
	

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
		if t._territory == territory:
			return t
	return null

	
## Returns a new context.
func create_initial_data() -> Dictionary:
	assert(is_node_ready(), 'node needs to be ready to save')
	var data := {
		territories = [] as Array[Territory],
		empires = [] as Array[Empire],
		player_empire = null,
		boss_empire = null,
		# these data will be removed later
		grabs = [] as Array[Territory]
	}

	_save_territories(data)
	_save_empires(data)
	data.erase('grabs')
	return data


## Saves the territories to ctx.
func _save_territories(data: Dictionary):
	for button in territory_buttons:
		var node: TerritoryNode = button.territory_node
		var t := Territory.new()
		t.name = node.name
		for adj in node.adjacent:
			t.adjacent.append(adj.name)
		t.maps = node.maps.duplicate()
		t.units = node.get_unit_entries()
		data.territories.append(t)
		data.grabs.append(t)


## Saves the empire to ctx.
func _save_empires(data: Dictionary):
	# add the preset empires
	for node in get_empire_nodes():
		if not node.home_territory_node:
			push_error('"%s" included in Empires, but has no home territory set' % node.name)
			continue
		var e := _create_empire_from_node(node)
		var home_territory: Territory = data.territories.filter(func(t): return t.name == node.home_territory_node.name)[0]
		node.home_territory_node.name
		_set_empire_territory(e, home_territory, true)
		_add_empire_to_data(data, e)
		data.grabs.erase(home_territory)
	
	# add random empires
	_distribute_empires(data)
	
	
## Creates the empire from node. Note that this doesn't set the territories or units.
func _create_empire_from_node(node: EmpireNode) -> Empire:
	var e := Empire.new()
	e.type = node.type
	e.leader_id = node.leader_id
	e.leader = node.leader
	e.hero_units = []
	e.base_aggression = node.base_aggression
	# units and territory will be set later
	e.aggression = node.base_aggression
	return e
	
	
## Adds territory to empire.
func _set_empire_territory(empire: Empire, territory: Territory, home: bool):
	if home:
		empire.home_territory = territory
	if territory not in empire.territories:
		empire.territories.insert(0 if home else empire.territories.size(), territory)
	
	
## Removes territory from empire.
func _unset_empire_territory(empire: Empire, territory: Territory):
	empire.territories.erase(territory)


## Adds the empire to context.
func _add_empire_to_data(data: Dictionary, empire: Empire):
	if empire not in data.empires:
		data.empires.append(empire)
	if empire.is_player_owned():
		data.player_empire = empire
	if empire.is_boss():
		data.boss_empire = empire

	
## Distributes the empires to territories.
func _distribute_empires(data: Dictionary):
	if data.grabs.is_empty():
		return
		
	# create the selection of random empires
	var selection: Array[Empire] = []
	for node in get_random_empire_nodes():
		var empire := _create_empire_from_node(node)
		selection.append(empire)
		if selection.size() > data.grabs.size():
			break
	selection.shuffle()
	
	# every empire gets their home territory
	for empire in selection:
		var idx := randi_range(0, data.grabs.size() - 1)
		var random_territory: Territory = data.grabs.pop_at(idx)
		_set_empire_territory(empire, random_territory, true)
		_add_empire_to_data(data, empire)
		data.grabs.erase(random_territory)
		
	# the rest will be distributed randomly
	for t: Territory in data.grabs:
		# get potential owners
		var potential_owner: Array[Empire] = []
		for e: Empire in selection:
			if e.is_adjacent_territory(t):
				potential_owner.append(e)
		
		# give territory to owner
		if potential_owner.is_empty():
			push_error('isolated territory %s' % t.name)
			_set_empire_territory(selection.pick_random(), t, false)
		else:
			_set_empire_territory(potential_owner.pick_random(), t, false)


#############################################################################

func scene_enter(_kwargs = {}):
	update_territory_buttons()
	

func update_territory_buttons():
	for btn in territory_buttons:
		btn.initialize(overworld.get_territory_by_name(btn.territory_node.name))
		if btn._territory == overworld.boss_empire().home_territory:
			btn.visible = overworld.is_boss_active()
	

func wait_for_player_action() -> Dictionary:
	$InputBlocker.mouse_filter = 2
	var action: Dictionary = await _player_choose_action
	$InputBlocker.mouse_filter = 0
	return action


func initiate_battle(attacker: Empire, defender: Empire, territory: Territory, map_id: int):
	print("%s attacks %s (%s)!" % [attacker.leader_id, territory.name, defender.leader_id])
	# TODO Game.battle.start_battle
	var anim := preload("res://scenes/overworld/marching_animation.tscn").instantiate()
	anim.global_position = find_territory_button(attacker.home_territory).global_position
	add_child(anim)
	anim.march(find_territory_button(territory).global_position)
	await anim.done
	if (attacker.is_player_owned() or defender.is_player_owned()):
		scene_call('battle', {attacker=attacker, defender=defender, territory=territory, map_id=map_id})
	else:
		var result := BattleResult.new(BattleResult.ATTACKER_VICTORY, attacker, defender, territory, map_id)
		await get_tree().create_timer(0.1).timeout
		Game.battle_ended.emit(result)


func show_battle_result_banner(result: BattleResult):
	var banner := battle_result_banner.duplicate()
	add_child(banner)
	await banner.show_parsed_result(result)


# ####################################################################################################
# #region Continuations
# ####################################################################################################

	
# ## Returns the matching continuation from state.
# func get_continuation(state: StringName) -> Callable:
# 	assert(has_method(state))
# 	return Callable(self, state)
	
	
# ## Calls the next continuation.
# func next(cont: Callable) -> void:
# 	if _should_end:
# 		return
# 	_state = cont.get_method()
# 	# TODO this is horrible but it'll do just fine. we do worse things
# 	# like updating objects every frame lol
# 	update_territory_buttons()
# 	cont.call_deferred()
	
	
# ## The start of a new turn cycle.
# func _cont_cycle_start() -> void:
# 	overworld.cycle_started.emit(overworld.cycle())
# 	await Game.wait_for_resume()
# 	return next(_cont_turn_start)
	
	
# ## The start of an empire's turn.
# func _cont_turn_start() -> void:
# 	overworld.turn_started.emit(overworld.on_turn())
# 	await Game.wait_for_resume()
# 	return next(_cont_take_action)
	

# ## Lets the empire on turn do their action.
# func _cont_take_action() -> void:
# 	var on_turn := overworld.on_turn()
# 	# wait for action
# 	var action: EmpireAction
# 	if on_turn.is_player_owned():
# 		print('waiting for player action...')
# 		$InputBlocker.mouse_filter = 2
# 		action = await _player_choose_action
# 		$InputBlocker.mouse_filter = 0
# 	else:
# 		action = await Game.delay_function(get_ai_action, 2, [on_turn])
		
# 	# execute action
# 	if action is AttackAction:
# 		print("%s attacks %s (%s)!" % [action.empire.leader_id, action.target.name, action.target_empire.leader_id])
# 		# TODO Game.battle.start_battle
# 		scene_call('battle', {
# 			attacker = action.empire,
# 			defender = action.target_empire,
# 			territory = action.target,
# 			map_id = action.map_id,
# 		})
# 		# calling scene_call here actually makes it so this object never
# 		# get to wait on this signal but instead, when battle returns, the
# 		# new object will be in this state waiting for the battle results.
# 		return next(_cont_wait_for_battle_result)

# 	if action is RestAction:
# 		print("%s rests. HP recovered." % on_turn.leader_id)
# 		on_turn.hp_multiplier = 1.0
# 		return next(_cont_turn_end)
		
# 	if action is TrainingAction:
# 		print('%s trains units (TODO does nothing)' % on_turn.leader_id)
# 		return next(_cont_turn_end)
		
		
# ## Waits for the battle to finish.
# func _cont_wait_for_battle_result() -> void:
# 	var result: BattleResult = await Game.battle_ended
# 	match result.value:
# 		BattleResult.CANCELLED:
# 			return next(_cont_take_action)
			
# 		BattleResult.NONE:
# 			push_warning('result == BattleResult.NONE')
			
# 		BattleResult.ATTACKER_VICTORY:
# 			transfer_territory(result.defender, result.attacker, result.territory)
# 			result.defender.hp_multiplier = 0.1
			
# 		BattleResult.DEFENDER_VICTORY:
# 			result.attacker.hp_multiplier = 0.1
			
# 		BattleResult.ATTACKER_WITHDRAW:
# 			pass
			
# 		BattleResult.DEFENDER_WITHDRAW:
# 			transfer_territory(result.defender, result.attacker, result.territory)
# 	last_battle_result = result
	
# 	var banner := battle_result_banner.duplicate()
# 	add_child(banner)
# 	await banner.show_parsed_result(last_battle_result)
	
# 	if result.loser().is_defeated():
# 		# transfer units
# 		result.winner().hero_units.append_array(result.loser().hero_units)
# 		result.winner().units.append_array(result.loser().units)
# 		result.loser().units.clear()

# 		# TODO should we really be doing these mutations?
# 		# i think overworld should do this, or whoever answers that signal
# 		# we're gonna send in _cont_wait_for_defeat_events
# 		overworld.defeated_empires().append(result.loser())
# 		return next(_cont_wait_for_defeat_events)
# 	else:
# 		return next(_cont_turn_end)
	
	
# ## Waits for defeat events fo finish.
# func _cont_wait_for_defeat_events() -> void:
# 	# kind of a hack, just cos we can't be arsed to pass the result here
# 	Game.empire_defeated.emit(overworld.defeated_empires().back())
# 	await Game.wait_for_resume()
# 	return next(_cont_turn_end)
	
	
# ## Ends the turn and emits the signal
# func _cont_turn_end() -> void:
# 	overworld.turn_ended.emit(overworld.on_turn())
# 	await Game.wait_for_resume()
	
# 	if overworld.next_turn():
# 		return next(_cont_cycle_end)
# 	else:
# 		return next(_cont_turn_start)
		
		
# ## Ends the current cycle and starts a new one.
# func _cont_cycle_end() -> void:
# 	overworld.cycle_ended.emit(overworld.cycle())
# 	await Game.wait_for_resume()
# 	overworld.end_cycle()
# 	return next(_cont_cycle_start)


# ####################################################################################################
# #endregion Continuations
# ####################################################################################################
	
	
# func get_ai_action(empire: Empire) -> EmpireAction:
# 	# if hurt, rest
# 	if empire.hp_multiplier < 0.8:
# 		return RestAction.new(_context, empire)
		
# 	# increase aggression
# 	empire.aggression += empire.base_aggression + randf()
	
# 	if empire.aggression >= 1:
# 		empire.aggression = 0
# 		var adjacent := empire.get_adjacent(_context.territories)
		
# 		# basic sanity check
# 		if adjacent.is_empty():
# 			push_warning('empire "%s" has no adjacent territories' % empire.leader_name())
# 			return RestAction.new(_context, empire)
		
# 		# attack
# 		var target: Territory = adjacent.pick_random()
# 		return AttackAction.new(_context, empire, _context.get_territory_owner(target), target, 0)
	
# 	# rest
# 	return RestAction.new(_context, empire)
	

## Called by actions to transfer territory.
# func transfer_territory(old_owner: Empire, new_owner: Empire, territory: Territory):
# 	if old_owner == new_owner:
# 		return
# 	_transfer_territory(old_owner, new_owner, territory)
	
# 	if territory == old_owner.home_territory:
# 		if Preferences.defeat_if_home_territory_captured:
# 			while not old_owner.territories.is_empty():
# 				var t: Territory = old_owner.territories.pop_back()
# 				_transfer_territory(old_owner, new_owner, t)
# 		else:
# 			pass # no action taken for losing home territory yet
			
	
# func _transfer_territory(old_owner: Empire, new_owner: Empire, territory: Territory):
# 	#print('transfer %s from %s to %s' % [territory.name, old_owner.leader_name() if old_owner else '(null)', new_owner.leader_name()])
# 	# transfer territory
# 	_unset_empire_territory(_context, old_owner, territory)
# 	_set_empire_territory(_context, new_owner, territory, false)
	
# 	# update buttons
# 	for btn in territory_buttons:
# 		if btn.get_territory(_context) == territory:
# 			btn.initialize(_context, territory)
	
	
func _on_territory_button_attack_pressed(button: TerritoryButton):
	if not overworld.on_turn().is_player_owned():
		push_warning('attack button pressed when not on turn!')
		return
	var attacker := overworld.on_turn()
	var defender := overworld.get_territory_owner(button._territory)
	_player_choose_action.emit({
		type = 'attack',
		attacker = attacker,
		defender = defender,
		territory = button._territory,
		map_id = 0,
	})
	#initiate_battle(attacker, defender, button._territory, 0)
	

func _on_territory_button_rest_pressed(_button: TerritoryButton):
	if not overworld.on_turn().is_player_owned():
		push_warning('rest button pressed when not on turn!')
		return
	_player_choose_action.emit({type='rest'})
	
	
func _on_territory_button_train_pressed(_button: TerritoryButton):
	if not overworld.on_turn().is_player_owned():
		push_warning('train button pressed when not on turn!')
		return
	_player_choose_action.emit({type='train'})
	
	
func _unhandled_input(event) -> void:
	if not is_active():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		return scene_call('pause', {save_data = Game.save_state()})
	
