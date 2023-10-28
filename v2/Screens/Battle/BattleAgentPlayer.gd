extends BattleAgent
class_name BattleAgentPlayer


signal prep_done

signal action_ready(action: Callable, args: Array)


# Extra targetable space outside map border.
const MAP_MARGIN := 3


# Prep

## Prep: The selected unit.
var selected: Unit

## Prep: If selected was already in the board and is being moved.
var selected_moved := false

## Prep: The original position, if selected was moved.
var selected_original_pos := Vector2.ZERO

## Prep: Mouse offset for dragging.
var selected_offset := Vector2.ZERO

# Battle

## Battle: The active unit. Set when a unit is in the accepted cell.
var active_unit: Unit

## Battle: Cached walkable cells of the active unit.
var active_walkable: PackedVector2Array

## Battle: The active attack. Set when an attack is engaged. Active attack implies active unit.
var active_attack: Attack

## Battle: The active attack multicast counter.
var active_multicast: Array[Vector2i]

## Battle: Cached targetable cells of the active attack.
var active_targetable: PackedVector2Array

## Battle: Undo stack of unit move action.
var move_stack: Array[UnitMoveAction]

# Universal

## The unit that's being rotated.
var heading_adjusted: Unit

## A record of unit name -> unit.
var unit_map := {}

## Input handler if prep or battle.
var input_handler: Callable


func initialize():
	# add the units to character list
	for type_name in empire.units:
		var unit := battle.spawn_unit(type_name, empire)
		add_unit_hooks(unit)
		battle.character_list.add_unit(type_name)
		
		# this way we don't lose a reference to the unit
		unit_map[type_name] = unit
		battle.set_can_attack(unit, true)
		battle.set_can_move(unit, true)
	
	# configure character list
	battle.character_list.unit_selected.connect(_on_character_list_unit_selected)
	battle.character_list.unit_released.connect(_on_character_list_unit_released)
	battle.character_list.unit_dragged.connect(_on_character_list_unit_dragged)
	battle.character_list.unit_cancelled.connect(_on_character_list_unit_cancelled)
	battle.character_list.unit_highlight_changed.connect(_on_character_list_unit_highlight_changed)
	
	# connect to battle
	battle.prep_done.connect(_on_battle_prep_done)
	battle.prep_cancelled.connect(_on_battle_prep_cancelled)
	battle.battle_quit.connect(_on_battle_quit_battle)
	
	battle.cell_selected.connect(_on_battle_cell_selected)
	battle.cell_accepted.connect(_on_battle_cell_accepted)
	battle.get_node('UI/Battle/AttackButton').pressed.connect(_on_battle_ui_attack_button_pressed)
	battle.get_node('UI/Battle/SpecialButton').pressed.connect(_on_battle_ui_special_button_pressed)
	battle.get_node('UI/Battle/UndoButton').pressed.connect(cancel)
	battle.get_node('UI/Battle/EndTurnButton').pressed.connect(end_turn)
	
	# change ui before transition is shown
	battle.character_list.visible = true
	for o in battle.map.get_objects().filter(func(x): return x.get_meta('spawn_point', '') == 'player'):
		o.no_show = false
	battle.cursor.visible = false
	

func prepare_units():
	input_handler = _unhandled_input_prep
	
	await prep_done
	
	battle.character_list.visible = false
	for o in battle.map.get_objects().filter(func(x): return x.get_meta('spawn_point', '') == 'player'):
		o.no_show = true
	

func do_turn():
	# setup
	should_end = false
	battle.cursor.visible = true
	input_handler = _unhandled_input_battle
	
	# do the action loop
	while not should_end:
		var action: Array = await action_ready
		await do_action(action[0], action[1])
		
	# cleanup
	battle.cursor.visible = false
	clear_active_unit()
	move_stack.clear()
	

func add_unit_hooks(unit: Unit):
	var on_button_down := func(button):
		match button:
			1:
				# if a unit that isn't selected is left clicked, select
				if input_handler == _unhandled_input_prep and unit != selected:
					selected = unit
					selected_moved = true
					selected_original_pos = unit.map_pos
					selected_offset = unit.map_pos - battle.map.world.screen_to_uniform(get_viewport().get_mouse_position())
			2:
				# if selected unit is right clicked, deselect
				if input_handler == _unhandled_input_prep and unit == selected:
					battle.set_unit_group(unit, 'units_standby')
					selected = null
			3:
				# if mmb is pressed on the unit, adjust heading
				if battle.can_attack(unit):
					heading_adjusted = unit
		
	var on_button_up := func(_button):
		pass
		
	unit.button_down.connect(on_button_down)
	unit.button_up.connect(on_button_up)
	
	
func use_keyboard(keyboard: bool):
	battle.camera.drag_horizontal_enabled = keyboard
	battle.camera.drag_vertical_enabled = keyboard
	battle.set_camera_follow(battle.cursor if keyboard else null)
	
	
func _unhandled_input(event):
	# still important to make event local
	event = battle.make_input_local(event)
	
	# universal controls
	if event is InputEventMouseMotion:
		use_keyboard(false)
	
	if event is InputEventKey and event.pressed:
		use_keyboard(true)
	
	if event is InputEventKey:
		if event.keycode == KEY_KP_2:
			var unit := battle.get_unit(battle.map.cell(battle.cursor.map_pos))
			if event.pressed and battle.can_attack(unit):
				heading_adjusted = unit
			else:
				heading_adjusted = null
			# prevent inputs from propagating
			get_viewport().set_input_as_handled()
			return
				
	# heading adjustment
	if heading_adjusted:
		if event is InputEventKey:
			if event.pressed:
				match event.keycode:
					KEY_W:
						heading_adjusted.face_towards(heading_adjusted.map_pos + Vector2(0, -1))
					KEY_S:
						heading_adjusted.face_towards(heading_adjusted.map_pos + Vector2(0, +1))
					KEY_A:
						heading_adjusted.face_towards(heading_adjusted.map_pos + Vector2(-1, 0))
					KEY_D:
						heading_adjusted.face_towards(heading_adjusted.map_pos + Vector2(+1, 0))
						
		if event is InputEventMouseMotion:
			# make unit face the mouse
			var target = battle.map.world.screen_to_uniform(event.position, true)
			if heading_adjusted.map_pos.distance_to(target) > 0.6:
				heading_adjusted.face_towards(target)
					
		if event is InputEventMouseButton:
			# clicking rmb cancels the movement and returns facing to default
			if event.button_index == 2:
				heading_adjusted.set_heading(Unit.Heading.West)
				
			# releasing mmb stops the heading adjustment interaction
			if event.button_index == 3 and not event.pressed:
				heading_adjusted = null
				
		# prevent inputs from propagating
		get_viewport().set_input_as_handled()
		return
	
	# phase specific controls
	input_handler.call(event)
	

func _on_battle_prep_done():
	prep_done.emit()
	
	
func _on_battle_prep_cancelled():
	battle.context.result = Battle.Result.Cancelled
	prep_done.emit()
	

func _on_battle_quit_battle():
	# TODO pressing quit battle shows it for the player, but the way the
	# signals are handled this is very confusing.
	if battle.context.attacker.is_player_owned():
		battle.end_battle(Battle.Result.AttackerWithdraw)
	else:
		battle.end_battle(Battle.Result.DefenderWithdraw)


################################################################################
## Prep
################################################################################

func _unhandled_input_prep(event):
	if selected:
		if event is InputEventMouseMotion:
			# drag selected unit to position
			var drag_pos: Vector2 = battle.map.world.screen_to_uniform(event.position) + selected_offset
			var drag_cell := battle.map.cell(drag_pos)
			selected.map_pos = drag_pos
			
			if Vector2(drag_cell) in battle.map.get_spawn_points('player'):
				selected.animation.play("RESET")
			else:
				selected.animation.play("highlight_red")
			
		if event is InputEventMouseButton:
			# releasing lmb releases the currently selected unit
			if event.button_index == 1 and not event.pressed:
				battle.character_list.get_button(selected.unit_name).release()
				
		# mark input as handled
		get_viewport().set_input_as_handled()


func _on_character_list_unit_selected(uname: String, pos: Vector2):
	var unit: Unit = unit_map[uname]
	
	selected = unit
	selected_moved = false
	selected_original_pos = Vector2.ZERO
	selected_offset = Vector2.ZERO
	
	if heading_adjusted:
		heading_adjusted.set_heading(Unit.Heading.West)
		heading_adjusted = null
	
	battle.set_unit_position(unit, battle.map.world.screen_to_uniform(pos))
	unit.modulate = Color(1, 1, 1, 0.5)
	

func _on_character_list_unit_released(uname: String, _pos: Vector2):
	var unit: Unit = unit_map[uname]
	
	unit.snap_to_grid()
	var spawn_pos := unit.map_pos
		
	# temporarily put away the unit it doesn't get included in get_unit()
	# we'll add it again if the unit can be spawned in the chosen spot
	battle.set_unit_position(unit, Map.OUT_OF_BOUNDS)
	
	if spawn_pos in battle.map.get_spawn_points('player'):
		var occupant := battle.get_unit(spawn_pos)
		print('dropping unit to %s: has %s' % [spawn_pos, occupant])
		if occupant:
			# if the unit is being moved, swap positions, otherwise take over
			if selected_moved:
				occupant.map_pos = selected_original_pos
			else:
				battle.set_unit_position(occupant, Map.OUT_OF_BOUNDS)
		battle.set_unit_position(unit, spawn_pos)
		
	unit.animation.play("RESET")
	unit.modulate = Color(1, 1, 1, 1)
	
	selected = null
	selected_moved = false


func _on_character_list_unit_dragged(uname: String, pos: Vector2):
	var unit: Unit = unit_map[uname]
	
	var drag_pos := battle.map.world.screen_to_uniform(pos)
	unit.map_pos = drag_pos
	
	if Vector2(battle.map.cell(drag_pos)) in battle.map.get_spawn_points('player'):
		unit.animation.play("RESET")
	else:
		unit.animation.play("highlight_red")


func _on_character_list_unit_cancelled(uname: String):
	if unit_map[uname] == selected:
		if selected_moved:
			battle.set_unit_position(selected, selected_original_pos)
		else:
			battle.set_unit_position(selected, Map.OUT_OF_BOUNDS)
		selected = null


func _on_character_list_unit_highlight_changed(uname: String, value: bool):
	unit_map[uname].animation.play("highlight" if value else "RESET")
		

################################################################################
## Battle
################################################################################

func _unhandled_input_battle(event):
	var cur: Vector2i = battle.map.cell(battle.cursor.map_pos)
	var cell: Vector2i
	if event is InputEventMouse:
		cell = battle.map.cell(battle.map.world.screen_to_uniform(event.position))
	else:
		cell = cur
	
#	if active_attack:
#		# prevent inputs from propagating
#		get_viewport().set_input_as_handled()
#		return
		
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			1:
				battle.select_cell(cell)
				battle.accept_cell()
			2:
				cancel()
				
	if event is InputEventMouseMotion:
		battle.select_cell(cell)
	

## Uses callable passed as the action.
func do_unit_action(action: Callable, args := []):
	# call deferred so we don't have the massive stack tree and
	# we start the whole action loop in a fresh new frame
	emit_signal.call_deferred('action_ready', action, args)
	print(action, args)
	
	
## Walks the active unit.
func move_action(cell: Vector2i):
	# setup
	battle.get_node('UI/Battle').visible = false
	set_process_unhandled_input(false)
	push_move_action()
	var unit := active_unit
	clear_active_unit()
	
	# walk
	await battle.walk_unit(unit, cell)
	
	# cleanup
	battle.get_node('UI/Battle').visible = true
	set_process_unhandled_input(true)
	battle.set_can_move(unit, false)
	battle.set_action_taken(unit, true)
	
	# clear and set again if can_attack to refresh the ui
	if battle.can_attack(unit):
		set_active_unit(unit)
		

## Uses the active attack.
func attack_action():
	# setup
	var unit := active_unit
	var attack := active_attack
	var targets := active_multicast.duplicate()
	move_stack.clear()
	clear_active_unit()
	battle.set_can_move(unit, false)
	battle.set_can_attack(unit, false)
	battle.set_action_taken(unit, true)
	
	for cell in targets:
		var p := ParallelUseAttack.new(unit, attack, cell, 0)
		add_child(p)
		p.add_to_group('parallel_use_attack')
		#battle.use_attack(unit, attack, cell, 0)
	
	# attack
	get_tree().call_group('parallel_use_attack', 'execute')
	
	# cleanup
	get_tree().call_group('parallel_use_attack', 'queue_free')
		
		
## Does nothing.
func do_nothing_action():
	if active_unit: # this can be called even without active_unit
		push_move_action()
		battle.do_nothing(active_unit)
		if not battle.can_attack(active_unit):
			clear_active_unit()
	
	
## Ends the turn.
func end_turn():
	should_end = true
	do_unit_action(do_nothing_action, [])
	
	
## Undo's a move.
func cancel():
	if active_attack:
		# drag cursor back to active unit pos
		battle.cursor.map_pos = active_unit.map_pos
		use_keyboard(true)
		
		# clear the attack
		clear_active_attack()
		
		if battle.can_move(active_unit):
			battle.draw_terrain_overlay(active_walkable, Battle.TERRAIN_GREEN, true)
		battle.set_ui_visible(null, true, active_unit.bond>=2, null)
	elif active_unit:
		clear_active_unit()
	else:
		undo_move_action()
		
		
## Pushes a move action.
func push_move_action():
	var action := UnitMoveAction.new()
	action.unit = active_unit
	action.cell = battle.map.cell(active_unit.map_pos)
	action.facing = active_unit.facing
	action.can_move = battle.can_move(active_unit)
	action.can_attack = battle.can_attack(active_unit)
	move_stack.append(action)
	

## Undo's an action.
func undo_move_action():
	if not move_stack.is_empty():
		var action = move_stack.pop_back()
		print('undoing move action ', action.unit.map_pos, ' ', action.cell)
		
		action.unit.map_pos = action.cell
		action.unit.facing = action.facing
		battle.set_can_move(action.unit, action.can_move)
		battle.set_can_attack(action.unit, action.can_attack)
		battle.set_action_taken(action.unit, false)
		
		set_active_unit(action.unit)
	else:
		print('no moves to undo')
	
	
## Sets the active unit.
func set_active_unit(unit: Unit):
	battle.set_ui_visible(true, battle.can_attack(unit), unit.bond>=2, battle.is_owned(unit))
	
	if active_unit:
		clear_active_unit()
		
	unit.animation.play("highlight")
	
	active_unit = unit
	refresh_active()
	
	if battle.is_owned(unit):
		if battle.can_move(unit):
			battle.draw_terrain_overlay(active_walkable, Battle.TERRAIN_GREEN, true)
		else:
			pass
	else:
		battle.draw_terrain_overlay(active_walkable, Battle.TERRAIN_BLUE, true)
	
	
## Sets the active attack of the unit.
func set_active_attack(attack: Attack):
	battle.terrain_overlay.clear()
	battle.unit_path.clear()
	
	active_attack = attack
	refresh_active()
	
	if attack.melee:
		battle.select_attack_target(active_unit, active_attack, null)
		
	battle.set_ui_visible(true, false, false, null)
	
	battle.draw_attack_overlay(active_unit, attack, battle.map.cell(battle.cursor.map_pos))
	
	
## Refreshes cached data from active unit and attack.
func refresh_active():
	if active_unit:
		active_walkable = battle.get_walkable_cells(active_unit)
		battle.unit_path.initialize(active_walkable)
		
	if active_attack:
		assert(active_unit)
		active_targetable = battle.get_targetable_cells(active_unit, active_attack)
		
	
## Clears the active unit.
func clear_active_unit():
	if active_unit:
		# clear stuff
		active_unit.animation.play("RESET")
		active_unit.animation.stop()
		active_unit = null
		active_walkable.clear()
		
		# clear ui
		battle.terrain_overlay.clear()
		battle.unit_path.clear()
		battle.set_ui_visible(false, false, false, false)
		
		# clear attack
		clear_active_attack()
		
		
## Clears the active attack.
func clear_active_attack():
	if active_attack:
		# clear stuff
		active_attack = null
		active_multicast.clear()
		active_targetable.clear()
		
		# clear ui
		battle.terrain_overlay.clear()
		battle.set_ui_visible(null, false, false, null)
		
		
func _on_battle_cell_selected(cell: Vector2i):
	cell.x = clampi(cell.x, -MAP_MARGIN, battle.map.world.map_size.x + MAP_MARGIN - 1)
	cell.y = clampi(cell.y, -MAP_MARGIN, battle.map.world.map_size.y + MAP_MARGIN - 1)
	var unit := battle.get_unit(cell)
	
	# set cursor position
	battle.cursor.map_pos = cell
	
	# set ui elements
	var show_portrait: bool = active_unit or unit != null
	var show_actions: bool = not active_attack and active_unit and battle.is_owned(active_unit) and battle.can_attack(active_unit)
	var show_undo_end: bool = battle.context.on_turn == Globals.empires["Lysandra"]
	
	if show_portrait:
		battle.update_portrait(unit if unit else active_unit)
	battle.set_ui_visible(show_portrait, show_actions, show_actions and active_unit.bond>=2, show_undo_end)
		
	# if there's an active attack, interaction is select target
	if active_attack:
		var arr := active_multicast.duplicate()
		arr.append(cell)
		battle.draw_attack_overlay_multicast(active_unit, active_attack, arr)
		return
	
	# if there's an active unit, interaction is select position
	if active_unit:
		if battle.is_owned(active_unit) and battle.can_move(active_unit) and battle.is_placeable(active_unit, cell):
			battle.unit_path.draw(battle.map.cell(active_unit.map_pos), cell)
		else:
			battle.unit_path.clear()
	
	
func _on_battle_cell_accepted(cell: Vector2i):
	if cell == Map.OUT_OF_BOUNDS:
		cell = battle.map.cell(battle.cursor.map_pos)
	elif battle.map.cell(battle.cursor.map_pos) != cell:
		battle.select_cell(cell)
		
	cell.x = clampi(cell.x, -MAP_MARGIN, battle.map.world.map_size.x + MAP_MARGIN - 1)
	cell.y = clampi(cell.y, -MAP_MARGIN, battle.map.world.map_size.y + MAP_MARGIN - 1)
	var unit := battle.get_unit(cell)
	
	# if there's an active attack, interaction is (to try) to use attack
	if active_attack:
		var err := battle.check_use_attack(active_unit, active_attack, cell, 0)
		if err != Battle.ATTACK_OK:
			battle.play_error(Battle.ATTACK_ERROR_MESSAGE[err])
			return
		
		active_multicast.append(cell)
		if active_multicast.size() > active_attack.multicast:
			# DO ACTION
			do_unit_action(attack_action)
		return
		
	# if a unit is selected, interaction is select unit
	if unit:
		if active_unit and battle.can_move(active_unit):
			if battle.is_owned(unit):
				if active_unit == unit:
					# DO ACTION
					do_unit_action(do_nothing_action)
					return
				else:
					# if same unit, swap
					set_active_unit(unit)
			else:
				battle.play_error("??")
		else:
			set_active_unit(unit)
	
	# if no unit is selected, location is selected and interaction is select location (move)
	else:
		# if we own the active unit and it hasnt moved yet, try moving
		if active_unit and battle.is_owned(active_unit):
			if battle.can_move(active_unit):
				# check if target cell is valid
				if Vector2(cell) in active_walkable and battle.is_pathable(active_unit, cell) and battle.is_placeable(active_unit, cell): 
					# DO ACTION
					do_unit_action(move_action, [cell])
					return
				else:
					battle.play_error('outside range')
			else:
				if battle.can_attack(active_unit):
					battle.play_error('already moved')
				else:
					clear_active_unit()
		# no active unit, not owned, or has already moved
		else:
			clear_active_unit()
	
	
func _on_battle_ui_attack_button_pressed():
	assert(active_unit)
	set_active_attack(active_unit.unit_type.basic_attack)


func _on_battle_ui_special_button_pressed():
	assert(active_unit)
	set_active_attack(active_unit.unit_type.special_attack)
	

class UnitMoveAction:
	var unit: Unit
	var cell: Vector2i
	var facing: float
	var can_move: bool
	var can_attack: bool
	

class ParallelUseAttack extends Node:
	var unit: Unit
	var attack: Attack
	var cell: Vector2i
	var rotation: float
	
	
	func _init(unit: Unit, attack: Attack, cell: Vector2i, rotation: float):
		self.unit = unit
		self.attack = attack
		self.cell = cell
		self.rotation = rotation
		
		
	func execute():
		Globals.battle.use_attack(unit, attack, cell, rotation)
		
		
		
