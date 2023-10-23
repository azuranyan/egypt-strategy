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

# gather tasks
# generate possible assignments
# sort assignments
# assign task

# move
# attack
func make_move(unit: Unit):
	var enemies := battle.map.get_units().filter(within_activation_range(unit))
	if enemies.is_empty():
		battle.do_nothing(unit)
		return
		
	# pathfind beside target
	var target: Unit = enemies.pick_random()
	var walkable := Util.flood_fill(
		battle.map.cell(unit.map_pos),
		(unit.mov + unit.rng),
		Rect2i(Vector2i.ZERO, battle.map.world.map_size),
		func(x): return Vector2i(x) == battle.map.cell(target.map_pos) or battle.is_placeable(unit, x)
		)
	var pathfinder := PathFinder.new(battle.map.world, walkable)
	var path := pathfinder.calculate_point_path(battle.map.cell(unit.map_pos), battle.map.cell(target.map_pos))
	if path.size() == 0:
		push_error("%s %s can't move towards %s given %s" % [unit.name, battle.map.cell(unit.map_pos), battle.map.cell(target.map_pos), walkable])
	else:
		var actual_path := PackedVector2Array()
		for p in path:
			if  Util.cell_distance(p, unit.map_pos) > unit.mov or \
				Vector2i(p) == battle.map.cell(target.map_pos) or \
				Util.cell_distance(p, target.map_pos) < unit.rng:
				break
			actual_path.append(p)
		await battle._walk_along(unit, actual_path)
	battle.do_nothing(unit)


static func within_activation_range(unit: Unit) -> Callable:
	return func(x): return x.empire != unit.empire and Util.cell_distance(unit.map_pos, x.map_pos) <= (unit.mov + unit.rng)
	
