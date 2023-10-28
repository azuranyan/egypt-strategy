@tool
extends Control
class_name Battle

################################################################################

## Emitted when battle is started.
signal battle_started(attacker, defender, territory)

## Emitted when battle ended.
signal battle_ended(result)

## Emitted when turn cycle starts.
signal turn_cycle_started

## Emitted when turn cycle ends.
signal turn_cycle_ended

## Emitted when an empire's turn starts.
signal turn_started

## Emitted when an empire's turn ends.
signal turn_ended

## Emitted during an empire's turn before it starts an action.
signal action_started

## Emitted during an empire's turn after the action is taken.
signal action_ended

################################################################################

## Emitted when a unit is selected.
signal message_displayed(message)

## Emitted when a cell is selected.
signal cell_selected(cell: Vector2i)

## Emitted when a cell is accepted.
signal cell_accepted(cell: Vector2i)

## Emitted when a unit is selected.
signal unit_selected(unit: Unit)

## Emitted when a unit starts walking.
signal walking_started(unit: Unit)

## Emitted when a unit finishes walking.
signal walking_finished(unit: Unit)

## Emitted when an attack sequence has started.
signal attack_sequence_started(unit: Unit, attack: Attack, target: Vector2i, targets: Array[Unit])

## Emitted when an attack sequence has ended.
signal attack_sequence_ended(unit: Unit, attack: Attack, target: Vector2i, targets: Array[Unit])

################################################################################

signal prep_cancelled

signal prep_done

signal battle_quit

################################################################################

signal _attack_sequence_finished()

signal _end_attack_sequence_requested()

signal _end_battle_requested(result)

signal _end_prep_requested(result)


## The result of the battle.
enum Result {
	## Attacker cancels before starting the fight.
	Cancelled=-2,
	
	## Attacker cannot fulfill battle requirements.
	AttackerRequirementsError=-1,
	
	## Invalid.
	None=0,
	
	## Attacker wins.
	AttackerVictory,
	
	## Attacker loses.
	DefenderVictory,
	
	## Attacker loses via withdraw.
	AttackerWithdraw,
	
	## Attacker wins via defender withdraw.
	DefenderWithdraw,
}


enum {
	TERRAIN_WHITE,
	TERRAIN_BLUE,
	TERRAIN_GREEN,
	TERRAIN_RED,
}


enum {
	ATTACK_OK = 0,
	ATTACK_NOT_UNLOCKED,
	ATTACK_TARGET_INSIDE_MIN_RANGE,
	ATTACK_TARGET_OUT_OF_RANGE,
	ATTACK_NO_TARGETS,
	ATTACK_INVALID_TARGET,
}


const ATTACK_ERROR_MESSAGE := [
	'Use attack.',
	'Unit has not unlocked this skill yet.',
	'Target is inside minimum range.',
	'Target is out of range.',
	'No targets found.',
	'Invalid target.',
]


const unit_group := [
	'units_standby',
	'units_alive',
	'units_dead',
	'units_ghost',
]


var context: Context

var _allow_quit := false

var _camera_target: MapObject = null
var _should_end_turn: bool

@onready var character_list: CharacterList = $UI/CharacterList

@onready var viewport: Viewport = $SubViewportContainer/Viewport
@onready var map: Map
@onready var camera: Camera2D = $Camera2D
@onready var terrain_overlay: TileMap = $SubViewportContainer/Viewport/TerrainOverlay
@onready var unit_path: UnitPath = $SubViewportContainer/Viewport/UnitPath
@onready var cursor: SpriteObject = $UI/Cursor
@onready var pause_overlay: PauseOverlay = $UI/PauseOverlay

#@onready var ai_action_controller := $AIActionController as BattleActionController
#@onready var player_action_controller := $PlayerActionController as BattleActionController


func _ready():
	set_debug_tile_visible(false)
	
	print("battle ready")
	

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE and context:
			accept_event()
			quit_battle.call_deferred()

	
## Starts a battle between two empires over a territory.
func start_battle(attacker: Empire, defender: Empire, territory: Territory, do_quick: Variant = null):
	# force ourselves to be ready (controllers are set init here, but we're loading in late)
	if not self.is_node_ready():
		self._ready()
		
	# initialize context
	context = Battle.Context.new()
	if attacker.is_player_owned():
		context.player = attacker
		context.ai = defender
	else:
		context.player = defender
		context.ai = attacker
	context.attacker = attacker
	context.defender = defender
	context.territory = territory
	context.result = Battle.Result.None
	context.turns = 0
	context.on_turn = context.attacker
	#context.controller[attacker] = player_action_controller if attacker.is_player_owned() else ai_action_controller
	#context.controller[defender] = player_action_controller if defender.is_player_owned() else ai_action_controller
	context.should_end = false
	context.victory_conditions = [VictoryCondition.new()] # TODO
	
	if fulfills_attack_requirements(attacker, territory):
		# do battle
		battle_started.emit(attacker, defender, territory)
		await Globals.play_queued_scenes()
		
		var should_do_quick := not (attacker.is_player_owned() or defender.is_player_owned())
		if do_quick != null:
			should_do_quick = do_quick
			
		if should_do_quick:
			context.result = await _quick_battle(attacker, defender, territory)
		else:
			context.result = await _real_battle(attacker, defender, territory)
		battle_ended.emit(context.result)
	else:
		# error
		display_message(context.warnings)
		battle_ended.emit(Result.AttackerRequirementsError)
	await Globals.play_queued_scenes()


## Returns true if the attacker can initiate the attack to territory.
func fulfills_attack_requirements(empire: Empire, territory: Territory) -> bool:
	# TODO put battle requirements here
	context.warnings = []
	return true


## Returns true if the attacker fulfills prep requirements over territory.
func fulfills_prep_requirements(empire: Empire, territory: Territory) -> bool:
	# TODO put battle requirements here
	context.warnings = []
	return true


## Request to end battle.
func end_battle(result: Result):
	# TODO this is iffy
	if context:
		context.result = result
		_end_battle_requested.emit(result)
	else:
		push_error("end_battle(): battle not started!")
		

## Quits the battle.
func show_quit_battle() -> bool:
	if not _allow_quit:
		return false
		
	if not context:
		push_error("quit_battle(): battle not started!")
		return false
		
#	var should_end := false
	if not context.battle_phase and context.attacker.is_player_owned():
		return await pause_overlay.show_pause('Return to Overworld?')
	else:
		return await pause_overlay.show_pause('Withdraw?')
	
	
## Quits the battle.
func quit_battle(show_confirm_dialogue := true):
	var should_end: bool
	if show_confirm_dialogue:
		should_end = await show_quit_battle()
	else:
		should_end = true

	if should_end:
		if context.battle_phase:
			battle_quit.emit()
		else:
			prep_cancelled.emit()

	
## Outcome is an implementation detail.
func _quick_battle(attacker: Empire, defender: Empire, territory: Territory) -> Result:
	# TODO randomize or simulate the victor
	return Result.AttackerVictory


## Real battle. 
func _real_battle(attacker: Empire, defender: Empire, territory: Territory) -> Result:
	# pre-battle setup
	Globals.push_screen(self)
	await Globals.screen_ready
	_load_map(territory.maps[0])
	
	var agent := {
		context.attacker: Globals.create_agent_for(context.attacker), 
		context.defender: Globals.create_agent_for(context.defender), 
	}
	
	await agent[context.ai].prepare_units()
		
	# wait for the screen transition before proceeding
	await Globals.transition_finished
	
	# allow the player to prep
	$UI/DonePrep.visible = true
	$UI/CancelPrep.visible = context.attacker.is_player_owned()
	_allow_quit = true
	await agent[context.player].prepare_units()
	_allow_quit = false
	$UI/DonePrep.visible = false
	$UI/CancelPrep.visible = false
	
	if context.result != Result.Cancelled:
		$UI/Battle.visible = true # TODO signalize all ui changes
		_do_battle.call_deferred(agent)
		await _end_battle_requested
		$UI/Battle.visible = false
		
		# show battle results
		var text := ''
		var battle_won := false
		if context.attacker.is_player_owned():
			battle_won = context.result == Result.AttackerVictory or context.result == Result.DefenderWithdraw
			match context.result:
				Result.AttackerVictory:
					text = 'Territory Taken!'
				Result.DefenderVictory:
					text = 'Conquest Failed.'
				Result.AttackerWithdraw:
					text = 'Battle Forfeited.'
				Result.DefenderWithdraw:
					text = 'Enemy Withdraw!'
		else:
			battle_won = context.result == Result.DefenderVictory or context.result == Result.AttackerWithdraw
			match context.result:
				Result.AttackerVictory:
					text = 'Territory Lost.'
				Result.DefenderVictory:
					text = 'Defense Success!'
				Result.AttackerWithdraw:
					text = 'Enemy Withdraw!'
				Result.DefenderWithdraw:
					text = 'Territory Surrendered.'
				
		if text != '':
			var node := preload("res://Screens/Battle/BattleResultsScreen.tscn").instantiate()
			get_tree().root.add_child.call_deferred(node)
			node.text = text
			node.battle_won = battle_won
			await node.animation_finished
			node.queue_free()
			
	# post-battle setup
	for e in agent.values():
		e.queue_free()
	Globals.pop_screen()
	await Globals.transition_finished
	_unload_map()
	
	return context.result


func _do_battle(agent: Dictionary):
	context.battle_phase = true
	
	#context.controller[context.attacker].initialize(self, context.attacker)
	#context.controller[context.defender].initialize(self, context.defender)
	
	for u in map.get_units(): # TODO not here
		u.hp = maxi(1, u.empire.hp_multiplier * u.maxhp)
		
	# loop until battle finishes
	while not context.should_end:
		turn_cycle_started.emit()
		await Globals.play_queued_scenes()
		
		# allow both empires to take their turns
		for empire in [context.attacker, context.defender]:
			# set the empire as the one to take their turn
			context.on_turn = empire
			_should_end_turn = false
			
			for u in get_owned_units():
				# reset move and attack flags
				var stunned: bool = Globals.status_effect['STN'] in u.status_effects
				set_can_move(u, not stunned)
				set_can_attack(u, not stunned)
				set_action_taken(u, stunned)
					
				# tick poison at the very start of turn, should be here so we can 
				# properly evaluate w/l conditions before the turn actually starts
				if Globals.status_effect['PSN'] in u.status_effects:
					damage_unit(u, Globals.status_effect['PSN'], 1)
			
			# things can happen before/after doing any actions so make sure to check first
			if _evaluate_victory_conditions():
				break
			
			# do turn (note that the attacker always attacks first)
			turn_started.emit()
			await Globals.play_queued_scenes()
			#context.controller[context.on_turn].turn_start()
			
			#await _do_turn()
			_allow_quit = true
			await agent[empire].do_turn()
			_allow_quit = false
						
			turn_ended.emit()
			await Globals.play_queued_scenes()
			#context.controller[context.on_turn].turn_end()
			
			# do end-turn tick mechanics
			for u in get_owned_units():
				# recover 1 hp for units that didn't do anything
				if not action_taken(u):
					damage_unit(u, self, -1) 
				
				# tick duration of status effects
				u.tick_status_effects()
			
		turn_cycle_ended.emit()
		await Globals.play_queued_scenes()
		
		# increment number of turns
		context.turns += 1
	$UI/Battle.visible = false # TODO doesn't belong here, signalize this
	
	end_battle(context.result)
		
		
func _load_map(scene: PackedScene):
	print("loading map '%s'" % scene.resource_path)
	map = scene.instantiate() as Map
	
	viewport.add_child(map)
	
	$UI.remove_child(cursor)
	map.add_object(cursor)


func _unload_map():
	print("unloading map")
	map.remove_object(cursor)
	$UI.add_child(cursor)
	
	viewport.remove_child(map)
	
	map.queue_free()
	map = null
	

func _evaluate_victory_conditions() -> bool:
	for c in context.victory_conditions:
		context.result = c.evaluate(self)
		if context.result != Result.None:
			context.should_end = true
			return true
	return false
	
	
## Walks a unit (action).
func walk_unit(unit: Unit, cell: Vector2i):
	walking_started.emit(unit)
	
	var start := map.cell(unit.map_pos)
	var end := cell # TODO unit_path is initialized by player and can't be used by ai
	var path := unit_path._pathfinder.calculate_point_path(start, end)
	await _walk_along(unit, path)
		
	walking_finished.emit(unit)
	
	
## Makes a unit walk along a path (action).
func _walk_along(unit: Unit, path: PackedVector2Array):
	if is_walking(unit):
		stop_walking(unit)
		
	match path.size():
		0, 1:
			pass
		_:
			# initialize driver
			var driver: UnitDriver = preload("res://Screens/Battle/map/UnitDriver.tscn").instantiate()
			driver.unit = unit
			unit.set_meta("Battle_driver", driver)
			$Drivers.add_child(driver)
			
			# run and wait for driver
			await driver.walk_along(path)
			
			# cleanup
			$Drivers.remove_child(driver)
			unit.remove_meta("Battle_driver")
			driver.queue_free()
			
			
func check_use_attack(unit: Unit, attack: Attack, target_cell: Vector2i, target_rotation: float) -> int:
	var cellf := Vector2(target_cell)
	
	# check for bond level
	if attack == unit.unit_type.special_attack and unit.bond < 2:
		return ATTACK_NOT_UNLOCKED
		
	# check for minimum range
	if attack.min_range > 0:
		if cellf in Util.flood_fill(map.cell(unit.map_pos), attack.min_range, Rect2i(Vector2i.ZERO, map.world.map_size)):
			return ATTACK_TARGET_INSIDE_MIN_RANGE
		
	# check for range
	if cellf not in Util.flood_fill(map.cell(unit.map_pos), unit.get_attack_range(attack), Rect2i(Vector2i.ZERO, map.world.map_size)):
		return ATTACK_TARGET_OUT_OF_RANGE
		
	# check for any targets
	var target_cells := get_attack_target_cells(unit, attack, target_cell, target_rotation)
	var targets := get_units().filter(func(u): return Vector2(map.cell(u.map_pos)) in target_cells)
	if targets.is_empty():
		return ATTACK_NO_TARGETS
		
	# check for valid targets
	var has_valid_target := false
	for t in targets:
		var target_flags := attack.get_target_flags()
		if  (target_flags & 1 != 0 and unit.is_enemy(t)) or \
			(target_flags & 2 != 0 and not unit.is_enemy(t)) or \
			(target_flags & 4 != 0 and unit == t):
			has_valid_target = true
			break
	if not has_valid_target: 			# causes the attack to release as long
		return ATTACK_INVALID_TARGET	# even if there are invalid targets
	
	return ATTACK_OK

	
## Unit use attack compatible with multicast.
func use_attack_multicast(unit: Unit, attack: Attack, target_cells: Array[Vector2i], target_rotation: float):
	if target_cells.size() == 1:
		use_attack(unit, attack, target_cells[0], target_rotation)
	else:
		var multicaster := AttackMulticaster.new()
		add_child(multicaster)
		multicaster.use_attack_multicast(unit, attack, target_cells, target_rotation)
		await multicaster.done
		multicaster.queue_free()
	
	
## Unit use attack (action).
func use_attack(unit: Unit, attack: Attack, target_cell: Vector2i, target_rotation: float):
	var target_cells := get_attack_target_cells(unit, attack, target_cell, target_rotation)
	var targets := get_units().filter(func(u): return Vector2(map.cell(u.map_pos)) in target_cells)
	attack_sequence_started.emit(unit, attack, target_cell, targets)
	await get_tree().create_timer(0.2).timeout # added artificial timeouts
	await _attack_sequence_finished
	await get_tree().create_timer(0.4).timeout
	attack_sequence_ended.emit(unit, attack, target_cell, targets)
	

## Do nothing (action). Unit cannot move or attack and is considered as not having any action taken.
func do_nothing(unit: Unit):
	set_can_move(unit, false)
	set_can_attack(unit, false)
	set_action_taken(unit, false)
	
	
## End the current turn.
func end_turn():
	_should_end_turn = true
	
	
## Waits for death animations to play out.
func wait_for_death_animations():
	var should_wait := false
	print('wait for death anim')
	for u in get_tree().get_nodes_in_group('units_dead'):
		print('connecting ', u)
		u.animation_finished.connect(func():
			print('anim done ', u)
			set_unit_position(u, Map.OUT_OF_BOUNDS)
			, CONNECT_ONE_SHOT)
		print('playing anim ', u)
		u.play_animation.call('death')
		should_wait = true
		
	if should_wait: # just estimate
		await get_tree().create_timer(1.4).timeout
		
		
## Notify the game that attack sequence is done.
func notify_attack_sequence_finished():
	# this is done so the methods called from the attack_sequence_started
	# signal can call this function and trigger the notify on the next frame.
	# not doing so will cause us to be stuck because we're still in the same
	# context as the attack_sequence call and have not moved on to the next
	# statement yet aka await for finish.
	_notify_attack_sequence_finished.call_deferred()


func _notify_attack_sequence_finished():
	_attack_sequence_finished.emit()
	
	
################################################################################
# Unit and turn utility functions
################################################################################
	
## Spawns a unit.
func spawn_unit(tag: String, empire: Empire, _name := "", pos := Map.OUT_OF_BOUNDS, heading := Unit.Heading.West) -> Unit:
	assert(empire == context.attacker or empire == context.defender, "owner is neither empire!")	
	var unit := Unit.create(map, {
		world = map.world,
		unit_type = Globals.unit_type[tag],
		empire = empire,
		map_pos = pos,
#		facing = 0,
#		hud = true,
#		color = Color.WHITE,
#		shadow = true,
#		debug = false,
		name = _name if _name != "" else tag,
		heading = heading,
	})
	if pos == Map.OUT_OF_BOUNDS:
		set_unit_group(unit, 'units_standby')
	else:
		set_unit_group(unit, 'units_alive')
	for u in map.get_units(): # TODO not here
		u.hp = maxi(1, u.empire.hp_multiplier * u.maxhp)
	return unit
	

## Returns the unit on cell.
func get_unit(cell: Vector2i) -> Unit:
	for u in get_units():
		if map.cell(u.map_pos) == cell:
			return u
	return null
	
	
## Sets the unit group.
func set_unit_group(unit: Unit, group: String):
	for g in unit_group:
		if g == group:
			unit.add_to_group(g)
			unit.set_meta('Battle_group', g)
		else:
			unit.remove_from_group(g)
	match group:
		'units_standby':
			unit.map_pos = Map.OUT_OF_BOUNDS
		'units_alive':
			pass
		'units_dead':
			pass
		'units_ghost':
			pass
			
			
## Returns units in a given group. Returns all alive units by default.
func get_units(group: String = 'units_alive') -> Array[Unit]:
	var re: Array[Unit] = []
	re.assign(get_tree().get_nodes_in_group(group))
	return re


## Returns units owned by empire.
func get_owned_units(empire: Empire = null, group: String = 'units_alive') -> Array[Unit]:
	if empire:
		return get_units(group).filter(func(x): return x.empire == empire)
	else:
		return get_units(group).filter(func(x): return x.empire == context.on_turn)


## Kills a unit.
func kill_unit(unit: Unit):
	print('kill ', unit.unit_name)
	# TODO play death animation
	set_unit_group(unit, 'units_dead')
	

## Revives a unit.
func revive_unit(unit: Unit, hp: int):
	unit.hp = mini(hp, unit.maxhp)
	set_unit_group(unit, 'units_alive')


## Standby unit.
func standby_unit(unit: Unit):
	set_unit_group(unit, 'units_standby')
	

## Sets unit position.
func set_unit_position(unit: Unit, cell: Vector2i):
	unit.map_pos = cell
	if cell == Map.OUT_OF_BOUNDS:
		standby_unit(unit)
	else:
		if unit.hp > 0:
			set_unit_group(unit, 'units_alive')
		else:
			set_unit_group(unit, 'units_dead')


## Inflict damage upon a unit.
func damage_unit(unit: Unit, source: Variant, amount: int):
	# if unit has block, remove block and set damage to 0
	if Globals.status_effect['BLK'] in unit.status_effects:
		unit.remove_status_effect(Globals.status_effect['BLK'])
		amount = 0
	
	# if unit has vul, increase damage taken by 1 
	if Globals.status_effect['VUL'] in unit.status_effects and amount >= 0:
		# this also increases poison damage which effectively 
		# doubles the damage making it a potent combo
		#amount += 1
		if source != Globals.status_effect['VUL']:
			damage_unit(unit, Globals.status_effect['VUL'], 1)
		
	unit.hp = clampi(unit.hp - amount, 0, unit.maxhp)
	
	var color := Color.WHITE
	if amount > 0:
		if source == Globals.status_effect['PSN']:
			color = Color(0.949, 0.29, 0.949)
		elif source == Globals.status_effect['VUL']:
			color = Color(0.949, 0.949, 0.29)
		else:
			camera.get_node("AnimationPlayer").play('shake')
			color = Color(0.949, 0.29, 0.392)
	
	play_floating_number(unit, abs(amount), color)
	
	if unit.hp <= 0:
		kill_unit(unit)
		
		
	
	
## Makes the unit stop walking.
func stop_walking(unit: Unit):
	unit.get_meta("Battle_driver").stop_walking()
	

## Returns true if the unit is walking.
func is_walking(unit: Unit):
	return unit.has_meta("Battle_driver")
	
	
## Sets unit bond level.
func set_bond_level(unit: Unit, level: int):
	unit.bond = clampi(level, 0, 2)
	if unit.bond >= 1:
		for stat in unit.unit_type.stat_growth_1:
			unit.set(stat, unit.unit_type.stat_growth_1[stat])
	if unit.bond >= 2:
		for stat in unit.unit_type.stat_growth_2:
			unit.set(stat, unit.unit_type.stat_growth_2[stat])
	
	
## Returns true if the unit do a move action.
func can_move(unit: Unit) -> bool:
	return unit.get_meta("Battle_can_move", false)


## Returns true if the unit can do an attack action.
func can_attack(unit: Unit) -> bool:
	return unit.get_meta("Battle_can_attack", false)
	
	
## Returns true if the unit has taken any actions.
func action_taken(unit: Unit) -> bool:
	return unit.get_meta("Battle_action_taken", false)


## Sets the unit can_move flag.
func set_can_move(unit: Unit, value: bool):
	unit.set_meta("Battle_can_move", value)
	
	
## Sets the unit can_attack flag.
func set_can_attack(unit: Unit, value: bool):
	unit.set_meta("Battle_can_attack", value)
	
	
## Sets the unit action_taken flag.
func set_action_taken(unit: Unit, value: bool):
	unit.set_meta("Battle_action_taken", value)
	

## Returns true if the unit is owned by the current empire on turn.
func is_owned(unit: Unit) -> bool:
	return unit.empire == context.on_turn
	
	
## Returns true if pos is pathable for unit.
func is_pathable(unit: Unit, cell: Vector2i) -> bool:
	for obj in map.get_objects_at(cell):
		if not unit.can_path(obj):
			return false
	return true
	

## Returns true if this unit can be placed on pos.
func is_placeable(unit: Unit, cell: Vector2i) -> bool:
	if map.cell(unit.map_pos) == cell:
		return true
	for obj in map.get_objects_at(cell):
		if not unit.can_place(obj):
			return false
	return true


################################################################################
# Misc Battle functions
################################################################################
	

func get_viewport_size() -> Vector2i:
	return viewport.size


func set_debug_tile_visible(debug_tile_visible: bool):
	# inspector starts with 1 but this is 0-based
	viewport.set_canvas_cull_mask_bit(9, debug_tile_visible)


func display_message(message):
	print(message)
	message_displayed.emit(message)
	

func play_error(message):
	if not $AudioStreamPlayer2D.is_playing():
		$AudioStreamPlayer2D.stream = preload("res://error-126627.wav")
		$AudioStreamPlayer2D.play()
	if message:
		display_message('error: ' + message)
	
	
func update_portrait(unit: Unit):
	# TODO unit parameters should be accessible in a uniform manner instead of
	# having picking from unit_type and chara
	$UI/Battle/Name/Label.text = unit.unit_type.name 
	$UI/Battle/Portrait/Control/TextureRect.texture = unit.unit_type.chara.portrait
	var container := $UI/Battle/Portrait/VBoxContainer
	
	# add hearts if lacking
	for i in max(0, unit.hp - container.get_child_count()):
		var trect := preload("res://Screens/Battle/Heart.tscn").instantiate()
		container.add_child(trect)
	
	# show all hearts
	var i := 0
	for heart in container.get_children():
		heart.visible = i < unit.hp
		i += 1
	
	
func play_floating_number(unit: Unit, number: int, color: Color):
	var node := preload("res://Screens/Battle/FloatingNumber.tscn").instantiate()
	var anim := node.get_node('AnimationPlayer') as AnimationPlayer
	var label := node.get_node('Label') as Label
	unit.add_child(node)
	
	# add some offset randomness
	node.position.x = randf_range(node.position.x - 24, node.position.x + 24)
	node.position.y = randf_range(node.position.x - 12, node.position.x + 12)
	
	label.text = str(number)
	node.modulate = color
	
	anim.play('start')
	await anim.animation_finished
	
	node.queue_free()
	
	
## Makes the camera follow a MapObject.
func set_camera_follow(obj: MapObject):
	if _camera_target:
		_camera_target.map_pos_changed.disconnect(_on_target_map_pos_changed)
	
	_camera_target = obj
	if _camera_target:
		_camera_target.map_pos_changed.connect(_on_target_map_pos_changed)
		
		
## Selects cell for attack target.
func select_attack_target(unit: Unit, attack: Attack, target: Variant):
	if attack.melee:
		match typeof(target):
			TYPE_VECTOR2, TYPE_VECTOR2I:
				unit.face_towards(target)
			TYPE_FLOAT, TYPE_INT:
				unit.facing = target
		if unit.get_attack_range(attack) > 0:
			select_cell(unit.map_pos + Unit.Directions[unit.get_heading()] * unit.get_attack_range(attack))
		else:
			select_cell(unit.map_pos)
	else:
		select_cell(target)


## Returns a list of walkable cells.
func get_walkable_cells(unit: Unit) -> PackedVector2Array:
	var cond := func(p): return is_pathable(unit, p)
	var bounds := Rect2i(Vector2i.ZERO, map.world.map_size)
	return Util.flood_fill(map.cell(unit.map_pos), unit.mov, bounds, cond)
	#return Globals.flood_fill(battle.map.cell(unit.map_pos), unit.mov, Rect2i(Vector2i.ZERO, battle.map.world.map_size),  func(p): return is_pathable(unit, p))
	

## Returns a list of targetable cells.
func get_targetable_cells(unit: Unit, attack: Attack) -> PackedVector2Array:
	var re := Util.flood_fill(
			map.cell(unit.map_pos),
			unit.get_attack_range(attack),
			Rect2i(Vector2i.ZERO, map.world.map_size),
			)
	if attack.min_range > 0:
		var min_area := Util.flood_fill(
			map.cell(unit.map_pos),
			attack.min_range,
			Rect2i(Vector2i.ZERO, map.world.map_size),
			)
		for p in min_area:
			var idx := re.find(p)
			re.remove_at(idx)
	return re
	
	
## Draws target overlay. target_rotation is ignored if melee.
func draw_attack_overlay(unit: Unit, attack: Attack, target: Vector2i, target_rotation: float = 0):
	draw_attack_overlay_multicast(unit, attack, [target], target_rotation)
	

## Draws target overlay. Supports multicast.
func draw_attack_overlay_multicast(unit: Unit, attack: Attack, targets: Array[Vector2i], target_rotation: float = 0):
	terrain_overlay.clear()
	
	# draw range
	var cells := get_targetable_cells(unit, attack)
	if not attack.melee:
		draw_terrain_overlay(cells, TERRAIN_RED)
		
	# draw targeted cells
	for target in targets:
		var target_cells := get_attack_target_cells(unit, attack, target, target_rotation)
		draw_terrain_overlay(target_cells, TERRAIN_BLUE)
	
	
## Draws terrain overlay.
func draw_terrain_overlay(cells: PackedVector2Array, idx := TERRAIN_GREEN, clear := false):
	if clear:
		terrain_overlay.clear()
	for cell in cells:
		terrain_overlay.set_cell(0, cell, 0, Vector2i(idx, 0), 0)
		
		
## Sets the visibility of ui elements.
func set_ui_visible(chara_info: Variant, attack: Variant, special: Variant, undo_end: Variant):
	if chara_info != null:
		$UI/Battle/Name.visible = chara_info
		$UI/Battle/Portrait.visible = chara_info
	if attack != null:
		$UI/Battle/AttackButton.visible = attack
	if special != null:
		$UI/Battle/SpecialButton.visible = special
	if undo_end != null:
		$UI/Battle/UndoButton.visible = undo_end
		$UI/Battle/EndTurnButton.visible = undo_end
	
			
## Selects the cell.
func select_cell(cell: Vector2i):
	var world_margin := Vector2i(5, 5)
	cell = cell.clamp(-world_margin, map.world.map_size + world_margin)
	cursor.map_pos = cell
	cell_selected.emit(cell)


## Accepts the cell.
func accept_cell(cell: Vector2i = Map.OUT_OF_BOUNDS):
	if cell != Map.OUT_OF_BOUNDS and map.cell(cursor.map_pos) != cell:
		select_cell(cell)
		
	cell_accepted.emit(cell)
	

## Returns a list of targets.
func get_attack_target_units(user: Unit, attack: Attack, target: Vector2i, target_rotation: float = 0) -> Array[Unit]:
	var targets: Array[Unit] = []
	for p in get_attack_target_cells(user, attack, target, target_rotation):
		var u := get_unit(p)
		if u:
			targets.append(u)
	return targets


## Returns a list of targeted cells.
func get_attack_target_cells(user: Unit, attack: Attack, target: Vector2i, target_rotation: float = 0) -> PackedVector2Array:
	if attack.melee:
		target_rotation = user.get_heading() * PI/2
		
	var re := PackedVector2Array()
	for offs in attack.target_shape:
		var m := Transform2D()
		m = m.translated(offs)
		m = m.rotated(target_rotation)
		m = m.translated(target)
		re.append(map.cell(m * Vector2.ZERO))
		
	return re


################################################################################
# Signals
################################################################################


func _on_target_map_pos_changed():
	assert(_camera_target)
	camera.position = map.world.uniform_to_screen(_camera_target.map_pos)
	

func _on_battle_started(attacker, defender, _territory):
	$UI.visible = true


func _on_battle_ended(_result):
	$UI.visible = false
	camera.drag_horizontal_enabled = false
	camera.drag_vertical_enabled = false
	camera.position = Vector2(960, 540)


func _on_done_prep_pressed():
	if fulfills_prep_requirements(context.on_turn, context.territory):
		prep_done.emit()
	else:
		display_message(context.warnings)


func _on_cancel_prep_pressed():
	quit_battle.call_deferred()


func _on_turn_started():
	set_process_input(false)
	set_camera_follow(cursor)
	$UI/Battle/OnTurn.text = context.on_turn.leader.name
	if context.on_turn.is_player_owned():
		$AnimationPlayer.play("turn_banner.player")
		cursor.visible = true
	else:
		$AnimationPlayer.play("turn_banner.enemy")
		cursor.visible = false
	await $AnimationPlayer.animation_finished
	set_process_input(true)


func _on_turn_ended():
	pass # Replace with function body.


func _on_turn_cycle_started():
	$UI/Battle/TurnNumber.text = str(context.turns)
	

func _on_attack_sequence_started(_unit, attack, _target, _targets):
	set_ui_visible(false, false, false, false)
	$UI/Attack/Label.text = attack.name
	$UI/Attack.visible = true


func _on_attack_sequence_ended(_unit, _attack, _target, _targets):
	$UI/Attack.visible = false


func _on_walking_started(unit):
	set_camera_follow(unit)
	if Globals.prefs.camera_follow_unit_move:
		camera.drag_horizontal_enabled = false
		camera.drag_vertical_enabled = false
	set_process_unhandled_input(false)
	$UI.visible = false


func _on_walking_finished(unit):
	$UI.visible = true
	set_process_unhandled_input(true)
	camera.drag_horizontal_enabled = true
	camera.drag_vertical_enabled = true
	set_camera_follow(cursor)

	
## The state of the battle.
class Context:
	var battle_phase := false
	
	var player: Empire
	var ai: Empire
	var attacker: Empire
	var defender: Empire
	var territory: Territory
	var result: Result
	
	var turns: int
	var on_turn: Empire
	#var controller := {}
	var should_end: bool

	var spawned_units: Array[Unit]
	var warnings: PackedStringArray
	
	var victory_conditions: Array[VictoryCondition]
	
	
