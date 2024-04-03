extends BattleAgent


@export var action_cooldown: float = 0.3
var battle: Battle

var action_order: Array[Unit]

	
## Called on initialize.
func _initialize():
	battle = Game.battle # fucking bastard refuse to show autocomplete for this
	BattleEvents.cycle_started.connect(_on_cycle_started)


func _on_cycle_started(_cycle: int):
	# TODO polish action order

	# determine action order
	action_order = []
	for u in Game.get_empire_units(empire):
		if u.can_act():
			action_order.append(u)

	Battle.instance().hud().action_order_list.clear_units()
	for u in action_order:
		Battle.instance().hud().action_order_list.add_unit(u)


## Called on start preparation.
func _enter_prepare_units():
	print('Agent is preparing units.')
	var spawnables: Array[Unit] = Game.get_empire_units(empire, Game.ALL_UNITS_MASK)
	var spawn_points := Game.battle.get_spawn_points(SpawnPoint.Type.ENEMY)
	
	var spawn_unit := func(u: Unit, sp: SpawnPoint):
		u.set_position(sp.map_position)
		u.face_towards(_get_closest_player_spawn_point(sp.map_position))
		spawnables.erase(u)
		spawn_points.erase(sp)
	
	# spawn the leader unit somewhere
	var leader_unit: Unit = null
	for u in spawnables:
		if u.chara() == empire.leader:
			leader_unit = u
			break
			
	if leader_unit:
		spawn_unit.call(leader_unit, spawn_points.pick_random())
	else:
		push_error('cannot spawn leader %s: not found in roster' % empire.leader)
		
	# spawn the rest of them
	while not spawn_points.is_empty() and not spawnables.is_empty():
		spawn_unit.call(spawnables.pick_random(), spawn_points.pick_random())
		
	end_prepare_units()
	
	
func _get_closest_player_spawn_point(cell: Vector2) -> Vector2:
	var pos := battle.get_spawn_points(SpawnPoint.Type.PLAYER)
	if pos.is_empty():
		return Vector2.ZERO
	pos.sort_custom(func(a, b): return Util.is_closer(a.map_position, b.map_position, cell))
	return pos[0].map_position
	
	
## Called on turn start.
@warning_ignore("redundant_await")
func _enter_turn():
	while not action_order.is_empty():
		var unit: Unit = action_order.pop_back()
		
		var action := make_action_for(unit)
		await battle.do_action(unit, action)
		await get_tree().create_timer(action_cooldown).timeout
	end_turn()
	
	
func make_action_for(unit: Unit) -> UnitAction:
	var list := Game.battle.generate_actions(unit)
	return list.pick_random()
