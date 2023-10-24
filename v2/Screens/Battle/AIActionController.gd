extends BattleActionController

var battle: Battle
var empire: Empire




## Initializes the controller. Called once every battle start.
func initialize(_battle: Battle, _empire: Empire) -> void:
	battle = _battle
	empire = _empire
	
	
## Called when action has to be executed.
func do_action() -> void:
	# make move
	for u in battle.map.get_units().filter(func(x): return x.empire == empire):
		print('can do shit? ', u)
		if battle.can_move(u) or battle.can_attack(u):
			print('  aight tryna do shit ', u)
			await make_move(u)
			print('  done widda shit ', u)
			break
	
	# should end once not a single unit can do any action
	var should_end := true
	for u in battle.map.get_units().filter(func(x): return x.empire == empire):
		print('can still do shit? ', u)
		if battle.can_move(u) or battle.can_attack(u):
			print('ye men ', u)
			should_end = false
			break
			
	if should_end:
		print('done widda turn')
		battle.end_turn()
	
	
## Called when turn starts.
func turn_start() -> void:
	battle.cursor.visible = false
	

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
	var roll := randf_range(0.0, weight_sum)
	var move: Move = null
	for i in moves.size():
		print('  %.3f%% %s' % [weights[i]/weight_sum*100, moves[i]])
		
	for i in moves.size():
		if roll <= chances[i]:
			print('  rolled %s for %s' % [roll, moves[i]])
			move = moves[i]
			break
	
	assert(move)
	print('  ', battle.map.cell(unit.map_pos), ' Choosing ', move)
	battle.unit_path.initialize(battle.get_walkable_cells(unit))
	battle.unit_path.draw(battle.map.cell(unit.map_pos), move.cell)
	await battle._walk_along(unit, pathfind_cell(unit, move.cell))
	battle.unit_path.stop()
	
	if move.attack:
		await battle.use_attack(unit, move.attack, move.target, 0)
		
	print('  Done')
	# pathfind beside target
	battle.do_nothing(unit)


func evaluate(unit: Unit, move: Move) -> float:
	if move.attack:
		return 10.0
	
	if battle.map.cell(unit.map_pos) == move.cell:
		return 5.0
		
	return -1.0
	

static func categorize(unit: Unit, move: Move) -> int:
	return 0


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
		if Util.cell_distance(p, start) > unit.mov or not Globals.battle.is_placeable(unit, p):
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
			if Globals.battle.can_use_attack(unit, attack, target, 0) == Battle.ATTACK_OK:
				re.append(Move.move_attack(cell, attack, target))
		
		# hack: restore unit position
		unit.map_pos = pos
	return re

	
class Move:
	var cell: Vector2i
	var attack: Attack
	var target: Vector2i
	
	static func move_only(_cell: Vector2i) -> Move:
		return Move.new(_cell, null, _cell)
		
	static func move_attack(_cell: Vector2i, _attack: Attack, _target: Vector2i) -> Move:
		return Move.new(_cell, _attack, _target)
		
	func _init(_cell: Vector2i, _attack: Attack, _target: Vector2i):
		cell = _cell
		attack = _attack
		target = _target

	func _to_string() -> String:
		if attack:
			return 'Move to %s and use %s on %s' % [cell, attack.name, target]
		else:
			return 'Move to %s' % cell
