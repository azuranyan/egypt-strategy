extends Control
class_name Overworld


# A special signal awaited to continue
signal player_choose_action(action: Array)


enum {
	NULL_ACTION,
	REST_ACTION,
	ATTACK_ACTION,
	TRAIN_ACTION,
}

## Returns a special null action.
static func empire_null_action() -> Array:
	return [NULL_ACTION]
	

## Returns a rest action.
static func empire_rest_action() -> Array:
	return [REST_ACTION]
	
	
## Returns an attack action.
static func empire_attack_action(territory: Territory) -> Array:
	return [ATTACK_ACTION, territory]
	
	
## Returns a train action.
static func empire_train_action(territory: Territory) -> Array:
	return [TRAIN_ACTION, territory]
	
	
class Context:
	# counts the number of turn cycles that have passed
	var turn_cycles: int

	# initial turn order
	var initial_turn_order: Array[Empire]

	# the turn queue
	var turn_queue: Array[Empire]

	# the empire currently taking their turn
	var on_turn: Empire

	# flag to indicate end
	var should_end := false


var context: Context

	
# Called when the node enters the scene tree for the first time.
func _ready():
	register_territories_to_globals()
	
	register_empires_to_globals()
		
	# connect overworld events TODO remove and stick spawn to where it should be
	OverworldEvents.connect("all_territories_taken", spawn_boss)
	
	do_cycle.call_deferred()
	

## Starts the overworld main loop.
func do_cycle():
	context = Context.new()
	
	# initialize turn order
	context.initial_turn_order.append(Globals.empires['Lysandra'])
	for ename in Globals.empires:
		if ename != 'Lysandra' and ename != 'Sitri':
			context.initial_turn_order.append(Globals.empires[ename])
			
	# do the cycle
	while not context.should_end:
		OverworldEvents.cycle_start.emit()
		
		# start the turns
		context.turn_queue = context.initial_turn_order.duplicate()
		while not context.turn_queue.is_empty():
			# should_end is checked before the start of a new turn
			if context.should_end:
				break
				
			context.on_turn = context.turn_queue.pop_front()
			
			# skip eliminated empires - we do it this way because 
			# empires can be defeated while the queue is on going
			if context.on_turn.get_meta('Overworld_manager_eliminated', false):
				continue
				
			# allow scene to play before the start of a turn
			await _play_scene_insert()
			
			OverworldEvents.cycle_turn_start.emit(context.on_turn)
		
			var action := await _get_turn_action(context.on_turn)
			await _execute_action(context.on_turn, action)
			
			# allow scene to play after the end of a turn
			await _play_scene_insert()
			
		OverworldEvents.cycle_end.emit()
		context.turn_cycles += 1
	

## Removes the empire from the turn order.
func remove_from_turn_order(empire: Empire):
	empire.set_meta('Overworld_manager_eliminated', true)
	
		
## Plays queued insert scenes.
func _play_scene_insert():
	# do the scene queue
	while !Globals.scene_queue.is_empty():
		var scn: String = Globals.scene_queue.pop_front()
		
		# emit signal to start scene
		OverworldEvents.cycle_scene_start.emit(scn)
		
		# wait for the signal to end scene
		await OverworldEvents.cycle_scene_end
		

## Returns the action taken by the empire.
func _get_turn_action(empire: Empire) -> Array:
	if empire.is_player_owned():
		# unlock ui
		$MouseEventBlocker.visible = false
		
		# wait for action to be chosen
		var player_action: Array = await player_choose_action
		
		# lock ui
		$MouseEventBlocker.visible = true
		return player_action
	else:
		# add artificial wait time
		await get_tree().create_timer(1.0).timeout
		
		# if empire is hurt, rest
		if empire.hp_multiplier < 0.8:
			return empire_rest_action()
		
		# increase aggression rating
		empire.aggression += empire.base_aggression + randf()
		
		# attack if aggression hits 1, else rest
		if empire.aggression >= 1.0:
			empire.aggression = 0
			return empire_attack_action(empire.get_adjacent().pick_random())
		else:
			return empire_rest_action()
		
		
## Executes given action for empire.
func _execute_action(empire: Empire, action: Array):
	match action[0]:
		REST_ACTION:
			if empire.is_player_owned():
				print("%s rests. HP recovered." % empire.leader.name)
			else:
				print("%s rests. HP recovered (aggression: %s)" % [empire.leader.name, empire.aggression])
				
			empire.hp_multiplier = 1.0
			
		ATTACK_ACTION:
			var territory: Territory = action[1]
			var attacker: Empire = empire
			var defender: Empire = territory.empire
			print("%s attacks %s (%s)!" % [attacker.leader.name, territory.name, defender.leader.name])
			
			# TODO show transition/loading screen
			# TODO show objectives
			
			self.visible = false
			# call deferred because we're awaiting for signal
			Globals.battle.start_battle.call_deferred(attacker, defender, territory)
			var result = await Globals.battle.battle_ended
			self.visible = true
			
			match result:
				Battle.Result.Cancelled:
					print("Attacker cancelled.")
					context.turn_queue.push_front(empire)
					
				Battle.Result.AttackerRequirementsError:
					print("Attacker does not meet requirements")
					context.turn_queue.push_front(empire)
					
				Battle.Result.None:
					push_error("Invalid battle result: None")
					
				Battle.Result.AttackerVictory:
					print("Attacker Withdraw. Battle lost!")
					_attacker_victory(empire, territory)
					defender.hp_multiplier = 0.1
					
				Battle.Result.DefenderVictory:
					print("Attacker Withdraw. Battle lost!")
					attacker.hp_multiplier = 0.1
					
				Battle.Result.AttackerWithdraw:
					print("Attacker Withdraw. Battle lost!")
					
				Battle.Result.DefenderWithdraw:
					print("Attacker Withdraw. Battle lost!")
					_attacker_victory(empire, territory)
					
		TRAIN_ACTION:
			print('%s trains units (TODO does nothing)')
	

func _attacker_victory(empire: Empire, territory: Territory):
	print("territory taken!")
	var old_owner := territory.empire
	
	# change owners
	territory_set_owner(territory, empire)
	
	# if home_territory, give the rest to the winning empire
	if Globals.prefs['defeat_if_home_territory_captured'] and territory == old_owner.home_territory:
		print("    home territory is captured!")
		while !old_owner.territories.is_empty():
			var t: Territory = old_owner.territories.pop_back()
			print("        surrendering %s" % t.name)
			territory_set_owner(t, empire)
			
	# remove from the pool if needed
	if old_owner.is_beaten():
		print("%s is defeated!" % old_owner.leader.name)
		
		if old_owner.is_player_owned():
			print("player defeated, game uber")
		else:
			if old_owner.leader.get_meta("final_boss", false):
				# boss
				print("boss defeated, congerets")
				OverworldEvents.emit_signal("boss_defeated")
			else:
				# normal enemy
				update_boss_spawn_condition()
			remove_from_turn_order(old_owner)
		

func update_boss_spawn_condition():
	for t in Globals.territories.values():
		if t.get_leader() != Globals.chara["Sitri"] and !t.is_player_owned():
			return
	
	OverworldEvents.emit_signal("all_territories_taken")
	
		
func spawn_boss():
	# TODO await boss spawn animation
	# TODO spawn boss directly
	$TerritoryButton10.visible = true
	
	connect_territories(Globals.territories["Cursed Stronghold"], Globals.territories["Ruins of Atesh"])
	
	context.initial_turn_order.append(Globals.empires["Sitri"])
	

## Connects two territories together
func connect_territories(a: Territory, b: Territory):
	if b not in a.adjacent:
		a.adjacent.append(b)
	if a not in b.adjacent:
		b.adjacent.append(a)


## Adds the territories to the global registry.
func register_territories_to_globals():
	Globals.territories.clear()
	for c in get_children():
		if c is TerritoryButton:
			Globals.territories[c.territory.name] = c.territory
			

## Assign territories and adds the empires to the global registry
func register_empires_to_globals():
	Globals.empires.clear()
	
	_register_new_empire(Globals.chara["Lysandra"], Globals.territories["Zetennu"])
	_register_new_empire(Globals.chara["Sitri"], Globals.territories["Cursed Stronghold"])
	
	var selection: Array[Chara] = []
	for c in Globals.chara.values():
		if c.get_meta("territory_selection", false):
			selection.append(c)
			
	selection.shuffle()
	# var i := 0
	for t in Globals.territories.values():
		if t.empire == null:
			# t.empire = _register_new_empire(selection[i], t)
			# i = (i + 1) % selection.size()
			assert(not selection.is_empty(), 'not enough charas for territories')
			t.empire = _register_new_empire(selection.pop_back(), t)


func _register_new_empire(leader: Chara, home_territory: Territory) -> Empire:
	var empire := Empire.new()
	empire.leader = leader
	empire_give_territory(null, empire, home_territory, true)
	Globals.empires[leader.name] = empire
	return empire
	

## Sets the owner of the territory to a different empire.
func territory_set_owner(territory: Territory, new_empire: Empire):
	if territory.empire != new_empire:
		empire_give_territory(territory.empire, new_empire, territory)
		
	
## Gives a territory to another empire.
func empire_give_territory(from_empire: Empire, to_empire: Empire, territory: Territory, home_territory: bool=false):
	assert(to_empire != null, "to_empire can't be null")
	# take
	if from_empire != null:
		from_empire.territories.erase(territory)
		for unit in territory.units:
			from_empire.units.erase(unit)
	
	# give
	to_empire.territories.append(territory)
	to_empire.units.append_array(territory.units)
	
	# assign home if needed
	if home_territory:
		assert(to_empire.home_territory == null, "home_territory set multiple times")
		to_empire.home_territory = territory
		
	# change owner
	territory.empire = to_empire
	
	# broadcast
	OverworldEvents.territory_owner_changed.emit(from_empire, to_empire, territory)
	
