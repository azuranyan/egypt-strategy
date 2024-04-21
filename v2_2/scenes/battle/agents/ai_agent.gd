extends BattleAgent


## Decides what the main objective of the ai should be.
class GrandCPU:
	enum {
		DO_NOTHING,
		AGGRESSIVE,
		REACT,
		SURVIVE,
	}
	


class StrategyCPU:
	enum {
		TARGET,
	}


static func action_attack_target(unit: Unit, target: Unit, attack: Attack) -> Dictionary:
	return {}


static func action_attack_nearest_target() -> Dictionary:
	return {}


# https://www.reddit.com/r/fireemblem/comments/167bnhz/comment/jyoutfv/
class UnitCPU:
	enum {
		IDLE,
		ATTACK,
		GUARD,

	}

	enum Aggro {
		ACTIVE,
		PASSIVE,
		NEUTRAL,
	}

	var unit: Unit ## A reference to the controlled unit.
	var state: int

	var deify_meter: float ## If > 1, will be able to use deify.
	var should_deify: bool ## This will be true if unit should unleash deify when possible.

	var allow_movement: bool = true ## Whether this unit is allowed to move.
	var allow_fight: bool = true ## Whether this unit is allowed to use the first (normal) attack.
	var allow_diefy: bool = true ## Whether this unit is allowed to use the special (diefy) attack.
	var allow_heal: bool = true ## Allows this unit to heal, if it has healing capabilities.
	var allow_flee: bool = true ## Allows this unit to retreat for self preservation.

	var aggro: Aggro = Aggro.ACTIVE ## Whether this unit
	var aggro_range: int = 999
	var aggro_group: int = 0


	func reset_action_state() -> void:
		should_deify = false


	func get_nearest_enemy() -> Unit:
		var cell := unit.get_position()
		var nearest_target: Unit
		var nearest_dist: float
		for tid: int in Game.unit_registry:
			var t: Unit = Game.unit_registry[tid]
			if not unit.is_enemy(t):
				continue
			var tdist := Util.cell_distance(cell, t.get_position())
			if nearest_dist == null or tdist < nearest_dist:
				nearest_target = t
				nearest_dist = tdist
		return null


	func target_within_range(target: Unit, attack: Attack, assumed_position := Map.OUT_OF_BOUNDS) -> bool:
		var pos := assumed_position if assumed_position != Map.OUT_OF_BOUNDS else target.get_position()
		return pos in unit.attack_range_cells(attack)


	func get_action() -> UnitAction:
		var a := UnitAction.new()

		a.is_move = target_location != Map.OUT_OF_BOUNDS
		a.cell = target_location

		a.is_attack = target_attack != null
		a.attack = target_attack
		a.target = target_units[0].get_position()
		a.rotation = target_rotation


	## Returns the unit action for this unit.
	func choose_action() -> void:
		reset_action_state()

		if unit.can_act():
			if action_behavior_override():
				return

			if action_behavior_specific():
				return

			if action_default_behavior():
				return

		# fallback action is to do nothing
		Battle.instance().unit_action_pass(unit)

		
	## Action overrides.
	func action_behavior_override() -> bool:
		if deify_meter > 1.0:
			
		# check if attack is a buff (assume self-targeted attacks are buffs)
		if unit.special_attack().target_flags & Attack.TARGET_SELF:
			if Util.find_nearest_enemy(unit).get_position() in unit.special_attack().get_cells_in_range(
		# can i use either attack to buff me up first?
		if unit.basic_attack().target_flags & Attack.TARGET_SELF:

		# does using buff make it good for the situation?
		return false


	## The default behavior when no specific one is found.
	func action_default_behavior() -> bool:
		return false


	## Returns behavior-specific action.
	func action_behavior_specific() -> bool:
		match unit.get_behavior():
			Unit.Behavior.NORMAL_MELEE: return action_normal_melee()
			Unit.Behavior.NORMAL_RANGED: return action_normal_ranged()
			Unit.Behavior.EXPLOITATIVE_MELEE: return action_exploitative_melee()
			Unit.Behavior.EXPLOITATIVE_RANGED: return action_exploitative_ranged()
			Unit.Behavior.DEFENSIVE_MELEE: return action_defensive_melee()
			Unit.Behavior.DEFENSIVE_RANGED: return action_defensive_ranged()
			Unit.Behavior.SUPPORT_HEALER: return action_support_healer()
			Unit.Behavior.STATUS_APPLIER: return action_status_applier()
			_, Unit.Behavior.PLAYER_CONTROLLED: return false


	## Always advances towards nearest target and attacks.
	func action_normal_melee() -> bool:
		var took_action: bool = false
		var t := get_nearest_enemy()
		if t:
			# TODO special attack

			# move towards the target if we have to
			if unit.can_move():
				if target_within_range(t, unit.basic_attack()):
					pass # we're already in range so do nothing
				else:
					var nearest_attack_position := unit.pathfind_to(t.get_position())
					Battle.instance().unit_action_move(unit, nearest_attack_position[-1])
					took_action = true

			# attack if possible
			if unit.can_attack():
				if unit.basic_attack().is_multicast():
					pass # TODO: multicast attack
				else:
					
					# TODO if can use attack check
					# TODO battle - use attack add melee face target feature *actually make it so all features
					# are implemented in battle itself instead of relying on the agents

					Battle.instance().unit_action_attack(unit, unit.basic_attack(), [t.get_position()], [0.0])
					took_action = true
					
		return took_action


	## Always attacks nearest target, flees adjacent attackers.
	func action_normal_ranged() -> bool:
		var took_action: bool = false
		var t := Util.find_nearest_enemy(unit)
		if t:
			# TODO special attack

			# move towards the target if we have to
			if unit.can_move():
				if Util.cell_distance(unit.get_position(), t.get_position()) == 1:
					pass # TODO pathfind to furthest reachable attack spot
				elif target_within_range(t, unit.basic_attack()):
					pass # we're already in range so do nothing
				else:
					var nearest_attack_position := unit.pathfind_to(t.get_position())
					Battle.instance().unit_action_move(unit, nearest_attack_position[-1])
					took_action = true

			# attack if possible
			if unit.can_attack():
				if unit.basic_attack().is_multicast():
					pass # TODO: multicast attack
				else:
					Battle.instance().unit_action_attack(unit, unit.basic_attack(), [t.get_position()], [0.0])
					took_action = true

		return took_action
	

	## Always advances and tries to attack target with lowest HP.
	func action_exploitative_melee() -> bool:
		# try to attack move to lowest hp
			# if possible, do that
			# else, attack normally
		return false
	

	## Always tries to attack targets that would not be able to retaliate.
	func action_exploitative_ranged() -> bool:
		return null
	

	## Holds 1 spot and attacks any who approach.
	func action_defensive_melee() -> bool:
		return null
	
	## Holds 1 spot and attacks any who approach, flees adjacent attackers.
	func action_defensive_ranged() -> bool:
		return null

	
	## Heals allies and self, runs away from attackers.
	func action_support_healer() -> bool:
		return null
	

	## Aims to inflict as many enemies with negative status as possible, will choose different target if already afflicted.
	func action_status_applier() -> bool:
		return null
		

# targeting
# favor guaranteed kills
# prioritize based on damage dealt, if possible take into account accuracy and crit hits
# factor in attacks from other units such that if x is killed if n units attack it
# prune 0 damage and 0% hits (exceptions are debuffs)
# dont do pointless stuff like silence non magic users

# movement
# stand still
# move when aggroed
# group linked aggro
# on trigger

# self preservation
# avoid taking high counterattack damage
# retreat when low hp




@export var action_cooldown: float = 0.3
var battle: Battle

var action_order: Array[Unit]
var action_queue: Array[Dictionary]



## Evaluates the game state and queues the actions for each unit.
func refresh_action_queue() -> void:
	action_queue.clear()

	evaluate_game_state()
	queue_unit_actions()

	Battle.instance().hud().action_order_list.clear_units()
	for d in action_queue:
		Battle.instance().hud().action_order_list.add_unit(d.unit)




## Allows the cpu to re-evaluate the state of the game and come up with strategies.
func evaluate_game_state() -> void:
	# relative force strength
	# how well the units support each other
	# how large area you threaten
	# how many units are threatened
	# 
	# check if we're winning or losing thru objectives
	# adjust grand strategy accordingly
	# issue strategies to squads
	pass


## Pushes actions to the action queue.
func queue_unit_actions() -> void:
	# how do you optimize the order of the unit actions
	pass

	
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
