extends State


signal attack_used(unit, attack, cell, targets)
signal battle_ended(result)

signal _end_action_requested()


const MAP_MARGIN := 3


enum {
	TERRAIN_WHITE,
	TERRAIN_BLUE,
	TERRAIN_GREEN,
	TERRAIN_RED,
}


## Reference to battle object.
var battle: Battle

## The active unit. Set when a unit is in the accepted cell.
var active_unit: Unit

## Cached walkable cells of the active unit.
var active_walkable: PackedVector2Array

## The active attack. Set when an attack is engaged. Active attack implies active unit.
var active_attack: Attack

## Cached targetable cells of the active attack.
var active_targetable: PackedVector2Array

## Set when a unit facing is being changed.
var change_facing: Unit

## Undo stack of unit move action.
var move_stack: Array[UnitMoveAction]

var on_action: Empire

@onready var drivers := $Drivers
@onready var ui := $UI


func enter(kwargs:={}):
	$UI.visible = true
	print("enter turn eval")
	battle = kwargs.battle
	
	battle.set_camera_follow(battle.cursor)
	for u in battle.map.get_units():
		set_can_move(u, true)
		set_can_attack(u, true)
	
	add_hooks()
	
	
func exit():
	remove_hooks()
	$UI.visible = false


func handle_input(event: InputEvent) -> void:
	# Make input local, imporant because we're using a camera
	#event = battle.map.make_input_local(event)
	event = make_input_local(event)
	
	var cur: Vector2i = battle.map.cell(battle.cursor.map_pos)
	var cell: Vector2i = cur if not event is InputEventMouse else battle.map.cell(battle.map.world.screen_to_uniform(event.position))
	
	# TODO transform to inputs
	if active_attack:
		battle.camera.drag_horizontal_enabled = true
		battle.camera.drag_vertical_enabled = true
		
		# accept
		if (event is InputEventMouseButton and event.button_index == 1 or event is InputEventKey and (event.keycode == KEY_KP_1 or event.keycode == KEY_ENTER)) and event.pressed:
			accept_cell()
			return
		
		# cancel
		if (event is InputEventMouseButton and event.button_index == 2 or event is InputEventKey and (event.keycode == KEY_KP_3 or event.keycode == KEY_ESCAPE)) and event.pressed:
			cancel()
			return
		
		if active_attack.target_melee:
			if event is InputEventMouseMotion:
				if active_unit.map_pos.distance_to(cell) > 0.6:
					select_attack_target(active_unit, active_attack, cell)
			elif event is InputEventKey and event.pressed:
				match event.keycode:
					KEY_W:
						select_attack_target(active_unit, active_attack, -PI/2)
					KEY_S:
						select_attack_target(active_unit, active_attack, PI/2)
					KEY_A:
						select_attack_target(active_unit, active_attack, PI)
					KEY_D:
						select_attack_target(active_unit, active_attack, 0.0)
			
		else:
			if event is InputEventMouseMotion:
				select_cell(cell)
			elif event is InputEventKey and event.pressed:
				match event.keycode:
					KEY_W:
						select_cell(cur + Vector2i(0, -1))
					KEY_S:
						select_cell(cur + Vector2i(0, +1))
					KEY_A:
						select_cell(cur + Vector2i(-1, 0))
					KEY_D:
						select_cell(cur + Vector2i(+1, 0))
			
		return
	
	
	# Mouse input
	if event is InputEventMouseMotion:
		battle.camera.drag_horizontal_enabled = true
		battle.camera.drag_vertical_enabled = true
		if change_facing:
			if change_facing and is_owned(change_facing) and can_attack(change_facing):
				var target := cell
				if change_facing.map_pos.distance_to(target) > 0.6:
					change_facing.face_towards(target)
		else:
			select_cell(cell)
		
	# Mouse button input
	elif event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				1:
					select_cell(cell)
					accept_cell()
				2:
					cancel()
				3:
					change_facing = battle.map.get_object(cell, Map.Pathing.UNIT)
		else:
			match event.button_index:
				3:
					change_facing = null
					
	# Key input
	elif event is InputEventKey:
		if event.keycode == KEY_KP_2:
			if event.pressed:
				change_facing = battle.map.get_object(cur, Map.Pathing.UNIT)
			else:
				change_facing = null
			return
		
		if event.pressed:
			if change_facing and is_owned(change_facing) and can_attack(change_facing):
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
						select_cell(cur + Vector2i(0, -1))
					KEY_S:
						select_cell(cur + Vector2i(0, +1))
					KEY_A:
						select_cell(cur + Vector2i(-1, 0))
					KEY_D:
						select_cell(cur + Vector2i(+1, 0))
					KEY_KP_1, KEY_ENTER:
						select_cell(cur)
						accept_cell()
					KEY_KP_3, KEY_ESCAPE:
						cancel()
	

func add_hooks():
	pass
	
	
func remove_hooks():
	pass
	
	
################################################################################
## Interaction functions
################################################################################

	
func select_cell(cell: Vector2i):
	cell.x = clampi(cell.x, -MAP_MARGIN, battle.map.world.map_size.x + MAP_MARGIN - 1)
	cell.y = clampi(cell.y, -MAP_MARGIN, battle.map.world.map_size.y + MAP_MARGIN - 1)
	var unit := battle.map.get_unit(cell)
	
	# set cursor position
	battle.cursor.map_pos = cell
	
	# set ui elements
	var show_portrait: bool = active_unit or unit != null
	var show_actions: bool = not active_attack and active_unit and is_owned(active_unit) and can_attack(active_unit)
	var show_undo_end: bool = battle.context.on_turn == Globals.empires["Lysandra"]
	
	if show_portrait:
		var punit := unit if unit else active_unit
		$UI/Name/Label.text = punit.unit_type.name
		$UI/Portrait/Control/TextureRect.texture = punit.unit_type.chara.portrait
	set_ui_visible(show_portrait, show_actions, show_undo_end)
		
	# if there's an active attack, interaction is select target
	if active_attack:
		draw_attack_overlay(active_unit, active_attack, cell)
		return
	
	# if there's an active unit, interaction is select position
	if active_unit:
		if is_owned(active_unit) and can_move(active_unit) and is_placeable(active_unit, cell):
			battle.unit_path.draw(battle.map.cell(active_unit.map_pos), cell)
		else:
			battle.unit_path.clear()
			
	
	
func accept_cell(cell: Vector2i = Map.OUT_OF_BOUNDS):
	if cell == Map.OUT_OF_BOUNDS:
		cell = battle.map.cell(battle.cursor.map_pos)
	elif battle.map.cell(battle.cursor.map_pos) != cell:
		select_cell(cell)
		
	cell.x = clampi(cell.x, -MAP_MARGIN, battle.map.world.map_size.x + MAP_MARGIN - 1)
	cell.y = clampi(cell.y, -MAP_MARGIN, battle.map.world.map_size.y + MAP_MARGIN - 1)
	var unit := battle.map.get_unit(cell)
	
	# if there's an active attack, interaction is (to try) to use attack
	if active_attack:
		use_attack()
		return
		
	# if a unit is selected, interaction is select unit
	if unit:
		if active_unit and can_move(active_unit):
			if is_owned(unit):
				if active_unit == unit:
					# if the selected cell is the same cell with the
					# active unit, just "move" it in place
					push_move_action()
					set_can_move(active_unit, false)
					clear_active_unit()
					
					# This is a move (MOVE), so check for end turn
					check_for_auto_end_turn()
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
		if active_unit and is_owned(active_unit):
			if can_move(active_unit):
				# check if target cell is valid
				if Vector2(cell) in active_walkable and is_pathable(active_unit, cell) and is_placeable(active_unit, cell): 
					walk_unit(active_unit, cell)
					push_move_action()
					set_can_move(active_unit, false)
					var u := active_unit
					clear_active_unit()
					if can_attack(u):
						set_active_unit(u)
						
					# This is a move (MOVE), so check for end turn
					check_for_auto_end_turn()
				else:
					battle.play_error(true)
			else:
				if can_attack(active_unit):
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
		draw_terrain_overlay(active_walkable, TERRAIN_GREEN, true)
		set_ui_visible(null, true, null)
	elif active_unit:
		clear_active_unit()
	else:
		undo_move_action()
	

func end_turn():
	pass
	
	
func use_attack():
	var cell := battle.cursor.map_pos
	
	# play error if cell is outside range 
	if cell not in active_targetable:
		battle.play_error("Target is out of range.")
		return
	
	# play error if no targets
	var target_cells := get_attack_target_cells(active_unit, active_attack, cell)
	var targets := battle.map.get_units().filter(func(x): # don't look
		return Vector2(battle.map.cell(x.map_pos)) in target_cells
		)
	if targets.is_empty():
		battle.play_error("No target.")
		return
	
	# play error if no valid targets
	var found_valid := false
	for t in targets:
		if  (active_attack.target_unit & 1 != 0 and active_unit.is_enemy(t)) or \
			(active_attack.target_unit & 2 != 0 and not active_unit.is_enemy(t)) or \
			(active_attack.target_unit & 4 != 0 and active_unit == t):
			found_valid = true
			break
	if not found_valid:
		battle.play_error("No valid targets found.")
		return

	# make actions undoable past this point
	move_stack.clear()
	
	# attack signal
	_activate_attack.call_deferred(active_unit, active_attack, cell, targets)
	
	# cleanup
	set_can_move(active_unit, false)
	set_can_attack(active_unit, false)
	clear_active_unit()
	
	
func _activate_attack(unit: Unit, attack: Attack, target: Vector2i, targets: Array[Unit]):
	print("%s%s used %s" % [unit.name, battle.map.cell(unit.map_pos), attack.name], ": ", target, " ", targets)
	$UI/AttackName/Label.text = attack.name
	$UI/AttackName.visible = true
	set_ui_visible(false, false, false)
	
	# play animations
	for t in targets:
		t.model.play_animation(attack.target_animation)
	unit.model.play_animation(attack.cast_animation)
	
	# play attack sequence
	match attack.cast_animation:
		"attack", "buff", "heal":
			# add animation TODO custom scripted animation
			var pos := battle.map.world.uniform_to_screen(target)
			#pos = get_viewport_transform() * pos
			$AnimatedSprite2D.position = pos
			$AnimatedSprite2D.position.y -= 50
			$AnimatedSprite2D.play("default")
			
			await $AnimatedSprite2D.animation_finished
			$AnimatedSprite2D.stop()
			
	match attack.target_animation:
		"hurt", "buff", "heal":
			pass
			
	# apply attack effect
	for t in targets:
		_use_attack_on_target(unit, t, attack)
	
	# stop animations
	for t in targets:
		t.model.play_animation("idle")
		t.model.stop_animation() # TODO wouldn't have to do this if there's a reset
	unit.model.play_animation("idle")
	unit.model.stop_animation()

	$UI/AttackName.visible = false
	
	# This is a move (ATTACK), so check for end turn
	check_for_auto_end_turn()


func _use_attack_on_target(caster: Unit, target: Unit, attack: Attack):
	match attack.type_tag:
		"attack":
			battle.damage_unit(target, caster, caster.dmg)
		"heal":
			battle.damage_unit(target, caster, -caster.dmg)
		"other":
			pass
			
	if attack.status_effect != "None":
		var duration_table := {"PSN": 2, "STN": 1, "VUL": 2}
		var eff = Globals.status_effect[attack.status_effect]
		var dur = duration_table[attack.status_effect]
		
		target.add_status_effect(eff, dur)
	


## Walks the unit.
func walk_unit(unit: Unit, cell: Vector2i):
	# pre walk set-up
	battle.set_camera_follow(unit)
	if Globals.prefs.camera_follow_unit_move:
		battle.camera.drag_horizontal_enabled = false
		battle.camera.drag_vertical_enabled = false
	state_machine.set_process_unhandled_input(false)
	
	$UI.visible = false
	
	# walk
	var start := battle.map.cell(unit.map_pos)
	var end := cell
	var path := battle.unit_path._pathfinder.calculate_point_path(start, cell)
	await walk_along(unit, path)
		
	$UI.visible = true
	
	# post walk set-up
	state_machine.set_process_unhandled_input(true)
	battle.camera.drag_horizontal_enabled = true
	battle.camera.drag_vertical_enabled = true
	battle.set_camera_follow(battle.cursor)


## Pushes a move action.
func push_move_action():
	var action := UnitMoveAction.new()
	action.unit = active_unit
	action.cell = battle.map.cell(active_unit.map_pos)
	action.facing = active_unit.facing
	action.can_move = can_move(active_unit)
	action.can_attack = can_attack(active_unit)
	move_stack.append(action)
	

## Undo's an action.
func undo_move_action():
	if not move_stack.is_empty():
		var action = move_stack.pop_back()
		
		action.unit.map_pos = action.cell
		action.unit.facing = action.facing
		set_can_move(action.unit, action.can_move)
		set_can_attack(action.unit, action.can_attack)
		
		set_active_unit(action.unit)
		
		
################################################################################
## Basic functions
################################################################################

## Sets the active unit.
func set_active_unit(unit: Unit):
	set_ui_visible(true, can_attack(unit), is_owned(unit))
	
	if active_unit:
		clear_active_unit()
		
	unit.animation.play("highlight")
	
	active_unit = unit
	refresh_active()
	
	if is_owned(unit):
		if can_move(unit):
			draw_terrain_overlay(active_walkable, TERRAIN_GREEN, true)
		else:
			pass
	else:
		draw_terrain_overlay(active_walkable, TERRAIN_BLUE, true)
	
	
## Sets the active attack of the unit.
func set_active_attack(attack: Attack):
	battle.terrain_overlay.clear()
	battle.unit_path.clear()
	
	active_attack = attack
	refresh_active()
	
	if attack.target_melee:
		select_attack_target(active_unit, active_attack, null)
		
	set_ui_visible(true, false, null)
	
	draw_attack_overlay(active_unit, attack, battle.cursor.map_pos)
	

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
		set_ui_visible(false, false, false)
		
		# clear attack
		clear_active_attack()
		
		
## Clears the active attack.
func clear_active_attack():
	if active_attack:
		# clear stuff
		active_attack = null
		active_targetable.clear()
		
		# clear ui
		battle.terrain_overlay.clear()
		set_ui_visible(null, false, null)
	
	
## Refreshes cached data from active unit and attack.
func refresh_active():
	if active_unit:
		active_walkable = get_walkable_cells(active_unit)
		battle.unit_path.initialize(active_walkable)
		
	if active_attack:
		assert(active_unit)
		active_targetable = Globals.flood_fill(battle.map.cell(active_unit.map_pos), active_attack.range, Rect2i(Vector2i.ZERO, battle.map.world.map_size))
	
	
################################################################################
## Helper functions
################################################################################
	
## Checks for auto end turn
func check_for_auto_end_turn():
	if Globals.prefs.auto_end_turn:
		var units := battle.map.get_units().filter(func(o): return is_owned(o))
		var should_end := true
		
		for u in units:
			if can_move(u) or can_attack(u):
				should_end = false
				
		if should_end:
			end_turn.call_deferred()
			
	
## Makes the unit walk along a path.
func walk_along(unit: Unit, path: PackedVector2Array):
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
			drivers.add_child(driver)
			
			# run and wait for driver
			await driver.walk_along(path)
			
			# cleanup
			drivers.remove_child(driver)
			unit.remove_meta("Battle_driver")
			driver.queue_free()
	
	
## Makes the unit stop walking.
func stop_walking(unit: Unit):
	unit.get_meta("Battle_driver").stop_walking()
	

## Returns true if the unit is walking.
func is_walking(unit: Unit):
	return unit.has_meta("Battle_driver")
	
	
func can_move(unit: Unit) -> bool:
	return unit.get_meta("Battle_can_move", false)


func can_attack(unit: Unit) -> bool:
	return unit.get_meta("Battle_can_attack", false)


func set_can_move(unit: Unit, value: bool):
	unit.set_meta("Battle_can_move", value)
	
	
func set_can_attack(unit: Unit, value: bool):
	unit.set_meta("Battle_can_attack", value)
	
	
func is_owned(unit: Unit) -> bool:
	return unit.empire == battle.context.on_turn
	
	
## Returns true if pos is pathable.
func is_pathable(unit: Unit, cell: Vector2i) -> bool:
	for obj in battle.map.get_objects_at(cell):
		if not unit.can_path(obj):
			return false
	return true
	

## Returns true if this unit can be placed on pos.
func is_placeable(unit: Unit, cell: Vector2i) -> bool:
	if battle.map.cell(unit.map_pos) == cell:
		return true
	for obj in battle.map.get_objects_at(cell):
		if not unit.can_place(obj):
			return false
	return true


## Selects cell for attack target.
func select_attack_target(unit: Unit, attack: Attack, target: Variant):
	if attack.target_melee:
		match typeof(target):
			TYPE_VECTOR2, TYPE_VECTOR2I:
				active_unit.face_towards(target)
			TYPE_FLOAT, TYPE_INT:
				active_unit.facing = target
		if attack.range > 0:
			select_cell(unit.map_pos + Unit.Directions[unit.get_heading()] * attack.range)
		else:
			select_cell(unit.map_pos)
	else:
		select_cell(target)


## Returns a list of walkable cells.
func get_walkable_cells(unit: Unit) -> PackedVector2Array:
	var cond := func(p): return is_pathable(unit, p)
	var bounds := Rect2i(Vector2i.ZERO, battle.map.world.map_size)
	return Globals.flood_fill(battle.map.cell(unit.map_pos), unit.mov, bounds, cond)
	#return Globals.flood_fill(battle.map.cell(unit.map_pos), unit.mov, Rect2i(Vector2i.ZERO, battle.map.world.map_size),  func(p): return is_pathable(unit, p))
	

## Returns a list of targetable cells.
func get_targetable_cells(unit: Unit, attack: Attack) -> PackedVector2Array:
	return Globals.flood_fill(battle.map.cell(unit.map_pos), attack.range, Rect2i(Vector2i.ZERO, battle.map.world.map_size))
	
	
## Returns a list of targeted cells.
func get_attack_target_cells(unit: Unit, attack: Attack, target: Vector2i, target_rotation: float = 0) -> PackedVector2Array:
	if attack.target_melee:
		target_rotation = unit.get_heading() * PI/2
		
	var re := PackedVector2Array()
	for offs in attack.target_shape:
		var m := Transform2D()
		m = m.translated(offs)
		m = m.rotated(target_rotation)
		m = m.translated(target)
		re.append(battle.map.cell(m * Vector2.ZERO))
	return re
	
	
## Draws target overlay. target_rotation is ignored if melee.
func draw_attack_overlay(unit: Unit, attack: Attack, target: Vector2i, target_rotation: float = 0):
	battle.terrain_overlay.clear()
	
	var cells := Globals.flood_fill(battle.map.cell(unit.map_pos), attack.range, Rect2i(Vector2i.ZERO, battle.map.world.map_size))
	
	if not attack.target_melee:
		draw_terrain_overlay(cells, TERRAIN_RED, true)
	
	var target_cells := get_attack_target_cells(unit, attack, target, target_rotation)
	draw_terrain_overlay(target_cells, TERRAIN_BLUE, false)


## Draws terrain overlay.
func draw_terrain_overlay(cells: PackedVector2Array, idx := TERRAIN_GREEN, clear := false):
	if clear:
		battle.terrain_overlay.clear()
	for cell in cells:
		battle.terrain_overlay.set_cell(0, cell, 0, Vector2i(idx, 0), 0)
		
		
## Sets the visibility of ui elements.
func set_ui_visible(chara_info: Variant, attacks: Variant, undo_end: Variant):
	if chara_info != null:
		$UI/Name.visible = chara_info
		$UI/Portrait.visible = chara_info
	if attacks != null:
		$UI/AttackButton.visible = attacks
		$UI/SpecialButton.visible = attacks
	if undo_end != null:
		$UI/UndoButton.visible = undo_end
		$UI/EndTurnButton.visible = undo_end
		

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


class UnitMoveAction:
	var unit: Unit
	var cell: Vector2i
	var facing: float
	var can_move: bool
	var can_attack: bool
	

