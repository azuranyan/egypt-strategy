class_name OverworldImpl
extends Overworld

@export_group("Game Data")
@export var _overworld_scene: PackedScene
@export var _territories: Array[Territory]
@export var _empires: Array[Empire]
@export var _player_empire: Empire
@export var _boss_empire: Empire

@export_group("State")
@export var _active_empires: Array[Empire]
@export var _defeated_empires: Array[Empire]
@export var _cycle_count: int
@export var _turn_index: int
@export var _state: StringName


var _ai_decision_function: Callable

var _should_end: bool

var new_event: StringName



func _ready():
	add_to_group('game_event_listeners')
	set_ai_decision_function(null)

	empire_defeated.connect(func(_e): if should_summon_boss(): summon_boss())
	DialogueEvents.instance().new_event_unlocked.connect(func(ev): new_event = ev)
	
	
func on_new_save(save: SaveState):
	var overworld_scene := preload("res://scenes/overworld/overworld_scene.tscn")
	var instance: OverworldScene = overworld_scene.instantiate()
	add_child(instance)

	var data := instance.create_initial_data()
	instance.queue_free()
	
	# do some simple verification
	if not data.player_empire:
		push_error('player_empire not found %s' % instance)
	if not data.boss_empire:
		push_error('boss_empire not found in %s' % instance)
	
	# initial values
	data.overworld_scene = overworld_scene
	data.active_empires = [] as Array[Empire]
	data.defeated_empires = [] as Array[Empire]
	data.cycle_count = 0
	data.turn_index = 0
	data.state = &''
	
	# add empires to active
	data.active_empires.append(data.player_empire)
	for e: Empire in data.empires:
		if e.is_random():
			data.active_empires.append(e)

	# give units to empires
	for e: Empire in data.empires:
		# skip non participating empires (aka empires with no home set)
		if not e.home_territory:
			continue
		
		var hero := Game.create_unit(save, e.leader_id, e)
		e.hero_units = [hero.id()]
		e.units.append(hero.id())
		for t in e.territories:
			for chara_id in t.units:
				for i in t.units[chara_id]:
					e.units.append(Game.create_unit(save, chara_id, e).id())
		# yes, this is dumb
		e.units = e.hero_units + e.units
		
	
	# add to save
	save.overworld_data = data


func on_save(save: SaveState):
	save.overworld_data = {
		overworld_scene = _overworld_scene,
		territories = _territories.duplicate(),
		empires = _empires.duplicate(),
		player_empire = _player_empire,
		boss_empire = _boss_empire,
		active_empires = _active_empires.duplicate(),
		defeated_empires = _defeated_empires.duplicate(),
		cycle_count = _cycle_count,
		turn_index = _turn_index,
		state = _state,
	}


func on_load(save: SaveState):
	var data := save.overworld_data
	_overworld_scene = data.overworld_scene
	
	_territories.assign(data.territories)
	_empires.assign(data.empires)
	_player_empire = data.player_empire
	_boss_empire = data.boss_empire
	
	_active_empires.assign(data.active_empires)
	_defeated_empires.assign(data.defeated_empires)
	_cycle_count = data.cycle_count
	_turn_index = data.turn_index
	_state = data.state


## Starts the overworld cycle.
func start_overworld_cycle() -> void:
	# TODO some workaround from the fact that the Game immediately launches
	# overworld (this will be the case until the dialog is implemented)
	if SceneManager.is_loading():
		await SceneManager.transition_finished
		
	if not is_running():
		SceneManager.load_new_scene(SceneManager.scenes.overworld, 'fade_to_black')
		await SceneManager.transition_finished
		
	return next(get_continuation(_state))


####################################################################################################
#region Continuations
####################################################################################################

	
## Returns the matching continuation from state.
func get_continuation(state: StringName) -> Callable:
	if state:
		return Callable(self, state)
	return _cont_cycle_start

	
## Calls the next continuation.
func next(cont: Callable) -> void:
	if _should_end:
		return
	_state = cont.get_method()
	cont.call_deferred()
	

## The start of a new turn cycle.
func _cont_cycle_start() -> void:
	cycle_started.emit(_cycle_count)
	await Game.wait_for_resume()
	return next(_cont_turn_start)
	

## The start of an empire's turn.
func _cont_turn_start() -> void:
	turn_started.emit(on_turn())
	await Game.wait_for_resume()
	return next(_cont_take_action)
	

## Lets the empire on turn do their action.
func _cont_take_action() -> void:
	# wait for action
	var action: Dictionary
	if on_turn().is_player_owned():
		print('waiting for player action...')
		action = await get_active_overworld_scene().wait_for_player_action()
	else:
		action = await Game.delay_function(_ai_decision_function, 0.2, [on_turn()])
		
	# execute action
	if action.type == 'attack':
		get_active_overworld_scene().initiate_battle(action.attacker, action.defender, action.territory, action.map_id)
		return next(_cont_wait_for_battle_result)

	if action.type == 'rest':
		print("%s rests. HP recovered." % on_turn().leader_id)
		on_turn().hp_multiplier = 1.0
		return next(_cont_turn_end)
		
	if action.type == 'train':
		print('%s trains units (TODO does nothing)' % on_turn().leader_id)
		return next(_cont_turn_end)
		
	# pass, interrupt, etc
	return next(_cont_turn_end)
			

## Waits for the battle to finish.
func _cont_wait_for_battle_result() -> void:
	var result: BattleResult = await Game.battle.battle_ended
	match result.value:
		BattleResult.CANCELLED:
			return next(_cont_take_action)
			
		BattleResult.NONE:
			pass
			
		BattleResult.ATTACKER_VICTORY:
			transfer_territory(result.attacker, result.territory)
			result.defender.hp_multiplier = 0.1
			
		BattleResult.DEFENDER_VICTORY:
			result.attacker.hp_multiplier = 0.1
			
		BattleResult.ATTACKER_WITHDRAW:
			pass
			
		BattleResult.DEFENDER_WITHDRAW:
			transfer_territory(result.attacker, result.territory)
	
	# TODO until scene manager is fixed, it had to be done this way
	# clean this up later when milestones have been reached
	if not is_running():
		# wait for battle to finish returning
		await SceneManager.transition_finished
		
	await get_active_overworld_scene().show_battle_result_banner(result)
	
	if result.loser().is_defeated():
		# TODO clean this shit up 
		while result.loser().hero_units.size() > 0:
			var unit_id: int = result.loser().hero_units.pop_front()
			Game.load_unit(unit_id).set_empire(result.winner())
		while result.loser().units.size() > 0:
			var unit_id: int = result.loser().units.pop_front()
			Game.load_unit(unit_id).set_empire(result.winner())

		_defeated_empires.append(result.loser())
		return next(_cont_wait_for_defeat_events)
	else:
		return next(_cont_turn_end)


## Waits for defeat events fo finish.
func _cont_wait_for_defeat_events() -> void:
	empire_defeated.emit(_defeated_empires.back())
	await Game.wait_for_resume()
	if new_event:
		# TODO ugly handling
		var ev := new_event
		new_event = &''
		DialogueEvents.instance().play_event(ev)
		return 
	return next(_cont_turn_end)
	
	
## Ends the turn and emits the signal
func _cont_turn_end() -> void:
	turn_ended.emit(on_turn())
	await Game.wait_for_resume()
	
	if next_turn():
		return next(_cont_cycle_end)
	else:
		return next(_cont_turn_start)


## Ends the current cycle and starts a new one.
func _cont_cycle_end() -> void:
	cycle_ended.emit(_cycle_count)
	await Game.wait_for_resume()

	for defeated in _defeated_empires:
		_active_empires.erase(defeated)
	_cycle_count += 1
	return next(_cont_cycle_start)


####################################################################################################
#endregion Continuations
####################################################################################################


## Advances to the next turn.
func next_turn() -> bool:
	# finds the first valid and active empire
	var valid := 0
	for i in range(_turn_index + 1, _active_empires.size()):
		if _active_empires[i] not in _defeated_empires:
			valid = i
			break
	_turn_index = valid
	return _turn_index == 0


## Basic ai action.
func default_ai_action(empire: Empire) -> Dictionary:
	# boss don't do anything
	if empire.is_boss():
		return {type='pass'}
		
	# if hurt, rest
	if empire.hp_multiplier < 0.8:
		return {type='rest'}
		
	# increase aggression
	empire.aggression += empire.base_aggression + randf()
	
	if empire.aggression >= 1:
		empire.aggression = 0
		var adjacent := empire.get_adjacent(_territories)
		
		# basic sanity check
		if adjacent.is_empty():
			push_warning('empire "%s" has no adjacent territories' % empire.leader_name())
			return {type='rest'}
		
		# attack
		var target: Territory = adjacent.pick_random()
		return {
			type = 'attack',
			attacker = empire,
			defender = get_territory_owner(target),
			territory = target,
			map_id = 0,
		}
		
	# rest
	return {type='rest'}
	
	
## Summons boss.
func summon_boss():
	var connections := ["Forsaken Temple", "Ruins of Atesh", "Nekhet's Rest"]
	for conn in connections:
		connect_territories(_boss_empire.home_territory, get_territory_by_name(conn))
	
	_active_empires.append(_boss_empire)
	get_active_overworld_scene().update_territory_buttons()
	

## Returns true if should summon boss.
func should_summon_boss() -> bool:
	if is_boss_active():
		return false
	for e in _active_empires:
		if e.is_random() and e not in _defeated_empires:
			return false
	return true


## Returns the active overworld scene. Kind of a hack, but yes.
func get_active_overworld_scene() -> OverworldScene:
	assert(is_running(), 'overworld not running!')
	return get_tree().current_scene


## Stops the overworld cycle.
func stop_overworld_cycle() -> void:
	if is_running():
		_state = &''
		get_active_overworld_scene().scene_return()

	
## Returns true if overworld is running.
func is_running() -> bool:
	# a small hack to get the current overworld scene
	return get_tree().current_scene is OverworldScene
	#return SceneManager._scene_stack.back().scene_path == "res://scenes/overworld/overworld_scene.tscn"
	

## Returns an array of all territories.
func territories() -> Array[Territory]:
	return _territories


## Returns an array of all the empires.
func empires() -> Array[Empire]:
	return _empires
	
	
## Returns the player empire.
func player_empire() -> Empire:
	return _player_empire
	
	
## Returns the boss empire.
func boss_empire() -> Empire:
	return _boss_empire
	
	
## Returns a list of all the active empires.
func active_empires() -> Array[Empire]:
	return _active_empires
	
	
## Returns a list of all the defeated empires.
func defeated_empires() -> Array[Empire]:
	return _defeated_empires
	
	
## Returns the number of overworld cycles.
func cycle() -> int:
	return _cycle_count

	
## Returns the empire currently on turn.
func on_turn() -> Empire:
	return _active_empires[_turn_index]
	

## Returns true if the boss is active.
func is_boss_active() -> bool:
	return _boss_empire in _active_empires
	
	
## Returns the empire with the given leader.
func get_empire_by_leader_id(leader_id: StringName) -> Empire:
	for e in _empires:
		if e.leader_id == leader_id:
			return e
	return null
	
	
## Returns the empire with the given leader name.
@warning_ignore("shadowed_variable_base_class")
func get_empire_by_leader_name(name: StringName) -> Empire:
	for e in _empires:
		if e.leader.name == name:
			return e
	return null
	
	
## Returns the territory with the given name.
@warning_ignore("shadowed_variable_base_class")
func get_territory_by_name(name: StringName) -> Territory:
	for t in _territories:
		if t.name == name:
			return t
	return null
	
	
## Returns the owner of the territory.
func get_territory_owner(territory: Territory) -> Empire:
	for e in _empires:
		if territory in e.territories:
			return e
	return null
	
	
## Returns true if territory is a home territory.
func is_home_territory(t: Territory) -> bool:
	for e in _empires:
		if t == e.home_territory:
			return true
	return false
	
	
## Connects two territories, [code]a[/code] and [code]b[/code].
func connect_territories(a: Territory, b: Territory) -> void:
	if not a.is_adjacent(b):
		a.adjacent.append(b.name)
	if not b.is_adjacent(a):
		b.adjacent.append(a.name)
		
		
## Transfers territory to [code]new_owner[/code].
func transfer_territory(new_owner: Empire, territory: Territory) -> void:
	var old_owner := get_territory_owner(territory)
	if old_owner == new_owner:
		return
	
	_transfer_territory(old_owner, new_owner, territory)

	if territory == old_owner.home_territory and Preferences.defeat_if_home_territory_captured:
		while not old_owner.territories.is_empty():
			var t: Territory = old_owner.territories.pop_back()
			_transfer_territory(old_owner, new_owner, t)


func _transfer_territory(old_owner: Empire, new_owner: Empire, territory: Territory):
	assert(territory not in new_owner.territories)
	old_owner.territories.erase(territory)
	new_owner.territories.append(territory)
	territory_owner_changed.emit(old_owner, new_owner, territory)
		

## Replaces the ai action decision function.
## [code]fun[/code] should take no args and return an action dictionary.
## Set to null to use the default decision function.
## This function will not persist between games and have to be set every time.
func set_ai_decision_function(_fun: Variant) -> void:
	if _fun:
		_ai_decision_function = _fun
	else:
		_ai_decision_function = default_ai_action
	
