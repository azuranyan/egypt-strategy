@tool
extends Control
class_name Battle


## Emitted when battle is started.
signal battle_started(attacker, defender, territory)

## Emitted when battle ended.
signal battle_ended(result)


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


var context: Context

var _camera_target: MapObject = null

@onready var state_machine: StateMachine = $States
@onready var character_list: CharacterList = $UI/CharacterList

@onready var viewport: Viewport = $SubViewportContainer/Viewport
@onready var map: Map
@onready var camera: Camera2D = $Camera2D
@onready var terrain_overlay: TileMap = $SubViewportContainer/Viewport/TerrainOverlay
@onready var unit_path: UnitPath = $SubViewportContainer/Viewport/UnitPath
@onready var cursor: SpriteObject = $UI/Cursor


func _ready():
	set_debug_tile_visible(false)
	
	print("battle ready")
	
	
## Starts a battle between two empires over a territory.
func start_battle(attacker: Empire, defender: Empire, territory: Territory, do_quick: Variant = null):
	# force ourselves to be ready by doing this hack
	if not self.is_node_ready():
		Globals.push_screen(Globals.battle)
		Globals.pop_screen()
		
	# initialize context
	context = Battle.Context.new()
	context.attacker = attacker
	context.defender = defender
	context.territory = territory
	context.result = Battle.Result.Cancelled
	context.turns = 0
	context.on_turn = context.attacker
	context.controller[attacker] = player_action_controller if attacker.is_player_owned() else ai_action_controller
	context.controller[defender] = player_action_controller if defender.is_player_owned() else ai_action_controller
	context.should_end = false
	context.victory_conditions = [VictoryCondition.new()] # TODO
	
	if fulfills_battle_requirements(attacker, territory):
		# do battle
		battle_started.emit(attacker, defender, territory)
		
		var should_do_quick := not (attacker.is_player_owned() or defender.is_player_owned())
		if do_quick != null:
			should_do_quick = do_quick
			
		if should_do_quick:
			context.result = await _quick_battle(attacker, defender, territory)
		else:
			Globals.push_screen(self)
			context.result = await _real_battle(attacker, defender, territory)
			Globals.pop_screen()
		
		battle_ended.emit(context.result)
	else:
		# error
		display_message(context.warnings)
		battle_ended.emit(Result.AttackerRequirementsError)


## Returns true if the attacker fulfills battle requirements over territory.
func fulfills_battle_requirements(empire: Empire, territory: Territory) -> bool:
	context.warnings = []
	return true


## Returns true if the attacker fulfills prep requirements over territory.
func fulfills_prep_requirements(empire: Empire, territory: Territory) -> bool:
	context.warnings = []
	return true


## Request to end battle.
func end_battle(result: Result):
	if context:
		_end_battle_requested.emit(result)
	else:
		push_warning("end_battle: battle not started!")
	

## Outcome is an implementation detail.
func _quick_battle(attacker: Empire, defender: Empire, territory: Territory) -> Result:
	return Result.AttackerVictory


## Real battle. 
func _real_battle(attacker: Empire, defender: Empire, territory: Territory) -> Result:
	# load the map
	_load_map(territory.maps[0])
	
	# if defender is ai, allow them to set first so player can see the map
	# with enemies already in place.
	var prep_queue := []
	if !context.defender.is_player_owned() and context.attacker.is_player_owned():
		prep_queue.append(context.defender)
		prep_queue.append(context.attacker)
	else:
		prep_queue.append(context.attacker)
		prep_queue.append(context.defender)
		
	# prep phase
	$UI/DonePrep.visible = true
	$UI/CancelPrep.visible = true
	var prep_result := await _prep_phase(prep_queue)
	$UI/DonePrep.visible = false
	$UI/CancelPrep.visible = false
	
	# battle phase
	var battle_result := Result.Cancelled
	if prep_result == 0:
		# PRUNE allow do_battle to be cut in line by end_battle call
		_do_battle.call_deferred()	
		battle_result = await _end_battle_requested
	_unload_map()
	return battle_result
	
	
func _do_battle():
	$UI/Battle.visible = true # TODO signalize all ui changes
	context.controller[context.attacker].initialize(self, context.attacker)
	context.controller[context.defender].initialize(self, context.defender)
	
	# loop until battle finishes
	while not context.should_end:
		# reset move and attack flags
		for u in map.get_units():
			var stunned: bool = Globals.status_effect['STN'] in u.status_effects
			set_can_move(u, not stunned)
			set_can_attack(u, not stunned)
			
		turn_cycle_started.emit()
				
		# allow both empires to take their turns
		for empire in [context.attacker, context.defender]:
			# tick poison at the very start of turn, should be here so we can 
			# properly evaluate w/l conditions before the turn actually starts
			for u in map.get_units():
				if u.empire == empire and Globals.status_effect['PSN'] in u.status_effects:
					damage_unit(u, Globals.status_effect['PSN'], 1)
			
			# things can happen before/after doing any actions so make sure to check first
			if _evaluate_victory_conditions():
				break
			
			# set the empire as the one to take their turn
			context.on_turn = empire
			_should_end_turn = false
			
			# do turn (note that the attacker always attacks first)
			context.controller[context.on_turn].turn_start()
			turn_started.emit()
			await _do_turn()
			turn_ended.emit()
			context.controller[context.on_turn].turn_end()
			
			# do end-turn tick mechanics
			for u in map.get_units():
				if u.empire == empire:
					# recover 1 hp for units that didn't do anything
					if can_move(u) and can_attack(u):
						damage_unit(u, self, -1) 
					
					# tick duration of status effects
					u.tick_status_effects()
					
		turn_cycle_ended.emit()
		
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
	
	
func _prep_phase(prep_queue: Array) -> int:
	while not prep_queue.is_empty():
		var prep: Empire = prep_queue.pop_front()
		context.on_turn = prep
		print("%s %s is preparing units" % [prep.leader.name, prep])
		if prep.is_player_owned():
			state_machine.transition_to("Prep", {prep_queue=[prep], battle=self})
		else:
			var spawnable := prep.units.duplicate()
			
			# fill spawn points
			for spawn_point in map.get_spawn_points("ai"):
				print('  checking spawn point ', spawn_point)
				if spawnable.is_empty():
					print('  no more spawnables, stopping')
					break
					
				var nem := ""
					
				# spawn or random
				if map.get_object_at(spawn_point).has_meta("spawn_unit"):
					var s = map.get_object_at(spawn_point).get_meta("spawn_unit")
					if s not in spawnable:
						push_error("spawn_unit '%s' not in spawnable" % s)
						continue
					else:
						nem = s
				else:
					nem = spawnable.pick_random()
				
				# remove from spawnable list
				spawnable.erase(nem)
				
				# spawn unit
				var unit := spawn_unit(nem, prep, "", spawn_point)
				print('  spawning %s at %s' % [nem, spawn_point])
				
				# make it face towards the closest spawn point
				var p_spawn := map.get_spawn_points("player")
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
					
	return await _end_prep_requested
	
	
func _check_prep_start() -> bool:
	return true

	
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
		display_message(message)
	
	
func set_bond_level(unit: Unit, level: int):
	unit.bond = clampi(level, 0, 2)
	if unit.bond >= 1:
		for stat in unit.unit_type.stat_growth_1:
			unit.set(stat, unit.unit_type.stat_growth_1[stat])
	if unit.bond >= 2:
		for stat in unit.unit_type.stat_growth_2:
			unit.set(stat, unit.unit_type.stat_growth_2[stat])
	
	
func use_attack(unit: Unit, attack: Attack, target_cell: Vector2i, target_rotation: float):
	var cellf := Vector2(target_cell)
	
	# check for bond level
	if attack == unit.unit_type.special_attack and unit.bond < 2:
		play_error("Unit has not unlocked this skill yet.")
		return
	
	# check for minimum range
	if attack.min_range > 0:
		var min_range := Util.flood_fill(map.cell(unit.map_pos), attack.min_range, Rect2i(Vector2i.ZERO, map.world.map_size))
		if cellf in min_range:
			play_error("Target is inside minimum range.")
			return
	
	# check for out of range
	var target_range := Util.flood_fill(map.cell(unit.map_pos), unit.get_attack_range(attack), Rect2i(Vector2i.ZERO, map.world.map_size))
	if cellf not in target_range:
		play_error("Target is out of range.")
		return
	
	# check for any targets
	var target_cells := get_attack_target_cells(unit, attack, target_cell, target_rotation)
	var targets := map.get_units().filter(func(u): return Vector2(map.cell(u.map_pos)) in target_cells)
	if targets.is_empty():
		play_error("No targets found.")
		return
	
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
		play_error("Invalid target")	# as there's at least one valid target,
		return							# even if there are invalid targets
	
	# commit actions
	set_can_move(unit, false)
	set_can_attack(unit, false)
	
	# attack signal
	attack_sequence_started.emit(unit, attack, target_cell, targets)
	await get_tree().create_timer(0.2).timeout # added artificial timeouts
	await _attack_sequence_finished
	await get_tree().create_timer(0.4).timeout
	attack_sequence_ended.emit(unit, attack, target_cell, targets)
	


func do_nothing(unit: Unit):
	set_can_move(unit, false)
	set_can_attack(unit, false)
	
	
################################################################################

const action_limit := 10
var _should_end_turn: bool

signal turn_cycle_started
signal turn_cycle_ended
signal turn_started
signal turn_ended
signal action_started
signal action_ended
#
#signal attack_button_pressed
#signal special_button_pressed
#signal undo_button_pressed
#signal end_turn_button_pressed


@onready var ai_action_controller := $AIActionController as BattleActionController
@onready var player_action_controller := $PlayerActionController as BattleActionController
	

func _do_turn():
	while not _should_end_turn:
		# things can happen before/after doing any actions so make sure to check first
		if _evaluate_victory_conditions():
			return
		
		# do action
		context.controller[context.on_turn].action_start()
		action_started.emit()
		await context.controller[context.on_turn].do_action()
		action_ended.emit()
		context.controller[context.on_turn].action_end()
		
		# auto end turn
		if Globals.prefs.auto_end_turn:
			var units := map.get_units().filter(func(x): return x.empire == context.on_turn)
			var should_end := true
			
			for u in units:
				if can_move(u) or can_attack(u):
					should_end = false
					break
					
			if should_end:
				end_turn()
		
		
## Sends the signal to end the current turn.
func end_turn():
	_should_end_turn = true
	

func _evaluate_victory_conditions() -> bool:
	for c in context.victory_conditions:
		context.result = c.evaluate(self)
		if context.result != Result.None:
			context.should_end = true
			return true
	return false
		
		
################################################################################
	

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
	
	
func notify_attack_sequence_finished():
	# this is done so the methods called from the attack_sequence_started
	# signal can call this function and trigger the notify on the next frame.
	# not doing so will cause us to be stuck because we're still in the same
	# context as the attack_sequence call and have not moved on to the next
	# statement yet aka await for finish.
	_notify_attack_sequence_finished.call_deferred()


func _notify_attack_sequence_finished():
	_attack_sequence_finished.emit()
	
	
func can_move(unit: Unit) -> bool:
	return unit.get_meta("Battle_can_move", false)


func can_attack(unit: Unit) -> bool:
	return unit.get_meta("Battle_can_attack", false)


func set_can_move(unit: Unit, value: bool):
	unit.set_meta("Battle_can_move", value)
	
	
func set_can_attack(unit: Unit, value: bool):
	unit.set_meta("Battle_can_attack", value)
	
	
func is_owned(unit: Unit) -> bool:
	return unit.empire == context.on_turn
	
	
## Returns true if pos is pathable.
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
	terrain_overlay.clear()
	
	var cells := get_targetable_cells(unit, attack)
	
	if not attack.melee:
		draw_terrain_overlay(cells, TERRAIN_RED, true)
	
	var target_cells := get_attack_target_cells(unit, attack, target, target_rotation)
	draw_terrain_overlay(target_cells, TERRAIN_BLUE, false)


## Draws terrain overlay.
func draw_terrain_overlay(cells: PackedVector2Array, idx := TERRAIN_GREEN, clear := false):
	if clear:
		terrain_overlay.clear()
	for cell in cells:
		terrain_overlay.set_cell(0, cell, 0, Vector2i(idx, 0), 0)
		
		
## Sets the visibility of ui elements.
func set_ui_visible(chara_info: Variant, attacks: Variant, undo_end: Variant):
	if chara_info != null:
		$UI/Battle/Name.visible = chara_info
		$UI/Battle/Portrait.visible = chara_info
	if attacks != null:
		$UI/Battle/AttackButton.visible = attacks
		$UI/Battle/SpecialButton.visible = attacks
	if undo_end != null:
		$UI/Battle/UndoButton.visible = undo_end
		$UI/Battle/EndTurnButton.visible = undo_end
	
		
## Spawns a unit of type tag with name at pos, facing x.
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
	add_unit(unit, pos)
	# TODO this piece of code shouldnt be here but im too lazy to create
	# an appropriate function so just deal with this for now
	unit.hp = unit.empire.hp_multiplier * unit.maxhp
	return unit
	

## Adds an already created unit to the map.
func add_unit(unit: Unit, pos := Map.OUT_OF_BOUNDS):
	var old_parent := unit.get_parent()
	if old_parent:
		if old_parent is Map:
			old_parent.remove_object(unit)
		else:
			old_parent.remove_child(unit)
	map.add_object(unit)
	unit.map_pos = pos
	
	
## Removes a unit from the map.
func remove_unit(unit: Unit):
	if unit not in map.get_objects():
		return
	# TODO if removed unit is on turn, forfeit first
	
	map.remove_object(unit)


## Kills a unit.
func kill_unit(unit: Unit):
	# TODO play death animation
	remove_unit(unit)
	

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
		
	await play_floating_number(unit, abs(amount), color)
	
	if unit.hp == 0:
		kill_unit(unit)

	
## Walks the unit.
func walk_unit(unit: Unit, cell: Vector2i):
	walking_started.emit(unit)
	
	var start := map.cell(unit.map_pos)
	var end := cell
	var path := unit_path._pathfinder.calculate_point_path(start, end)
	await _walk_along(unit, path)
		
	walking_finished.emit(unit)
	
## Makes the unit stop walking.
func stop_walking(unit: Unit):
	unit.get_meta("Battle_driver").stop_walking()
	

## Returns true if the unit is walking.
func is_walking(unit: Unit):
	return unit.has_meta("Battle_driver")
	
	
## Makes the unit walk along a path.
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
		var u := map.get_object(p, Map.Pathing.UNIT)
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


## Makes the camera follow a MapObject.
func set_camera_follow(obj: MapObject):
	# TODO some bug concerning this:
	# the wrong lambda is being called leading to error
#	if camera.has_meta("battle_target"):
#		camera.get_meta("battle_target").map_pos_changed.disconnect(camera.get_meta("battle_follow_func"))
#		camera.set_meta("battle_follow_func", null)
#		camera.set_meta("battle_target", null)
#
#	if obj:
#		var follow_func := func():
#			camera.position = map.world.uniform_to_screen(obj.map_pos)
#
#		camera.set_meta("battle_follow_func", follow_func)
#		camera.set_meta("battle_target", obj)
#
#		obj.map_pos_changed.connect(follow_func)
	if _camera_target:
		_camera_target.map_pos_changed.disconnect(_on_target_map_pos_changed)
	
	_camera_target = obj
	if _camera_target:
		_camera_target.map_pos_changed.connect(_on_target_map_pos_changed)
		

func _on_target_map_pos_changed():
	assert(_camera_target)
	camera.position = map.world.uniform_to_screen(_camera_target.map_pos)
	

# TODO maybe this should be on UI code?
func _on_battle_started(attacker, defender, _territory):
	$UI.visible = true
	#$UI/Label.text = "%s vs %s" % [attacker.leader.name, defender.leader.name]


func _on_battle_ended(_result):
	$UI.visible = false

	camera.drag_horizontal_enabled = false
	camera.drag_vertical_enabled = false
	camera.position = Vector2(960, 540)


func _on_done_prep_pressed():
	if fulfills_prep_requirements(context.on_turn, context.territory):
		print("FUCKING TRANSITION")
		state_machine.transition_to("Idle")
		_end_prep_requested.emit(0)
	else:
		print("FUCKING ERROR")
		display_message(context.warnings)


func _on_undo_button_pressed():
	state_machine.transition_to("Idle")
	_end_prep_requested.emit(1)


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
	set_ui_visible(false, false, false)
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
	var attacker: Empire
	var defender: Empire
	var territory: Territory
	var result: Result
	
	var turns: int
	var on_turn: Empire
	var controller := {}
	var should_end: bool

	var spawned_units: Array[Unit]
	var warnings: PackedStringArray
	
	var victory_conditions: Array[VictoryCondition]
	
	
