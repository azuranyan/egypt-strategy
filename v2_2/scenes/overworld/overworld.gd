class_name Overworld extends Node
## The overworld interface.

const OVERWORLD_SCENE := preload("res://scenes/overworld/overworld_scene.tscn")

enum {
	NO_ERROR = 0,
	SCENE_LOADING_FAILED,
	NO_HOME_TERRITORY_SET,
	HOME_TERRITORY_NOT_FOUND,
	MULTIPLE_HOME_TERRITORY,
	NO_PLAYER_EMPIRE,
	NO_BOSS_EMPIRE,
	MULTIPLE_PLAYER_EMPIRES,
	MULTIPLE_BOSS_EMPIRES,
	ISOLATED_TERRITORY,
	CANNOT_CREATE_HERO_UNIT,
	CANNOT_CREATE_UNIT,
}

@export_range(0.0, 10.0) var enemy_action_delay: float

var _territories: Array[Territory]
var _boss_adjacent_territories: Array[Territory]
var _empires: Array[Empire]
var _player_empire: Empire
var _boss_empire: Empire

var _active_empires: Array[Empire]
var _defeated_empires: Array[Empire]
var _cycle: int
var _turn_queue: Array[Empire]
var _next_state: StringName
var _new_event: StringName

var _overworld_scene: Node
var _initialized: bool
var _should_end: bool
var _should_reload: bool
var _is_running: bool

var _ai_decision_function: Callable


static func instance() -> Overworld:
	return Game.overworld


func _ready():
	# register us to the game core logic group
	add_to_group(Game.GAME_EVENT_LISENERS_GROUP)

	set_ai_decision_function(null)
	
	OverworldEvents.empire_defeated.connect(_check_boss_summon)
	OverworldEvents.boss_summoned.connect(func(_a, _b): _should_reload = true)
	DialogueEvents.new_event_unlocked.connect(_notify_new_event)
	SceneManager.scene_ready.connect(_on_scene_ready)
	

## Returns the active overworld scene. Kind of a hack, but yes.
func get_active_overworld_scene() -> OverworldScene:
	return _overworld_scene


## Returns true if the overworld is initialized.
func is_initialized() -> bool:
	return _initialized


func _set_initialized(initialized: bool) -> void:
	if _initialized == initialized:
		return
	_initialized = initialized
	if _initialized:
		print('Overworld initialized')
		print_stack()
	else:
		print('Overworld uninitialized')
		print_stack()


## Loads in a new state.
func load_new_state() -> int:
	_set_initialized(false)
	var node := OVERWORLD_SCENE.instantiate()

	if not node is OverworldScene:
		node.queue_free()
		return SCENE_LOADING_FAILED

	add_child(node)
	var err := _load_from_scene(node)
	node.free()
	if err != NO_ERROR:
		return err

	_active_empires = [_player_empire]
	for e in _empires:
		if e.is_random():
			_active_empires.append(e)
	_defeated_empires = []
	_cycle = 0
	_reload_turn_queue()
	_next_state = 'cycle_start'

	_should_end = false
	_should_reload = false
	_is_running = false

	_new_event = ''
	
	_set_initialized(true)
	return NO_ERROR


func _load_from_scene(scene: OverworldScene) -> int:
	var err: int
	var distributed_territories: Array[Territory] = []

	err = _load_territories(scene, distributed_territories)
	if err != NO_ERROR:
		return err

	err = _load_empires(scene, distributed_territories)
	if err != NO_ERROR:
		return err

	for empire in _empires:
		if not empire.home_territory:
			continue
		err = _create_empire_units(empire)
		if err != NO_ERROR:
			return err
		update_force_rating(empire)

	return NO_ERROR


func _load_territories(scene: OverworldScene, distributed_territories: Array[Territory]) -> int:
	_territories = []
	for node in scene.get_territory_nodes():
		# create territory
		var t := Territory.new()
		t.name = node.name
		for adj in node.adjacent:
			t.adjacent.append(adj.name)
		t.maps = node.maps.duplicate()
		t.units = node.get_unit_entries()

		# add territory
		_territories.append(t)
		if node.connect_to_boss:
			_boss_adjacent_territories.append(t)
		distributed_territories.append(t)

	return NO_ERROR


func _load_empires(scene: OverworldScene, distributed_territories: Array[Territory]) -> int:
	_empires = []
	for node in scene.get_empire_nodes():
		# load home territory
		if not node.home_territory:
			push_error('"%s" included in Empires, but has no home territory set. Maybe put it in RandomEmpires?' % node.name)
			return NO_HOME_TERRITORY_SET
		
		var home_territories := _territories.filter(func(t): return t.name == node.home_territory.name)
		if home_territories.size() == 0:
			push_error('Territory "%s" not found.' % node.home_territory.name)
			return HOME_TERRITORY_NOT_FOUND

		elif home_territories.size() > 1:
			push_error('Multiple home territories for "%s"' % node.name)
			return MULTIPLE_HOME_TERRITORY

		# create empire
		var empire := _create_empire_from_node(node)
		var err := _add_empire(empire)
		if err != NO_ERROR:
			return err

		# set home territory
		empire.home_territory = home_territories[0]
		empire.territories = [empire.home_territory]
		distributed_territories.erase(empire.home_territory)

	# make sure player and boss empires are present
	if not _player_empire:
		return NO_PLAYER_EMPIRE
	if not _boss_empire:
		return NO_BOSS_EMPIRE

	return _distribute_territories(scene, distributed_territories)


func _distribute_territories(scene: OverworldScene, distributed_territories: Array[Territory]) -> int:
	if distributed_territories.is_empty():
		return NO_ERROR

	var selection: Array[Empire] = []
	var empire_nodes := scene.get_random_empire_nodes()

	# create the selection of random empires
	while not empire_nodes.is_empty() and selection.size() < distributed_territories.size():
		# pick random empire (node)
		var node: EmpireNode = empire_nodes.pick_random()
		empire_nodes.erase(node)

		# create empire and add to selection
		var empire := _create_empire_from_node(node)
		var err := _add_empire(empire)
		if err != NO_ERROR:
			return err
		selection.append(empire)

	# every empire gets their home territory
	selection.shuffle()
	for empire in selection:
		# pick random territory
		var rand: Territory = distributed_territories.pick_random()
		distributed_territories.erase(rand)

		# set home territory
		empire.home_territory = rand
		empire.territories = [rand]

	# the rest will be distributed randomly
	while not distributed_territories.is_empty():
		# shuffle empire selection
		selection.shuffle()

		for empire in selection:
			# pick a random territory from adjacent territories
			var adjacent := distributed_territories.filter(empire.is_adjacent_territory)
			if adjacent.is_empty():
				continue

			var rand: Territory = adjacent.pick_random()
			distributed_territories.erase(rand)

			# assign to empire
			empire.territories.append(rand)

	return NO_ERROR


func _create_empire_from_node(node: EmpireNode) -> Empire:
	var e := Empire.new()
	e.type = node.type
	e.leader_id = node.leader_id # TODO put leader_id in leader
	e.leader = node.leader
	e.base_aggression = node.base_aggression
	e.aggression = node.base_aggression
	return e


func _add_empire(empire: Empire) -> int:
	if empire.is_player_owned():
		if _player_empire:
			return MULTIPLE_PLAYER_EMPIRES
		_player_empire = empire

	if empire.is_boss():
		if _boss_empire:
			return MULTIPLE_BOSS_EMPIRES
		_boss_empire = empire

	_empires.append(empire)

	return NO_ERROR


func _create_empire_units(empire: Empire) -> int:
	if not Game.create_unit(empire, empire.leader_id):
		return CANNOT_CREATE_HERO_UNIT
		
	# creates all units in all territories for n times.
	for t in empire.territories:
		for chara_id in t.units:
			for i in t.units[chara_id]:
				if not Game.create_unit(empire, chara_id):
					return CANNOT_CREATE_UNIT
	OverworldEvents.empire_unit_list_updated.emit(empire, Game.get_empire_units(empire, Game.ALL_UNITS_MASK))
	return NO_ERROR


## Reloads the turn queue.
func _reload_turn_queue():
	_turn_queue = [_player_empire]
	# for weird transition period where active empires are not flushed yet
	for e in _active_empires:
		if e != _player_empire and e not in _defeated_empires:
			_turn_queue.append(e)


## Called when it's time to save.
func save_state() -> Dictionary:
	return 	{
		territories = _territories.duplicate(),
		boss_adjacent_territories = _boss_adjacent_territories.duplicate(),
		empires = _empires.duplicate(),
		player_empire = _player_empire,
		boss_empire = _boss_empire,

		active_empires = _active_empires.duplicate(),
		defeated_empires = _defeated_empires.duplicate(),
		cycle = _cycle,
		turn_queue = _turn_queue.duplicate(),
		next_state = _next_state,
		new_event = _new_event,
	}


## Called when it's time to load.
func load_state(data: Dictionary):
	_set_initialized(false)
	_territories.assign(data.territories)
	_boss_adjacent_territories.assign(data.boss_adjacent_territories)
	_empires.assign(data.empires)
	_player_empire = data.player_empire
	_boss_empire = data.boss_empire

	_active_empires.assign(data.active_empires)
	_defeated_empires.assign(data.defeated_empires)
	_cycle = data.cycle
	_turn_queue.assign(data.turn_queue)
	_next_state = data.next_state
	_new_event = data.new_event

	_should_end = false
	_should_reload = false
	_is_running = false
	_set_initialized(true)


## Called when the scene is ready. This small function is what ties the scene manager and overworld together.
## When the overworld scene is loaded, this automatically launches our main loop.
func _on_scene_ready(node: Node) -> void:
	# this will make it so it's null when a diff scene is loaded
	_overworld_scene = node as OverworldScene

	# important to check if we're already running cos we may have been paused
	# and waiting for the stack to return to our scene
	if _overworld_scene and not is_running():
		_overworld_main.call_deferred()


func _overworld_main() -> void:
	assert(is_initialized())
	_is_running = true
	while not _should_end:
		if _should_reload:
			SceneManager.load_new_scene(SceneManager.scenes.overworld, 'fade_to_black')
			await SceneManager.transition_finished
			_should_reload = false

		match _next_state:
			# Just reloads the turn queue and sends the signal.
			'cycle_start':
				_reload_turn_queue()
				OverworldEvents.cycle_started.emit(cycle())
				_next_state = 'turn_start'

			# Waits for the action and executes it.
			# If action is cancelled, we can go back to this point to do the action again.
			'turn_start':
				OverworldEvents.turn_started.emit(on_turn())

				# wait for action
				var action: Dictionary
				if on_turn().is_player_owned():
					action = await OverworldEvents.player_action_chosen
				else:
					action = await Game.delay_function(_ai_decision_function, enemy_action_delay, [on_turn()])

				print(action)
				# execute action
				match action.type:
					'attack':
						if Game.settings.show_marching_animations:
							await get_active_overworld_scene().show_marching_animation(action.attacker, action.defender, action.territory)
						BattleEvents.start_battle_requested.emit(action.attacker, action.defender, action.territory, action.map_id)
						_next_state = 'wait_for_battle_result'

					'rest':
						on_turn().hp_multiplier = 1.0
						_next_state = 'turn_end'

					'train':
						print('TODO train')
						_next_state = 'turn_end'
					
					'strategy':
						SceneManager.call_scene(SceneManager.scenes.strategy_room, 'fade_to_black', {inspect_mode=true})
						await OverworldEvents.strategy_room_closed
						_next_state = 'turn_start'

					_:
						_next_state = 'turn_end'

			# This is a separate state so we can go back here when we close or reload
			# while the battle is ongoing.
			'wait_for_battle_result':
				var result: BattleResult = await BattleEvents.battle_ended

				# TODO workaround, we wait for the transition because battle no longer waits for it
				if SceneManager.is_loading():
					await SceneManager.transition_finished

				if result.value == BattleResult.CANCELLED:
					_next_state = 'turn_start'

				elif result.value == BattleResult.NONE:
					_next_state = 'turn_end'

				else:
					# evaluate the results here so it doesn't get reexecuted later
					match result.value:
						BattleResult.ATTACKER_VICTORY:
							transfer_territory(result.attacker, result.territory)
							result.defender.hp_multiplier = 0.1
							
						BattleResult.DEFENDER_VICTORY:
							result.attacker.hp_multiplier = 0.1
							
						BattleResult.ATTACKER_WITHDRAW:
							pass
							
						BattleResult.DEFENDER_WITHDRAW:
							transfer_territory(result.attacker, result.territory)

					_next_state = 'post_turn'

			# A special state right after the battle end that waits for the event to finish.
			# This makes it so the player can choose a different strategy room scene, however
			# new events will not be skipped and still be forced to play.
			'post_turn':
				if _new_event:
					_next_state = 'process_new_event'
				else:
					var allow_strategy_room := on_turn().is_player_owned() and _new_event.is_empty()
					var strategy_room: bool = await get_active_overworld_scene().show_battle_result_banner(Battle.instance().get_battle_result(), allow_strategy_room)

					if strategy_room:
						SceneManager.call_scene(SceneManager.scenes.strategy_room, 'fade_to_black', {inspect_mode=false})
						var event_id: StringName = await OverworldEvents.strategy_room_closed

						await SceneManager.transition_finished
						
						if event_id:
							DialogueEvents.start_event_requested.emit(event_id)
							await DialogueEvents.event_ended

					_next_state = 'turn_end'
				
			# Immediately processes the new event and waits for it to end.
			# Abandoning the game here will cause it to return to this point and restart
			# the event.
			'process_new_event':
				assert(not _new_event.is_empty(), 'no new event to process!')
				DialogueEvents.start_event_requested.emit(_new_event)
				await DialogueEvents.event_ended
				_new_event = ''
				_next_state = 'turn_end'

			# Ends the turn.
			'turn_end':
				OverworldEvents.turn_ended.emit(on_turn())
				_turn_queue.pop_front()
				if _turn_queue.is_empty():
					_next_state = 'cycle_end'
				else:
					_next_state = 'turn_start'

			# Turns over to the next cycle.
			'cycle_end':
				OverworldEvents.cycle_ended.emit(_cycle)
				_cycle += 1
				_next_state = 'cycle_start'

			var st:
				push_error('invalid state "%s"' % st)
				_should_end = true

		# necessary to avoid infinite loop even on accident
		await get_tree().process_frame
	_is_running = false
	_set_initialized(false)


## Returns true if overworld is running.
func is_running() -> bool:
	return _is_running
	
	
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
	return _cycle
	

## Returns the empire currently on turn.
func on_turn() -> Empire:
	return _turn_queue.front()
	

## Returns true if the boss is active.
func is_boss_active() -> bool:
	return boss_empire() in active_empires()
	
	
## Returns the empire with the given leader.
func get_empire_by_leader_id(leader_id: StringName) -> Empire:
	for e in empires():
		if e.leader_id == leader_id:
			return e
	return null
	
	
## Returns the empire with the given leader name.
func get_empire_by_leader_name(leader_name: StringName) -> Empire:
	for e in empires():
		if e.leader.name == leader_name:
			return e
	return null


## Returns a standardized value of empire's force rating.
func calculate_empire_force_rating(empire: Empire) -> float:
	return _calculate_total_stat_value(empire, 'maxhp') + _calculate_total_stat_value(empire, 'dmg')


func _calculate_total_stat_value(e: Empire, stat: StringName) -> float:
	var units := Game.get_empire_units(e, Game.ALL_UNITS_MASK)
	if units.is_empty():
		return 0
	return units.map(func(u): return u.get_stat(stat)).reduce(func(a, b): return a + b)


## Returns the territory with the given name.
func get_territory_by_name(territory_name: StringName) -> Territory:
	for t in territories():
		if t.name == territory_name:
			return t
	return null
	
	
## Returns the owner of the territory.
func get_territory_owner(territory: Territory) -> Empire:
	for e in _empires:
		if territory in e.territories:
			return e
	return null
	
	
## Returns true if territory is a home territory.
func is_home_territory(territory: Territory) -> bool:
	for e in _empires:
		if territory == e.home_territory:
			return true
	return false

	
## Connects two territories, [code]a[/code] and [code]b[/code].
func connect_territories(a: Territory, b: Territory) -> void:
	var a_changed := not a.is_adjacent(b)
	var b_changed := not b.is_adjacent(a)
	if a_changed:
		a.adjacent.append(b.name)
	if b_changed:
		b.adjacent.append(a.name)
	if a_changed or b_changed:
		_emit_adjacency_events(a, b)


func _emit_adjacency_events(a: Territory, b: Territory) -> void:
	var a_owner := get_territory_owner(a)
	var b_owner := get_territory_owner(b)

	OverworldEvents.territory_adjacency_changed.emit(a, a_owner)
	OverworldEvents.territory_adjacency_changed.emit(b, b_owner)

	OverworldEvents.empire_adjacency_updated.emit(a_owner, a_owner.get_adjacent(_territories))
	if a_owner != b_owner:
		OverworldEvents.empire_adjacency_updated.emit(b_owner, b_owner.get_adjacent(_territories))

	
## Transfers territory to [code]new_owner[/code].
func transfer_territory(new_owner: Empire, territory: Territory) -> void:
	var old_owner := get_territory_owner(territory)
	if old_owner == new_owner:
		return

	_transfer_territory(old_owner, new_owner, territory)

	if territory == old_owner.home_territory and Game.settings.defeat_if_home_territory_captured:
		while not old_owner.territories.is_empty():
			var t: Territory = old_owner.territories.pop_back()
			_transfer_territory(old_owner, new_owner, t)

	if old_owner.territories.is_empty():
		for u in Game.get_empire_units(old_owner, Game.ALL_UNITS_MASK):
			transfer_unit(u, new_owner)
		update_force_rating(old_owner)
		update_force_rating(new_owner)
		set_empire_defeated(old_owner)

	OverworldEvents.empire_adjacency_updated.emit(new_owner, new_owner.get_adjacent(_territories))

	
func _transfer_territory(old_owner: Empire, new_owner: Empire, territory: Territory):
	assert(territory not in new_owner.territories)
	old_owner.territories.erase(territory)
	new_owner.territories.append(territory)
	OverworldEvents.territory_owner_changed.emit(territory, old_owner, new_owner)
		

## Returns the empires total force.
func calculate_empire_force_total(empire: Empire) -> float:
	var empire_units := Game.get_empire_units(empire, Game.ALL_UNITS_MASK)
	return empire_units.map(func(u): return u.get_stat('maxhp') + u.get_stat('dmg')).reduce(func(a, b): return a + b, 0)
	

## Updates the empire's force rating ([code]total_force/player_force[/code] rating).
func update_force_rating(empire: Empire) -> void:
	if empire == _player_empire:
		empire.force_rating = 1
	else:
		var empire_total := calculate_empire_force_total(empire)
		var player_total := calculate_empire_force_total(_player_empire)
		empire.force_rating = empire_total/player_total
	OverworldEvents.empire_force_rating_updated.emit(empire, empire.force_rating)


## Transfers unit ownership.
func transfer_unit(unit: Unit, new_owner: Empire) -> void:
	var old_owner := unit.get_empire()
	unit.set_empire(new_owner)
	if old_owner:
		OverworldEvents.empire_unit_list_updated.emit(old_owner, Game.get_empire_units(old_owner, Game.ALL_UNITS_MASK))
	if new_owner:
		OverworldEvents.empire_unit_list_updated.emit(new_owner, Game.get_empire_units(new_owner, Game.ALL_UNITS_MASK))
	

## Puts the empire in the defeated list.
func set_empire_defeated(empire: Empire) -> void:
	if not empire in _active_empires or empire in _defeated_empires:
		return 
	
	_defeated_empires.append(empire)
	_active_empires.erase(empire)
	OverworldEvents.empire_defeated.emit(empire)


## Replaces the ai action decision function.
## [code]fun[/code] should take no args and return an action dictionary.
## Set to null to use the default decision function.
## This function will not persist between games and have to be set every time.
func set_ai_decision_function(fun: Variant) -> void:
	if fun:
		_ai_decision_function = fun
	else:
		_ai_decision_function = default_ai_action

		
## The default ai action. Needs to be replaced for custom behaviour.
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
	

func _notify_new_event(ev: StringName) -> void:
	_new_event = ev


func _check_boss_summon(_empire: Empire) -> void:
	if is_boss_active():
		# why are we even here, just skedaddle
		OverworldEvents.empire_defeated.disconnect(_check_boss_summon)
		return

	# don't summon until everyone else is defeated
	for e in _active_empires:
		if e.is_random():
			return
	
	# summon boss
	_active_empires.append(_boss_empire)
	for t in _boss_adjacent_territories:
		connect_territories(t, _boss_empire.home_territory)
	OverworldEvents.boss_summoned.emit(_boss_empire, _boss_empire.home_territory)
