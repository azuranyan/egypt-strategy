class_name BattleAgentAIv2
extends BattleAgent


var agents := {}


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
	var unit_action_queue: Array[Unit] = []
	for u in battle.get_owned_units(battle.on_turn):
		if not u.has_attacked or not u.has_moved:
			unit_action_queue.append(u)
			
	while not (should_end or unit_action_queue.is_empty()):
		var unit: Unit = unit_action_queue.pop_back()
		var agent := get_agent(unit)
		
		var action := agent.get_action()
		await do_action(do_unit_action, [unit, action])


func get_agent(unit: Unit) -> Agent:
	if unit not in agents:
		match unit.behavior:
			## Always advances towards nearest target and attacks.
			Unit.Behavior.NormalMelee:
				agents[unit] = NormalMeleeAgent.new(Globals.battle, unit)
				
			## Always attacks nearest target, flees adjacent attackers.
			Unit.Behavior.NormalRanged:
				pass
			## Always advances and tries to attack target with lowest HP.
			Unit.Behavior.ExploitativeMelee:
				pass
			## Always tries to attack targets that would not be able to retaliate.
			Unit.Behavior.ExploitativeRanged:
				pass
			## Holds 1 spot and attacks any who approach.
			Unit.Behavior.DefensiveMelee:
				pass
			## Holds 1 spot and attacks any who approach, flees adjacent attackers.
			Unit.Behavior.DefensiveRanged:
				pass
			## Heals allies and self, runs away from attackers.
			Unit.Behavior.SupportHealer:
				pass
			## Aims to inflict as many enemies with negative status as possible, will choose different target if already afflicted.
			Unit.Behavior.StatusApplier:
				pass
	return agents[unit]


func do_unit_action(unit: Unit, action: Action):
	# do nothing
	if unit.cell() == action.cell and not action.attack:
		await battle.unit_action_pass(unit)
		return
		
	# action
	await battle.unit_action_walk(unit, action.cell)
	
	# attack
	if action.attack:
		await battle.unit_action_attack(unit, action.attack, action.target, 0)
	

	
class Action:
	var cell: Vector2
	var attack: Attack
	var target: Vector2
	
	static func move_only(cell: Vector2) -> Action:
		return Action.new(cell, null, cell)
		
	static func move_attack(cell: Vector2, attack: Attack, target: Vector2) -> Action:
		return Action.new(cell, attack, target)
		
	func _init(cell: Vector2, attack: Attack, target: Vector2):
		self.cell = cell
		self.attack = attack
		self.target = target


class Agent:
	# a reference to battle
	var battle: Battle
	
	# the distance when the unit is activated
	var activation_radius: int
	
	# the unit being controlled
	var unit: Unit
	
	
	func _init(battle: Battle, unit: Unit):
		self.battle = battle
		self.unit = unit
		activation_radius = unit.move + unit.get_attack_range(unit.basic_attack) + 2
		
	
	func get_action() -> Action:
		push_error("Needs implementation.")
		return null
		
		
	func get_nearby_enemies(distance: int) -> Array[Unit]:
		return battle.get_units_in_range(unit.map_pos, distance, func(x): return x != unit and unit.is_enemy(x))
		
		
	func get_nearby_allies(distance: int) -> Array[Unit]:
		return battle.get_units_in_range(unit.map_pos, distance, func(x): return x != unit and unit.is_ally(x))
	
	
	func generate_action_list() -> Array[Action]:
		return BattleAgentAIv2.generate_action_list(unit)
		

class NormalMeleeAgent extends Agent:
	
	func get_action() -> Action:
		var enemies: Array[Unit] = battle.map.get_units().filter(unit.is_enemy)
		var nearby: Array[Unit] = []
		
		# unit targeting:
		# closest enemy
		
		# pathing:
		# shortest travel distance to target
		# shortest cell distance to target
		
		# attack targeting:
		# least allies hit
		# most enemies hit
		
		for enemy in enemies:
			if Util.cell_distance(unit.map_pos, enemy.map_pos) < activation_radius:
				nearby.append(enemy)
		
		if nearby.is_empty():
			return Action.move_only(unit.cell())
			
		enemies.sort_custom(custom_compare)
		var target := enemies[0]
		
		var points := {}
		var moves := generate_action_list()
		moves.sort_custom(func(a: Action, b: Action): 
			if a.attack != null and b.attack == null:
				return true
			if a.attack == null and b.attack != null:
				return false
			var pts1 := 0
			var pts2 := 0
			if a.attack and b.attack:
				var ta := unit.get_attack_target_units(a.attack, a.target, 0)
				for t in ta:
					if unit.is_ally(t):
						pts1 -= 3
					else:
						pts1 += 1
				var tb := unit.get_attack_target_units(b.attack, b.target, 0)
				for t in tb:
					if unit == t or unit.is_ally(t):
						pts2 -= 3
					else:
						pts2 += 1
				if pts1 > pts2:
					return true
				elif pts1 < pts2:
					return false
			return Util.cell_distance(a.cell, a.target) < Util.cell_distance(b.cell, b.target)
			)
		
		return moves[0]
			
		
		#
		#var target_pool := enemies if nearby.is_empty() else nearby
		#target_pool.sort_custom(custom_compare)
		#
		#var target := target_pool[0]
		#
		#var moves := generate_action_list()
		#var chosen_move: Action
		#for move in moves:
			#if chosen_move == null:
				#chosen_move = move
			#else:
				#var attack := ((move.attack != null) and (chosen_move.attack == null))
				#var closer := Util.cell_distance(move.cell, move.target) < Util.cell_distance(chosen_move.cell, chosen_move.target)
				#if attack or closer:
					#chosen_move = move
		#return chosen_move
	
		
	func custom_compare(a: Unit, b: Unit) -> bool:
		var a_high_prio := is_high_priority(a)
		var b_high_prio := is_high_priority(b)
		
		if a_high_prio and not b_high_prio:
			return true
		if not a_high_prio and b_high_prio:
			return false
		return Util.cell_distance(unit.map_pos, a.map_pos) < Util.cell_distance(unit.map_pos, b.map_pos)
		
		
	func is_high_priority(u: Unit) -> bool:
		return false
		
	
	
	
	
	
	
	
