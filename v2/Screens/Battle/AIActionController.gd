extends BattleActionController

var battle: Battle
var empire: Empire

var unit_action_queue: Array[Unit]


## Initializes the controller. Called once every battle start.
func initialize(_battle: Battle, _empire: Empire) -> void:
	battle = _battle
	empire = _empire
	
	
## Called when action has to be executed.
func do_action() -> void:
	if not unit_action_queue.is_empty():
		await make_move(unit_action_queue.pop_front())
	else:
		battle.end_turn()
		
	
## Called when turn starts.
func turn_start() -> void:
	battle.cursor.visible = false
	unit_action_queue.clear()
	for u in battle.get_owned_units():
		if battle.can_move(u) or battle.can_attack(u):
			unit_action_queue.append(u)
	

## Called when turn ends.
func turn_end() -> void:
	battle.cursor.visible = true

	
## Called when action is started.
func action_start() -> void:
	pass
	

## Called when action is ended.
func action_end() -> void:
	pass

################################################################################

class UnitAI:
	enum Movement {
		# Unit actively chases enemies.
		Chase,
		
		# Unit holds position.
		Hold,
		
		# Unit flees when targeted.
		Flee,
		
		# Tries to stay away from enemies targeting range.
		Escape,
	}
	
	enum Targeting { Closest, Random, Weakest, Strongest, }
	
	enum Aggression {
		Active,
		Passive,
		Distance,
	}
	
	enum Skillset {
		Damage,
		Recover,
	}

	
func make_move(unit: Unit):
	var all_moves := generate_move_list(unit)
	
	# evaluate and prune moves
	var moves: Array[Move] = []
	var weights := PackedFloat32Array()
	var chances := PackedFloat32Array()
	var weight_sum := 0.0
	for move in all_moves.duplicate():
		var weight := evaluate(unit, move)
		if weight > 0.0:
			weight_sum += weight
			weights.append(weight)
			chances.append(weight_sum)
			moves.append(move)
	
	# weighted selection
	print('Doing action ', unit.unit_name)
	var roll := randf_range(0.0, weight_sum)
	var move: Move = null
	for i in moves.size():
		print('  %.1f (%3d%%): %s' % [weights[i], int(weights[i]/weight_sum*100), moves[i]])
		
	for i in moves.size():
		if roll <= chances[i]:
			move = moves[i]
			break
	
	assert(move)
	print('  ', battle.map.cell(unit.map_pos), ' Choosing ', move)
	
	# do nothing
	if battle.map.cell(unit.map_pos) == move.cell and not move.attack:
		battle.do_nothing(unit)
		return
		
	# move
	battle.unit_path.initialize(battle.get_walkable_cells(unit))
	battle.unit_path.draw(battle.map.cell(unit.map_pos), move.cell)
	await battle._walk_along(unit, pathfind_cell(unit, move.cell))
	battle.unit_path.stop()
	battle.set_can_move(unit, false)
	
	# attack
	if move.attack:
		await battle.use_attack(unit, move.attack, move.target, 0)
		battle.set_can_attack(unit, false)
		
	battle.set_action_taken(unit, true)

	

func evaluate(unit: Unit, move: Move) -> float:
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
	

#func get_utility(v: float, unit: Unit, tag: String, args: Array) -> float:
#	match tag:
#		'do_nothing':
#		'damage':
#		'kill':
#		'cc':
#			return v + 5 * args[0]
#		'debuff':
#			return v + 4 * args[0]
#		'dispell':
#			return v + 2 * args[0]
#		'heal':
#			return v + 3 * args[0]
#		'buff':
#			return v + 5 * args[0]
#		'cleanse':
#			return v + 3 * args[0]
#		'enemy_distance':
#			return v + (Util.cell_distance(unit.map_pos, args[0]) - args[1])*0.8
#		'ally_distance':
#			return v + (Util.cell_distance(unit.map_pos, args[0]) - args[1])*0.2
#		_:
#			return 1.0

	

## Returns a lambda that returns true if a unit is within activation range of the given unit. 
static func within_activation_range(unit: Unit) -> Callable:
	# TODO get empire activation range modifier
	return func(x): return x.empire != unit.empire and Util.cell_distance(unit.map_pos, x.map_pos) <= (unit.mov + unit.rng)
	

## Returns a path from unit to target, stopping when the target is within range.
static func pathfind_unit(unit: Unit, target: Unit) -> PackedVector2Array:
	# get walkable cells
	var start: Vector2i = Globals.battle.map.cell(unit.map_pos)
	var end: Vector2i = Globals.battle.map.cell(target.map_pos)
	var walkable := Util.flood_fill(start, 99, Util.world_bounds(), func(x): return Vector2i(x) == end or Globals.battle.is_placeable(unit, x))
	
	# pathfind
	var pathfinder := PathFinder.new(Globals.battle.map.world, walkable)
	var long_path := pathfinder.calculate_point_path(start, end)
	
	# cut path by mov and range
	for i in long_path.size():
		var p: Vector2i = long_path[i]
		if Util.cell_distance(p, start) > unit.mov or Util.cell_distance(p, end) < unit.rng or Vector2i(p) == end:
			return long_path.slice(0, i)
	return long_path
	
	
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


static func generate_move_list(unit: Unit) -> Array[Move]:
	var re: Array[Move] = []
	for p in Globals.battle.get_walkable_cells(unit):
		if Globals.battle.is_placeable(unit, p):
			re.append(Move.move_only(p))
			re.append_array(generate_attack_move(unit, p, unit.unit_type.basic_attack))
			re.append_array(generate_attack_move(unit, p, unit.unit_type.special_attack))
	return re
	

static func generate_attack_move(unit: Unit, cell: Vector2i, attack: Attack) -> Array[Move]:
	var re: Array[Move] = []
	
	if attack:
		# hack: temp move unit to future position
		var pos := unit.map_pos
		unit.map_pos = cell
		
		# add all possible attack locations
		for target in Globals.battle.get_targetable_cells(unit, attack):
			if Globals.battle.check_use_attack(unit, attack, target, 0) == Battle.ATTACK_OK:
				re.append(Move.move_attack(cell, attack, target))
		
		# hack: restore unit position
		unit.map_pos = pos
	return re

	
class Move:
	var cell: Vector2i
	var attack: Attack
	var target: Vector2i
	
	static func move_only(cell: Vector2i) -> Move:
		return Move.new(cell, null, cell)
		
	static func move_attack(cell: Vector2i, attack: Attack, target: Vector2i) -> Move:
		return Move.new(cell, attack, target)
		
	func _init(_cell: Vector2i, _attack: Attack, _target: Vector2i):
		cell = _cell
		attack = _attack
		target = _target

	func _to_string() -> String:
		if attack:
			return 'Move %s + %s %s' % [cell, attack.name, target]
		else:
			return 'Move %s' % cell
