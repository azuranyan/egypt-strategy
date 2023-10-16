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

## Emitted when an attack sequence has started.
signal attack_sequence_started(unit: Unit, attack: Attack, target: Vector2i, targets: Array[Unit])

## Emitted when an attack sequence has ended.
signal attack_sequence_ended(unit: Unit, attack: Attack, target: Vector2i, targets: Array[Unit])


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


var action_stack: Array[Action] = []
var frames: int = 0

var context: Context

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
	
	# TODO not ideal
	Globals.battle = self
	
				
func _process(_delta):
	frames += 1
	
	
func push_action(fun: Callable, args: Array):
	var action := Action.new()
	action.frame = frames
	action.fun = fun
	action.args = args
	action_stack.push_back(action)


func pop_action():
	action_stack.pop_back()
	
	
func undo():
	pop_action()
	action_stack[-1].fun.callv(action_stack[-1].args)
	

## Starts a battle between two empires over a territory.
func start_battle(attacker: Empire, defender: Empire, territory: Territory, do_quick := false):
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
	
	if fulfills_battle_requirements(attacker, territory):
		# do battle
		battle_started.emit(attacker, defender, territory)
		
		if do_quick or !(attacker.is_player_owned() or defender.is_player_owned()):
			_quick_battle(attacker, defender, territory)
		else:
			_real_battle(attacker, defender, territory)
		
		# wait until done
		var result = await _end_battle_requested
		battle_ended.emit(result)
	else:
		display_message(context.warnings)
		battle_ended.emit(Result.AttackerRequirementsError)
	
	# cleanup
	context = null


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
func _quick_battle(attacker: Empire, defender: Empire, territory: Territory):
	await get_tree().create_timer(1.0).timeout
	end_battle(Result.AttackerVictory)


## Real battle. 
func _real_battle(attacker: Empire, defender: Empire, territory: Territory):
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
	
	$UI/DonePrep.visible = true
	$UI/CancelPrep.visible = true
	
	var rv = await _prep_phase(prep_queue)
	
	$UI/DonePrep.visible = false
	$UI/CancelPrep.visible = false
	
	if rv != 0:
		_unload_map()
		_end_battle_requested.emit(Result.Cancelled)
	else:
		_battle_phase.call_deferred()
		
		await _end_battle_requested
		_unload_map()
	
	
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
		print("%s (%s) is preparing units" % [prep.leader.name, prep])
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
						closest_dist = v_dist
					p_spawn.remove_at(p_spawn.size() - 1)
						
				unit.face_towards(closest)
					
	return await _end_prep_requested
	
	
func _check_prep_start() -> bool:
	return true


func _battle_phase():
	#state_machine.transition_to("TurnEval", {battle=self})
	_do_battle()
		
	
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
	
################################################################################

const action_limit := 10
var _should_end_turn: bool

signal turn_started
signal turn_ended
signal action_started
signal action_ended

@onready var ai_action_controller := $AIActionController as BattleActionController
@onready var player_action_controller := $PlayerActionController as BattleActionController


func _do_battle():
	context.controller[context.attacker].initialize(self, context.attacker)
	context.controller[context.defender].initialize(self, context.defender)
	
	# loop until battle finishes
	while true:
		# allow both empires to take their turns
		for empire in [context.attacker, context.defender]:
			# things can happen before doing any actions so make sure to check first
			if _evaluate_win_loss_condition():
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
		
		# increment number of turns
		context.turns += 1
		
	

func _do_turn():
	var num_actions := 0
	while not _should_end_turn:
		# things can happen before doing any actions so make sure to check first
		if _evaluate_win_loss_condition():
			return
		
		# do action
		context.controller[context.on_turn].action_start()
		action_started.emit()
		await context.controller[context.on_turn].do_action()
		action_ended.emit()
		context.controller[context.on_turn].action_end()
		
		# action limit just in case
		num_actions += 1
		if num_actions >= action_limit:
			push_warning("too many actions taken, maybe no end_turn()? force ending turn")
			end_turn()
			
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
	

func _evaluate_win_loss_condition() -> bool:
	# once this evaluates to true, we won't reevaluate again on subsequent calls
	if not context.should_end:
		context.result = Result.None
		context.should_end = false
	return context.should_end
		
		
func can_move(unit: Unit) -> bool:
	return unit.get_meta("Battle_can_move", false)


func can_attack(unit: Unit) -> bool:
	return unit.get_meta("Battle_can_attack", false)


func set_can_move(unit: Unit, value: bool):
	unit.set_meta("Battle_can_move", value)
	
	
func set_can_attack(unit: Unit, value: bool):
	unit.set_meta("Battle_can_attack", value)
	
		
## Spawns a unit of type tag with name at pos, facing x.
func spawn_unit(tag: String, empire: Empire, name := "", pos := Map.OUT_OF_BOUNDS, heading := Unit.Heading.West) -> Unit:
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
		name = name if name != "" else tag,
		heading = heading,
	})
	add_unit(unit, pos)
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
	unit.hp = clampi(unit.hp - amount, 0, unit.maxhp)
	if unit.hp == 0:
		kill_unit(unit)


## Selects cell for attack target.
func select_attack_target(user: Unit, attack: Attack, target: Variant):
	if attack.target_melee:
		match typeof(target):
			TYPE_VECTOR2, TYPE_VECTOR2I:
				user.face_towards(target)
			TYPE_FLOAT, TYPE_INT:
				user.facing = target
		select_cell(user.map_pos + Unit.Directions[user.get_heading()] * attack.range)
	else:
		select_cell(target)
	

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
	for p in get_attack_target_cells(user, attack, target):
		var u := map.get_object(p, Map.Pathing.UNIT)
		
		if u:
			targets.append(u)
	return targets


## Returns a list of targeted cells.
func get_attack_target_cells(user: Unit, attack: Attack, target: Vector2i, target_rotation: float = 0) -> PackedVector2Array:
	if attack.target_melee:
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
	if camera.has_meta("battle_target"):
		camera.get_meta("battle_target").map_pos_changed.disconnect(camera.get_meta("battle_follow_func"))
		camera.set_meta("battle_follow_func", null)
		camera.set_meta("battle_target", null)
		
	if obj:
		var follow_func := func():
			camera.position = map.world.uniform_to_screen(obj.map_pos)
		obj.map_pos_changed.connect(follow_func)
		
		camera.set_meta("battle_follow_func", follow_func)
		camera.set_meta("battle_target", obj)


func _on_cursor_position_changed(pos: Vector2):
	$UI/Label.text = "Tile: %s\nx = %s\ny = %s" % [map.get_tile(pos).get_name(), pos.x, pos.y]


# TODO maybe this should be on UI code?
func _on_battle_started(attacker, defender, territory):
	$UI.visible = true
	$UI/Label.text = "%s vs %s" % [attacker.leader.name, defender.leader.name]


func _on_battle_ended(result):
	$UI.visible = false


func _on_done_prep_pressed():
	if fulfills_prep_requirements(context.on_turn, context.territory):
		state_machine.transition_to("Idle")
		_end_prep_requested.emit(0)
	else:
		display_message(context.warnings)


func _on_undo_button_pressed():
	state_machine.transition_to("Idle")
	_end_prep_requested.emit(1)


func _on_turn_eval_attack_used(unit: Unit, attack: Attack, target: Vector2i, targets: Array[Unit]):
	$States/TurnEval/UI.visible = false
	
	# play animations
	for t in targets:
		t.model.play_animation(attack.target_animation)
	unit.model.play_animation(attack.cast_animation)
	
	# do attack sequence
	attack_sequence_started.emit(unit, attack, target, targets)
	await _end_attack_sequence_requested
	attack_sequence_ended.emit(unit, attack, target, targets)
	
	# stop animations
	for t in targets:
		t.model.play_animation("idle")
		t.model.stop_animation() # TODO wouldn't have to do this if there's a reset
	unit.model.play_animation("idle")
	unit.model.stop_animation()
	
	$States/TurnEval/UI.visible = true

	# This is a move (ATTACK), so check for end turn
	$States/TurnEval.check_for_auto_end_turn()


## TODO Generic attack handler. Should make an actual attack handler that checks
## if there are handlers, if not then this kicks in to avoid perma lock.
func _on_attack_sequence_started(unit: Unit, attack: Attack, target: Vector2i, targets: Array[Unit]):
	# play animations
	match attack.cast_animation:
		"attack", "buff", "heal":
			# add animation TODO custom scripted animation
			$AnimatedSprite2D.position = map.world.uniform_to_screen(target)
			$AnimatedSprite2D.position.y -= 50
			$AnimatedSprite2D.play("default")
			
			await $AnimatedSprite2D.animation_finished
			$AnimatedSprite2D.stop()
			
	match attack.target_animation:
		"hurt", "buff", "heal":
			pass
			
	# emit signal
	_end_attack_sequence_requested.emit()
	
	
func _on_attack_sequence_ended(unit: Unit, attack: Attack, target: Vector2i, targets: Array[Unit]):
	# TODO attack effects here
	# damage_unit(flat, percentage)
	# heal_unit(flat, percentage)
	# give_effect(what, duration)
	# set_stat(stat, amount)
	# TODO create the characters and check the extents of the effect of attacks
	for t in targets:
		match attack.type_tag:
			"attack":
				damage_unit(t, unit, unit.dmg)
			"heal":
				damage_unit(t, unit, -unit.dmg)
			"other":
				pass
	
	# apply attack effect
	if attack.status_effect != "None":
		var duration_table := {"PSN": 2, "STN": 1, "VUL": 2}
		var eff = Globals.status_effect[attack.status_effect]
		var dur = duration_table[attack.status_effect]
		
		unit.add_status_effect(eff, dur)
	
	
## An action.
class Action:
	var frame: int
	var fun: Callable
	var args: Array
	
	
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
	





func _on_turn_started():
	set_process_input(false)
	if context.on_turn.is_player_owned():
		$UI/AnimationPlayer.play("turn_banner.player")
		cursor.visible = true
	else:
		$UI/AnimationPlayer.play("turn_banner.enemy")
		cursor.visible = false
	await $UI/AnimationPlayer.animation_finished
	set_process_input(true)


func _on_turn_ended():
	pass # Replace with function body.
