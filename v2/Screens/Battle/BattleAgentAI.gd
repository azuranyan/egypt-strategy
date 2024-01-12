extends BattleAgent
class_name BattleAgentAI


## Returns a list of all possible moves.
static func generate_action_list(unit: Unit) -> Array[Action]:
	var re: Array[Action] = []
	for p in unit.get_pathable_cells():
		if unit.is_placeable(p):
			re.append(Action.move_only(p))
			re.append_array(generate_move_attack_action(unit, p, unit.basic_attack))
			re.append_array(generate_move_attack_action(unit, p, unit.special_attack))
	return re
	

## Returns a list of all possible move attack in a cell.
static func generate_move_attack_action(unit: Unit, cell: Vector2, attack: Attack) -> Array[Action]:
	var re: Array[Action] = []
	
	if attack:
		for targettable in unit.get_attack_range_cells(attack):
			if unit.check_use_attack(attack, targettable, 0) == Unit.ATTACK_OK:
				re.append(Action.move_attack(cell, attack, targettable))
	return re
	
	
var unit_action_queue: Array[Unit]


func prepare_units():
	print('Agent is preparing units.')
	var spawnable: Array[String] = empire.units.duplicate()
	var spawned_leader := false
	
	for spawn_point in battle.map.get_spawn_points("ai"):
		if spawnable.is_empty():
			break
		
		if not spawned_leader:
			_spawn_unit(spawn_point.cell(), empire.leader.name)
			spawned_leader = true
		
		var type_name: String
		if spawn_point.spawn_list.is_empty():
			type_name = spawnable.pick_random()
		else:
			var spawn_unit := spawn_point.spawn_list[randi_range(0, spawn_point.spawn_list.size() - 1)]
			if spawn_unit not in spawnable:
				push_warning("spawn_unit '%s' not in spawnable" % spawn_unit)
				continue
			else:
				type_name = spawn_unit
				
		_spawn_unit(spawn_point.cell(), type_name)
		
		spawnable.erase(type_name)
		

func _spawn_unit(cell: Vector2, type_name: String):
	print('  spawning %s at %s' % [type_name, cell])
	var unit := battle.spawn_unit("res://Screens/Battle/map_types/unit/Unit.tscn", empire, type_name, cell) # TODO fix type spawned
	unit.face_towards(_get_closest_player_spawn_point(cell))
	
	
func _get_closest_player_spawn_point(cell: Vector2) -> Vector2:
	var spawn_points := battle.map.get_spawn_points("player")
	var closest := Vector2(999, 999)
	var closest_dist := -1.0
	while not spawn_points.is_empty():
		var sp: SpawnPoint = spawn_points.pop_back()
		var dist := sp.map_pos.distance_squared_to(cell)
		if closest == Vector2(999, 999) or dist < closest_dist:
			closest = sp.map_pos
	return closest
		

func do_turn():
	should_end = false
	unit_action_queue = []
	for u in battle.get_owned_units(battle.on_turn):
		if not u.has_attacked or not u.has_moved:
			unit_action_queue.append(u)
			
	while not (should_end or unit_action_queue.is_empty()):
		var unit: Unit = unit_action_queue.pick_random()
		unit_action_queue.erase(unit)
		
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
		print('Doing action ', unit.display_name)
		var roll := randf_range(0.0, weight_sum)
		var action: Action = null
		for i in actions.size():
			print('  %.1f (%3d%%): %s' % [weights[i], int(weights[i]/weight_sum*100), actions[i]])
			
		for i in actions.size():
			if roll <= chances[i]:
				action = actions[i]
				break
		
		assert(action)
		print('  ', unit.cell(), ' Choosing ', action)
		
		await do_action(do_unit_action, [unit, action])
	
	
## Actually performs the move.
func do_unit_action(unit: Unit, action: Action):
	# do nothing
	if unit.cell() == action.cell and not action.attack:
		#battle.do_nothing(unit)
		print(unit, " do nothing")
		return
		
	# action
	#await battle._walk_along(unit, pathfind_cell(unit, action.cell))
	print(unit, " move")
	unit.has_moved = true
	
	# attack
	if action.attack:
		#await battle.use_attack(unit, action.attack, action.target, 0)
		print(unit, " attack")
		unit.has_attacked = true
		
	unit.has_taken_action = true
	

## Returns the weight of an action.
func evaluate(unit: Unit, move: Action) -> float:
	## TODO TODO TODO tune ai
	if unit.cell() == move.cell and not move.attack:
		return 2.0 # do nothing (recover 1 hp)
		
	var v := 1.0
	var nearest_enemy: Unit = null
	var nearest_ally: Unit = null
	var nearest_enemy_dist := 9999
	var nearest_ally_dist := 9999
	for u in battle.map.get_units():
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
	if nearest_enemy:
		v += (Util.cell_distance(unit.map_pos, nearest_enemy.map_pos) - nearest_enemy_dist)*0.8
	
	# move towards ally
	if nearest_ally:
		v += (Util.cell_distance(unit.map_pos, nearest_ally.map_pos) - nearest_ally_dist)*0.2
	
	if move.attack:
		var hints := move.attack.get_effect_hints()
		var targets := unit.get_attack_target_units(move.attack, move.target, 0)
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
	var cell: Vector2
	var attack: Attack
	var target: Vector2
	
	static func move_only(cell: Vector2) -> Action:
		return Action.new(cell, null, cell)
		
	static func move_attack(cell: Vector2, attack: Attack, target: Vector2) -> Action:
		return Action.new(cell, attack, target)
		
	func _init(_cell: Vector2, _attack: Attack, _target: Vector2):
		cell = _cell
		attack = _attack
		target = _target

	func _to_string() -> String:
		if attack:
			return 'Action %s + %s %s' % [cell, attack.name, target]
		else:
			return 'Action %s' % cell

