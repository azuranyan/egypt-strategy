extends BattleActionController


signal _action_completed


const MAP_MARGIN := 3


## Reference to battle object.
var battle: Battle

## The active unit. Set when a unit is in the accepted cell.
var active_unit: Unit

## Cached walkable cells of the active unit.
var active_walkable: PackedVector2Array

## The active attack. Set when an attack is engaged. Active attack implies active unit.
var active_attack: Attack

## The active attack multicast counter.
var active_multicast: Array[Vector2i]

## Cached targetable cells of the active attack.
var active_targetable: PackedVector2Array

## Set when a unit facing is being changed.
var change_facing: Unit

## Undo stack of unit move action.
var move_stack: Array[UnitMoveAction]


var _allow_input: bool:
	set(value):
		if not is_node_ready():
			await get_parent().ready
		#print(value)
		_allow_input = value
		$"../UI/Battle".visible = value
		set_process_unhandled_input(value)


## Initializes the controller. Called once every battle start.
func initialize(_battle: Battle, _empire: Empire) -> void:
	self.battle = _battle
	

## Called when action has to be executed.
func do_action() -> void:
	await _action_completed
	
	
## Called when turn starts.
func turn_start() -> void:
	_allow_input = true
	#$"../UI/Battle".visible = true
	

## Called when turn ends.
func turn_end() -> void:
	clear_active_unit()
	move_stack.clear()
	
	_allow_input = false
	#$"../UI/Battle".visible = false

	
## Called when action is started.
func action_start() -> void:
	_allow_input = true
	#set_process_unhandled_input(true)
	

## Called when action is ended.
func action_end() -> void:
	_allow_input = false
	#set_process_unhandled_input(false)


func _ready():
	_allow_input = false
	#set_process_unhandled_input(false)


func _unhandled_input(event):
	# Make input local, imporant because we're using a camera
	#event = battle.map.make_input_local(event)
	event = battle.make_input_local(event)
	
	var cur: Vector2i = battle.map.cell(battle.cursor.map_pos)
	var cell: Vector2i = cur if not event is InputEventMouse else battle.map.cell(battle.map.world.screen_to_uniform(event.position))
	
	# TODO transform to inputs
	if active_attack:
		battle.camera.drag_horizontal_enabled = true
		battle.camera.drag_vertical_enabled = true
		
		# accept
		if (event is InputEventMouseButton and event.button_index == 1 or event is InputEventKey and event.keycode == KEY_KP_1) and event.pressed:
			battle.accept_cell()
			return
		
		# cancel
		if (event is InputEventMouseButton and event.button_index == 2 or event is InputEventKey and event.keycode == KEY_KP_3) and event.pressed:
			cancel()
			return
		
		if active_attack.melee:
			if event is InputEventMouseMotion:
				if active_unit.map_pos.distance_to(cell) > 0.6:
					battle.select_attack_target(active_unit, active_attack, cell)
			elif event is InputEventKey and event.pressed:
				match event.keycode:
					KEY_W:
						battle.select_attack_target(active_unit, active_attack, -PI/2)
					KEY_S:
						battle.select_attack_target(active_unit, active_attack, PI/2)
					KEY_A:
						battle.select_attack_target(active_unit, active_attack, PI)
					KEY_D:
						battle.select_attack_target(active_unit, active_attack, 0.0)
			
		else:
			if event is InputEventMouseMotion:
				battle.select_cell(cell)
			elif event is InputEventKey and event.pressed:
				match event.keycode:
					KEY_W:
						battle.select_cell(cur + Vector2i(0, -1))
					KEY_S:
						battle.select_cell(cur + Vector2i(0, +1))
					KEY_A:
						battle.select_cell(cur + Vector2i(-1, 0))
					KEY_D:
						battle.select_cell(cur + Vector2i(+1, 0))
			
		return
	
	
	# Mouse input
	if event is InputEventMouseMotion:
		battle.camera.drag_horizontal_enabled = true
		battle.camera.drag_vertical_enabled = true
		if change_facing:
			if change_facing and battle.is_owned(change_facing) and battle.can_attack(change_facing):
				var target := cell
				if change_facing.map_pos.distance_to(target) > 0.6:
					change_facing.face_towards(target)
		else:
			battle.select_cell(cell)
		
	# Mouse button input
	elif event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				1:
					battle.select_cell(cell)
					battle.accept_cell()
				2:
					cancel()
				3:
					change_facing = battle.get_unit(cell)
		else:
			match event.button_index:
				3:
					change_facing = null
					
	# Key input
	elif event is InputEventKey:
		if event.keycode == KEY_KP_2:
			if event.pressed:
				change_facing = battle.get_unit(cur)
			else:
				change_facing = null
			return
		
		if event.pressed:
			if change_facing and battle.is_owned(change_facing) and battle.can_attack(change_facing):
				match event.keycode:
					KEY_W:
						change_facing.face_towards(change_facing.map_pos + Vector2(0, -1))
					KEY_S:
						change_facing.face_towards(change_facing.map_pos + Vector2(0, +1))
					KEY_A:
						change_facing.face_towards(change_facing.map_pos + Vector2(-1, 0))
					KEY_D:
						change_facing.face_towards(change_facing.map_pos + Vector2(+1, 0))
			else:
				battle.camera.drag_horizontal_enabled = false
				battle.camera.drag_vertical_enabled = false
				match event.keycode:
					KEY_W:
						battle.select_cell(cur + Vector2i(0, -1))
					KEY_S:
						battle.select_cell(cur + Vector2i(0, +1))
					KEY_A:
						battle.select_cell(cur + Vector2i(-1, 0))
					KEY_D:
						battle.select_cell(cur + Vector2i(+1, 0))
					KEY_KP_1:
						battle.select_cell(cur)
						battle.accept_cell()
					KEY_KP_3:
						cancel()

################################################################################
## Basic functions
################################################################################
	
	
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
		
		action.unit.map_pos = action.cell
		action.unit.facing = action.facing
		battle.set_can_move(action.unit, action.can_move)
		battle.set_can_attack(action.unit, action.can_attack)
		battle.set_action_taken(action.unit, false)
		
		set_active_unit(action.unit)
		

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
	
	
## Refreshes cached data from active unit and attack.
func refresh_active():
	if active_unit:
		active_walkable = battle.get_walkable_cells(active_unit)
		battle.unit_path.initialize(active_walkable)
		
	if active_attack:
		assert(active_unit)
		active_targetable = battle.get_targetable_cells(active_unit, active_attack)
		
	
################################################################################
## Main functions
################################################################################
		
		
func select_cell(cell: Vector2i):
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
	
	
func accept_cell(cell: Vector2i = Map.OUT_OF_BOUNDS):
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
			use_attack()
		return
		
	# if a unit is selected, interaction is select unit
	if unit:
		if active_unit and battle.can_move(active_unit):
			if battle.is_owned(unit):
				if active_unit == unit:
					# if the selected cell is the same cell with the
					# active unit, just "move" it in place
					push_move_action()
					battle.set_can_move(active_unit, false)
					battle.set_action_taken(active_unit, true)
					clear_active_unit()
					
					# This is a move (MOVE) action
					#action_completed.call_deferred()
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
					# await, because not doing so immediately completes 
					# the action and messes up the flow
					battle.walk_unit(active_unit, cell)
					push_move_action()
					battle.set_can_move(active_unit, false)
					battle.set_action_taken(active_unit, true)
					var u := active_unit
					clear_active_unit()
					if battle.can_attack(u):
						set_active_unit(u)
						
					## This is a move (MOVE) action
					#action_completed.call_deferred()
					return
				else:
					battle.play_error(true)
			else:
				if battle.can_attack(active_unit):
					battle.play_error(true)
				else:
					clear_active_unit()
		# no active unit, not owned, or has already moved
		else:
			clear_active_unit()
	

func cancel():
	# TODO if the action we want to undo is from a different unit, 
	# cancel active unit first
	if active_attack:
		# drag cursor back to active unit pos
		battle.camera.drag_horizontal_enabled = false
		battle.camera.drag_vertical_enabled = false
		battle.cursor.map_pos = active_unit.map_pos
		
		# clear the attack
		clear_active_attack()
		
		# redraw stuff TODO select_active_unit?
		#battle.draw_terrain_overlay(active_walkable, Battle.TERRAIN_GREEN, true)
		if battle.can_move(active_unit):
			battle.draw_terrain_overlay(active_walkable, Battle.TERRAIN_GREEN, true)
		battle.set_ui_visible(null, true, active_unit.bond>=2, null)
	elif active_unit:
		clear_active_unit()
	else:
		undo_move_action()
	

func end_turn():
	battle.end_turn()
	action_completed()
	
	
func use_attack():
	var unit := active_unit
	var attack := active_attack
	var targets := active_multicast.duplicate()
	move_stack.clear()
	clear_active_unit()
	battle.set_can_move(unit, false)
	battle.set_can_attack(unit, false)
	battle.set_action_taken(unit, true)
	for cell in targets:
		battle.use_attack(unit, attack, cell, 0)


func action_completed():
	#_action_completed.emit()
	emit_signal.call_deferred('_action_completed')
	

signal cast_animation_finished
var animated_counter := 0
func decrement_animated_counter():
	animated_counter -= 1
	if animated_counter <= 0:
		var nodes := get_tree().get_nodes_in_group('cast_animation')
		for node in nodes:
			battle.remove_child(node)
			node.queue_free()
		cast_animation_finished.emit()
			
	
func _activate_attack(unit: Unit, attack: Attack, target: Vector2i, targets: Array[Unit]):
	print("%s%s used %s" % [unit.name, battle.map.cell(unit.map_pos), attack.name], ": ", target, " ", targets)

	# play animations
	for t in targets:
		t.model.play_animation(attack.target_animation)
	unit.model.play_animation(attack.user_animation)
	
	# apply attack effect
	for t in targets:
		for eff in attack.effects:
			# all targets are in the array so so we must check first
			if not _is_effect_target(unit, t, eff):
				continue
			
			var anim := AnimatedSprite2D.new()
			anim.sprite_frames = preload("res://Screens/Battle/data/default_effects.tres")
			
			battle.add_child(anim)
			anim.position = battle.map.world.uniform_to_screen(t.map_pos)
			anim.position.y -= 50
			anim.scale = Vector2(0.5, 0.5)
			anim.play(eff.get_animation())
			anim.pause()
			anim.add_to_group('cast_animation')
			anim.animation_finished.connect(decrement_animated_counter)
			animated_counter += 1
			
			eff.apply(battle, unit, attack, target, t)
	
	get_tree().call_group('cast_animation', 'play')
	await cast_animation_finished
	
	# stop animations
	for t in targets:
		t.model.play_animation("idle")
		t.model.stop_animation() # TODO wouldn't have to do this if there's a reset
	unit.model.play_animation("idle")
	unit.model.stop_animation()
	
	battle.notify_attack_sequence_finished()
		

func _is_effect_target(unit: Unit, target: Unit, effect: AttackEffect) -> bool:
	match effect.target:
		0: # Enemy
			return unit.is_enemy(target)
		1: # Ally
			return unit.is_ally(target)
		2: # Self
			return unit == target
	return false


class UnitMoveAction:
	var unit: Unit
	var cell: Vector2i
	var facing: float
	var can_move: bool
	var can_attack: bool
	


func _on_attack_button_pressed():
	assert(active_unit)
	set_active_attack(active_unit.unit_type.basic_attack)


func _on_special_button_pressed():
	assert(active_unit)
	set_active_attack(active_unit.unit_type.special_attack)


func _on_undo_button_pressed():
	cancel()


func _on_end_turn_button_pressed():
	end_turn()


func _on_battle_attack_sequence_started(unit, attack, target, targets):
	# FIX this func shouldn't be implemented here lmao
	_activate_attack(unit, attack, target, targets)


func _on_battle_attack_sequence_ended(_unit, _attack, _target, _targets):
	action_completed.call_deferred()


func _on_battle_walking_started(_unit):
	_allow_input = false
	#$"../UI".visible = false
	#set_process_unhandled_input(false)


func _on_battle_walking_finished(_unit):
	_allow_input = true
	#$"../UI".visible = true
	#set_process_unhandled_input(true)
	action_completed.call_deferred()


func _on_battle_cell_selected(cell):
	select_cell(cell)


func _on_battle_cell_accepted(cell):
	accept_cell(cell)
