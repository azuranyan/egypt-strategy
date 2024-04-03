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
	
			
func _initialize():
	pass
	

func _enter_prepare_units():
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
	end_prepare_units()
		
		
func _exit_prepare_units():
	pass
	

func _enter_turn():
	var unit_action_queue: Array[Unit] = []
	for u in battle.get_owned_units(battle.on_turn):
		if u.can_act():
			unit_action_queue.append(u)
			
	while not unit_action_queue.is_empty():
		var unit: Unit = unit_action_queue.pop_back()
		var agent := get_agent(unit)
		
		await do_unit_action(unit, agent.get_action())
	end_turn()


func _exit_turn():
	pass


func _spawn_unit(cell: Vector2, type_name: String):
	print('  spawning %s at %s' % [type_name, cell])
	var unit := battle.spawn_unit(type_name, empire, type_name, cell) # TODO fix type spawned
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
		
		
func get_agent(unit: Unit) -> Agent:
	if unit not in agents:
		match unit.behavior:
			## Always advances towards nearest target and attacks.
			Unit.Behavior.NormalMelee:
				agents[unit] = NormalMeleeAgent.new(Game.battle, unit)
				
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
	battle.map.pathing_overlay.draw(unit.get_pathable_cells())
	await battle.unit_action_walk(unit, action.cell)
	battle.map.pathing_overlay.clear()
	
	# attack
	if action.attack:
		await battle.unit_action_attack(unit, action.attack, [action.target], [0])
	

class Action:
	var cell: Vector2
	var attack: Attack
	var target: Vector2
	
	static func move_only(_cell: Vector2) -> Action:
		return Action.new(_cell, null, _cell)
		
	static func move_attack(_cell: Vector2, _attack: Attack, _target: Vector2) -> Action:
		return Action.new(_cell, _attack, _target)
		
	func _init(_cell: Vector2, _attack: Attack, _target: Vector2):
		cell = _cell
		attack = _attack
		target = _target


class Agent:
	# a reference to battle
	var battle: Battle
	
	# the distance when the unit is activated
	var activation_radius: int
	
	# the unit being controlled
	var unit: Unit
	
	
	func _init(_battle: Battle, _unit: Unit):
		battle = _battle
		unit = _unit
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
		
		for enemy in enemies:
			if Util.cell_distance(unit.map_pos, enemy.map_pos) < activation_radius:
				nearby.append(enemy)
			
		# if there are no enemy units within activation range, do nothing (heal)
		if nearby.is_empty():
			return Action.move_only(unit.cell())
			
		enemies.sort_custom(custom_compare)
		var target := enemies[0]
		
		# if the enemy is reachable by special attack, do it
		if Util.cell_distance(target.map_pos, unit.map_pos) <= unit.get_attack_range(unit.special_attack):
			# TODO ff avoidance and maximize aoe
			print("using special attack on ", target.map_pos)
			return Action.move_attack(unit.map_pos, unit.special_attack, target.map_pos)
			
		# if the enemy is reachable by basic attack, do it
		if Util.cell_distance(target.map_pos, unit.map_pos) <= unit.get_attack_range(unit.basic_attack):
			# TODO ff avoidance and maximize aoe
			print("using basic attack on ", target.map_pos)
			return Action.move_attack(unit.map_pos, unit.basic_attack, target.map_pos)
			
		# if the enemy is not immediately reachable, pathfind
		var path := unit.pathfind_cell(target.cell())
		return Action.move_only(path[path.size() - 1])
			
		
	func custom_compare(a: Unit, b: Unit) -> bool:
		var a_high_prio := is_high_priority(a)
		var b_high_prio := is_high_priority(b)
		
		if a_high_prio and not b_high_prio:
			return true
		if not a_high_prio and b_high_prio:
			return false
		return Util.cell_distance(unit.map_pos, a.map_pos) < Util.cell_distance(unit.map_pos, b.map_pos)
		
		
	func is_high_priority(_u: Unit) -> bool:
		return false # TODO
		

	
	
	
	
	
	
