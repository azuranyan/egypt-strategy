extends BattleAgent
class_name BattleAgentAI


## Returns a list of all possible moves.
static func generate_action_list(unit: Unit) -> Array[Action]:
	var re: Array[Action] = []
	for p in Globals.battle.get_walkable_cells(unit):
		if Globals.battle.is_placeable(unit, p):
			re.append(Action.move_only(p))
			re.append_array(generate_move_attack_action(unit, p, unit.unit_type.basic_attack))
			re.append_array(generate_move_attack_action(unit, p, unit.unit_type.special_attack))
	return re
	

## Returns a list of all possible move attack in a cell.
static func generate_move_attack_action(unit: Unit, cell: Vector2i, attack: Attack) -> Array[Action]:
	var re: Array[Action] = []
	
	if attack:
		# hack: temp move unit to future position
		var pos := unit.map_pos
		unit.map_pos = cell
		
		# add all possible attack locations
		for target in Globals.battle.get_targetable_cells(unit, attack):
			if Globals.battle.check_use_attack(unit, attack, target, 0) == Battle.ATTACK_OK:
				re.append(Action.move_attack(cell, attack, target))
		
		# hack: restore unit position
		unit.map_pos = pos
	return re
	

## Pathfinds to a cell but considers unit move.
static func pathfind_cell(unit: Unit, end: Vector2i) -> PackedVector2Array:
	# get walkable cells
	var start: Vector2i = Globals.battle.map.cell(unit.map_pos)
	
	var walkable := Util.flood_fill(start, 99, Util.world_bounds(), func(x): return Vector2i(x) == end or Globals.battle.is_pathable(unit, x))
	
	# pathfind
	var pathfinder := PathFinder.new(Globals.battle.map.world, walkable)
	var long_path := pathfinder.calculate_point_path(start, end)
	
	# cut path by mov and range
	for i in long_path.size():
		var p: Vector2i = long_path[i]
		if Util.cell_distance(p, start) > unit.mov:# or not Globals.battle.is_placeable(unit, p):
			return long_path.slice(0, i)
	return long_path
	
	
var unit_action_queue: Array[Unit]


func prepare_units():
	print('Agent is preparing units.')
	var spawnable: Array[String] = empire.units.duplicate()
	
	# fill spawn points
	for spawn_point in battle.map.get_spawn_points("ai"):
		if spawnable.is_empty():
			break
			
		# get the unit type to spawn
		var type_name: String
		if battle.map.get_object_at(spawn_point).has_meta("spawn_unit"):
			var spawn_unit = battle.map.get_object_at(spawn_point).get_meta("spawn_unit")
			if spawn_unit not in spawnable:
				push_warning("spawn_unit '%s' not in spawnable" % spawn_unit)
				continue
			else:
				type_name = spawn_unit
		else:
			type_name = spawnable.pick_random()
		
		# remove from spawnable list
		spawnable.erase(type_name)
		
		# spawn unit
		var unit := battle.spawn_unit(type_name, empire, "", spawn_point)
		print('  spawning %s at %s' % [type_name, spawn_point])
		
		# make it face towards the closest spawn point
		var p_spawn := battle.map.get_spawn_points("player")
		var closest := Map.OUT_OF_BOUNDS
		var closest_dist := -1
		while not p_spawn.is_empty():
			var v := p_spawn[-1]
			var v_dist := spawn_point.distance_squared_to(v)
			if closest == Map.OUT_OF_BOUNDS or v_dist < closest_dist:
				closest = v
				closest_dist = int(v_dist)
			p_spawn.remove_at(p_spawn.size() - 1)
			
		unit.face_towards(closest)


func do_turn():
	unit_action_queue = []
	for u in battle.get_owned_units():
		if battle.can_move(u) or battle.can_attack(u):
			unit_action_queue.append(u)
			
	while not (should_end or unit_action_queue.is_empty()):
		var unit: Unit = unit_action_queue.pick_random()
		
		var all_actions := generate_action_list(unit)
		
		# evaluate and prune moves
		var actions: Array[Action] = []
		var weights := PackedFloat32Array()
		var chances := PackedFloat32Array()
		var weight_sum := 0.0
		for action in all_actions.duplicate():
			var weight := evaluate(unit, action)
			if weight > 0.0:
				weight_sum += weight
				weights.append(weight)
				chances.append(weight_sum)
				actions.append(action)
				
		# weighted selection
		print('Doing action ', unit.unit_name)
		var roll := randf_range(0.0, weight_sum)
		var action: Action = null
		for i in actions.size():
			print('  %.1f (%3d%%): %s' % [weights[i], int(weights[i]/weight_sum*100), actions[i]])
			
		for i in actions.size():
			if roll <= chances[i]:
				action = actions[i]
				break
		
		assert(action)
		print('  ', battle.map.cell(unit.map_pos), ' Choosing ', action)
		
		await do_action(do_unit_action, [unit, action])
	
	
## Actually performs the move.
func do_unit_action(unit: Unit, action: Action):
	# do nothing
	if battle.map.cell(unit.map_pos) == action.cell and not action.attack:
		battle.do_nothing(unit)
		return
		
	# action
	await battle._walk_along(unit, pathfind_cell(unit, action.cell))
	battle.set_can_move(unit, false)
	
	# attack
	if action.attack:
		await battle.use_attack(unit, action.attack, action.target, 0)
		battle.set_can_attack(unit, false)
	
	battle.set_action_taken(unit, true)
	

## Returns the weight of an action.
func evaluate(unit: Unit, move: Action) -> float:
	## TODO TODO TODO tune ai
	if battle.map.cell(unit.map_pos) == move.cell and not move.attack:
		return 2.0 # do nothing (recover 1 hp)
		
	var v := 1.0
	var nearest_enemy: Unit = null
	var nearest_ally: Unit = null
	var nearest_enemy_dist := 9999
	var nearest_ally_dist := 9999
	for u in battle.get_units():
		var dist := Util.cell_distance(move.cell, u.map_pos)
		if u.empire == empire:
			if dist < nearest_enemy_dist:
				nearest_enemy = u
				nearest_enemy_dist = dist
		else:
			if dist < nearest_ally_dist:
				nearest_ally = u
				nearest_ally_dist = dist
				
	# move towards enemy
	v += (Util.cell_distance(unit.map_pos, nearest_enemy.map_pos) - nearest_enemy_dist)*0.8
	
	# move towards ally
	v += (Util.cell_distance(unit.map_pos, nearest_ally.map_pos) - nearest_ally_dist)*0.2
	
	if move.attack:
		var hints := move.attack.get_effect_hints()
		var targets := battle.get_attack_target_units(unit, move.attack, move.target)
		
		if 'attack' in hints:
			var amt := 0.0
			for eff in move.attack.effects:
				if eff is FlatDamageEffect:
					amt += eff.amount
				elif eff is StatDamageEffect:
					amt += eff.flat_damage + eff.multiplier * unit.get(eff.stat)
			
			for u in targets:
				var dmg := minf(u.hp, amt)
				v += dmg*(1 + dmg/u.maxhp) # damage
				if amt >= u.hp:
					v += u.maxhp*6.9 # kill
			
		if 'cc' in hints:
			v += 5 * targets.size() # crowd control
			
		if 'debuff' in hints:
			v += 4 * targets.size() # add debuff
			
		if 'dispel' in hints:
			v += 2 * targets.size() # remove buffs
			
		if 'heal' in hints:
			var amt := 0.0
			for eff in move.attack.effects:
				if eff is FlatHealEffect:
					amt += eff.amount
				elif eff is StatHealEffect:
					amt += eff.flat_damage + eff.multiplier * unit.get(eff.stat)
			
			for u in targets:
				var heal := minf(u.maxhp - u.hp, amt)
				v += heal*3 if heal > 0 else -amt*3 # heal
			
		if 'buff' in hints:
			v += 5 * targets.size() # add buffs
			
		if 'cleanse' in hints:
			v += 3 * targets.size() # remove debuff
	
	return v
	
	
class Action:
	var cell: Vector2i
	var attack: Attack
	var target: Vector2i
	
	static func move_only(cell: Vector2i) -> Action:
		return Action.new(cell, null, cell)
		
	static func move_attack(cell: Vector2i, attack: Attack, target: Vector2i) -> Action:
		return Action.new(cell, attack, target)
		
	func _init(_cell: Vector2i, _attack: Attack, _target: Vector2i):
		cell = _cell
		attack = _attack
		target = _target

	func _to_string() -> String:
		if attack:
			return 'Action %s + %s %s' % [cell, attack.name, target]
		else:
			return 'Action %s' % cell

