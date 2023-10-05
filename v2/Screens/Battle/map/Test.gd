@tool
extends Node2D

@onready var world := $Map.world as World
@onready var drivers := $Drivers
@onready var unit_path := $UnitPath as UnitPath
@onready var terrain_overlay := $TerrainOverlay as TileMap

@onready var cursor := $Map/Cursor as SpriteObject

@onready var map := $Map as Map


static func make_square_path(path: PackedVector2Array) -> PackedVector2Array:
	var re := PackedVector2Array()
	var prev := Vector2.ZERO
	
	re.append(prev)
	for p in path:
		if p.x != prev.x and p.y != prev.y:
			if p.x < p.y:
				re.append(Vector2(p.x, prev.y))
			else:
				re.append(Vector2(prev.x, p.y))
		re.append(p)
		prev = p
	return re


static func make_random_path(
		length: int,
		start: Vector2,
		min: Vector2,
		max: Vector2,
		square := true
		) -> PackedVector2Array:
	var re := PackedVector2Array()
	var prev := start
	
	re.append(prev)
	for i in length:
		var p := Vector2(randi_range(min.x, max.x), randi_range(min.y, max.y))
		if square:
			if p.x != prev.x and p.y != prev.y:
				if p.x < p.y:
					p = Vector2(p.x, prev.y)
				else:
					p = Vector2(prev.x, p.y)
		re.append(p)
		prev = p
	
	return re


var empire: Empire
func _ready():
	# TODO this doesnt work when set from editor because units are intended to
	# be created via code..
	$Map/Unit1.unit_type = preload("res://Screens/Battle/data/UnitType_Zahra.tres")
	$Map/Unit2.unit_type = preload("res://Screens/Battle/data/UnitType_Maia.tres")
	$Map/Unit3.unit_type = preload("res://Screens/Battle/data/UnitType_Lysandra.tres")
	
	empire = Empire.new() 
	$Map/Unit1.empire = empire
	$Map/Unit2.empire = empire
	$Map/Unit3.empire = null
	on_turn = empire
	
	set_can_move($Map/Unit1, true)
	set_can_move($Map/Unit2, true)
	set_can_attack($Map/Unit1, true)
	set_can_attack($Map/Unit2, true)
	
	set_camera_follow_target(cursor)
		
	
	var m := Transform2D()
	
	# scale to downsize to unit vector
	m = m.scaled(Vector2.ONE/Vector2(unit_path.tile_set.tile_size))
	if world:
		# scale to tile size
		m = m.scaled(Vector2(world.tile_size, world.tile_size))
		
	unit_path.transform = world._world_to_screen_transform * m

	unit_path.position = world.uniform_to_screen(Vector2(-0.5, -0.5))
	
#	var arr := []
#	arr.resize(world.map_size.x * world.map_size.y)
#	var n := 0
#	for j in world.map_size.y:
#		for i in world.map_size.x:
#			var vec := Vector2(i, j)
#			# TODO if pathable, do this else not pathable
#			print(n, " ", vec, " ", map.index(vec))
#			arr[map.index(vec)] = vec
#			n += 1
	$CanvasLayer/UI/UndoButton.pressed.connect(_cancel)
		
	add_unit_callbacks($Map/Unit1)
	add_unit_callbacks($Map/Unit2)
	
	if not Engine.is_editor_hint():
		test.call_deferred()


#func _input(event):
#	if event is InputEventMouseMotion:
#		var start := unit.map_pos
#		var end := world.screen_to_uniform(event.position)
#		unit_path.draw(start, end)
#
#	if event is InputEventMouseButton:
#		if event.button_index == 1 and event.pressed:
#			unit_path.initialize(get_walkable_cells(unit))
#			walk_towards(unit, world.screen_to_uniform(event.position))


## Directions.
const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]


func random_path(length: int) -> PackedVector2Array:
#	if driver.walking:
#		return make_random_path(length, unit.curve.get_point_out(unit.curve.point_count), Vector2.ZERO, world.map_size - Vector2i.ONE, true)
#	else:
	return make_random_path(length, $Map/Unit1.map_pos, Vector2.ZERO, world.map_size - Vector2i.ONE, true)


## Makes the unit walk towards a point.
func walk_towards(unit: Unit, end: Vector2):
	var start := unit.map_pos
	var path := unit_path._pathfinder.calculate_point_path(start, end)
	walk_along(unit, path)
	

## Makes the unit walk along a path.
func walk_along(unit: Unit, path: PackedVector2Array):
	if is_walking(unit):
		stop_walking(unit)
		
	match path.size():
		0, 1:
			walking_finished.emit(unit, false)
		_:
			# initialize driver
			var driver: UnitDriver = preload("res://Screens/Battle/map/UnitDriver.tscn").instantiate()
			driver.unit = unit
			unit.set_meta("driver", driver)
			drivers.add_child(driver)
			
			var old_pos := unit.map_pos
			var new_pos := path[-1]
			
			# run and wait for driver
			await driver.walk_along(path)
			
			# cleanup
			drivers.remove_child(driver)
			unit.remove_meta("driver")
			driver.queue_free()
			
			# TODO map bug workaround
			map.get_objects_at(old_pos).erase(unit)
			map.get_objects_at(new_pos).append(unit)
				
			walking_finished.emit(unit, driver.stopped)
	
	
## Makes the unit stop walking.
func stop_walking(unit: Unit):
	unit.get_meta("driver").stop_walking()
	

## Returns true if the unit is walking.
func is_walking(unit: Unit):
	return unit.has_meta("driver")
	
	
## Returns an array of walkable cells in range.
func get_walkable_cells(unit: Unit) -> PackedVector2Array:
	return _flood_fill(unit, map.cell(unit.map_pos), unit.mov)
	

func _flood_fill(unit: Unit, cell: Vector2, max_distance: int) -> PackedVector2Array:
	# TODO pos -> cells
	var re := PackedVector2Array()
	
	var stack := [cell]
	
	while not stack.is_empty():
		var current = stack.pop_back()
		
		# bounds check
		if not world.in_bounds(current):
			continue
		
		# dupe check
		if current in re:
			continue
			
		# distance check
		var diff: Vector2 = (current - cell).abs()
		var dist := int(diff.x + diff.y)
		if dist > max_distance:
			continue
			
		if not is_pathable(unit, current):
			continue
			
		re.append(current)
		
		for direction in DIRECTIONS:
			var coords: Vector2 = current + direction
			
			if not world.in_bounds(coords):
				continue
			
			#if map.is_occupied(coords):
			#	continue
			
			if coords in re:
				continue
			
			stack.append(coords)
	return re
	

func add_unit_callbacks(unit: Unit):
	var cb := func(button):
		if button == 1:
			unit_selected.emit(unit)
	unit.button_up.connect(cb)
	unit.set_meta("Map_unit_selected", cb)
	
	
func remove_unit_callbacks(unit: Unit):
	var cb = unit.get_meta("Map_unit_selected")
	unit.button_up.disconnect(cb)
	unit.remove_meta("Map_unit_selected")
	
	
func test():
	print("waiting for interact?")


signal unit_selected(unit: Unit)
signal rmb_pressed()
signal location_selected(pos: Vector2)
signal walking_finished(unit: Unit, cancelled: bool)


func _on_unit_selected(unit: Unit):
	pass


func _on_rmb_pressed():
	pass


func _on_location_selected(pos: Vector2):
	pass
			
			
func _on_walking_finished(unit: Unit, cancelled: bool):
	pass


## Returns true if pos is pathable.
func is_pathable(unit: Unit, pos: Vector2) -> bool:
	for obj in map.get_objects_at(pos):
		if not unit.can_path(obj):
			return false
	return true
	

## Returns true if this unit can be placed on pos.
func is_placeable(unit: Unit, pos: Vector2) -> bool:
	if map.cell(unit.map_pos) == map.cell(pos):
		return true
	for obj in map.get_objects_at(pos):
		if not unit.can_place(obj):
			return false
	return true
	

var active_unit: Unit
var active_cell: Vector2i
var active_facing: float
var active_walkable: PackedVector2Array

var active_attack: Attack
var active_target: PackedVector2Array
var active_targetable: PackedVector2Array

var change_facing: Unit

var unit_move_list: Array[Unit] = []
var unit_attack_list: Array[Unit] = []

var on_turn: Empire

var action_stack: Array = []

class UnitMoveAction:
	var unit: Unit
	var cell: Vector2i
	var facing: float
	var can_move: bool
	var can_attack: bool

class UnitAttackAction:
	var unit: Unit
	var cell: Vector2i
	var facing: float
	var attack: Attack
	

func _push_move_action():
	var action := UnitMoveAction.new()
	action.unit = active_unit
	action.cell = active_cell
	action.facing = active_facing
	action.can_move = can_move(active_unit)
	action.can_attack = can_attack(active_unit)
	action_stack.append(action)
	

func _push_attack_action():
	var action := UnitAttackAction.new()
	action.unit = active_unit
	action.cell = active_cell
	action.facing = active_facing
	action.attack = active_attack
	action_stack.append(action)


## Undo's an action.
func undo_action():
	if not action_stack.is_empty():
		var action = action_stack.pop_back()
		if action is UnitMoveAction:
			var old_pos: Vector2i = map.cell(action.unit.map_pos)
			var new_pos: Vector2i = action.cell
			
			action.unit.map_pos = action.cell
			action.unit.facing = action.facing
			
			# TODO map bug workaround
			map.get_objects_at(old_pos).erase(action.unit)
			map.get_objects_at(new_pos).append(action.unit)
				
			set_can_move(action.unit, action.can_move)
			set_can_attack(action.unit, action.can_attack)
			
			_set_active_unit(action.unit)
		elif action is UnitAttackAction:
			pass
		
	
## Commits the action, preventing undos.
func commit_action():
	action_stack.clear()


func can_move(unit: Unit) -> bool:
	return unit in unit_move_list
	
	
func can_attack(unit: Unit) -> bool:
	return unit in unit_attack_list
	
	
func set_can_move(unit: Unit, can: bool):
	if can:
		if unit not in unit_move_list:
			unit_move_list.append(unit)
	else:
		unit_move_list.erase(unit)
		
	
func set_can_attack(unit: Unit, can: bool):
	if can:
		if unit not in unit_attack_list:
			unit_attack_list.append(unit)
	else:
		unit_attack_list.erase(unit)
		
	
func _is_current_empire(unit: Unit) -> bool:
	return unit.empire == on_turn


func use_attack(unit: Unit, attack: Attack):
	# TODO cell should be Vector2i, change name
	var cell := Vector2(map.cell(unit.map_pos)) 
	
	clear_walkable_cells()
	
	commit_action()
	
	active_attack = attack
	active_target = attack.target_shape.duplicate()
	active_targetable = PackedVector2Array()
	
	# TODO duplicated flood fill code cos i got lazy
	var stack := [cell]
	while not stack.is_empty():
		var current = stack.pop_back()
		
		# bounds check
		if not world.in_bounds(current):
			continue
		
		# dupe check
		if current in active_targetable:
			continue
			
		# distance check
		var diff: Vector2 = (current - cell).abs()
		var dist := int(diff.x + diff.y)
		if dist > attack.range:
			continue
			
		active_targetable.append(current)
		
		for direction in DIRECTIONS:
			var coords: Vector2 = current + direction
			
			if not world.in_bounds(coords):
				continue
			
			if coords in active_targetable:
				continue
			
			stack.append(coords)
		
	draw_attack_cells(cursor.map_pos)
	
	# attack is engaged
	
func _select_cell(pos: Vector2):
	# TODO cell should be Vector2i, change name
	var cell := world.clamp_pos(Vector2(roundi(pos.x), roundi(pos.y)))
	var unit := map.get_object(cell, Map.Pathing.UNIT) as Unit
	
	# set cursor position
	cursor.map_pos = map.cell(Vector2(clamp(pos.x, -4, world.map_size.x + 3), clamp(pos.y, -4, world.map_size.y + 3)))
	
	if active_attack:
		draw_attack_cells(cursor.map_pos)
		return
	
	if active_unit:
		# draw path
		if is_placeable(active_unit, cell) and _is_current_empire(active_unit) and can_move(active_unit):
			unit_path.draw(active_cell, cell)
		else:
			unit_path.clear()
			
		# draw ui
		if unit and unit != active_unit:
			# show unit info
			$CanvasLayer/UI/Name/Label.text = unit.unit_type.name
			$CanvasLayer/UI/Portrait/Control/TextureRect.texture = unit.unit_type.chara.portrait
			set_ui_visible(true, false)
		else:
			if _is_current_empire(active_unit):
				# show extended info
				$CanvasLayer/UI/Name/Label.text = active_unit.unit_type.name
				$CanvasLayer/UI/Portrait/Control/TextureRect.texture = active_unit.unit_type.chara.portrait
				set_ui_visible(true, can_attack(active_unit))
	else:
		if unit:
			# show unit info
			$CanvasLayer/UI/Name/Label.text = unit.unit_type.name
			$CanvasLayer/UI/Portrait/Control/TextureRect.texture = unit.unit_type.chara.portrait
			set_ui_visible(true, false)
		else:
			# clear unit info
			$CanvasLayer/UI/Name/Label.text = ""
			$CanvasLayer/UI/Portrait/Control/TextureRect.texture = null
			set_ui_visible(false, false)
	

func _accept_cell():
	# TODO cell should be Vector2i, change name
	var cell := world.clamp_pos(Vector2(roundi(cursor.map_pos.x), roundi(cursor.map_pos.y)))
	var unit: Unit = map.get_object(cell, Map.Pathing.UNIT)
	
	if active_attack:
		if cell not in active_targetable:
			_play_error(true)
			return
		$CanvasLayer.visible = false
		# hide ui
		# face target
		# play hurt animation
		# await attack animation
		# attack signal
		print("attack ", active_attack.name)
		active_attack = null
		set_can_move(active_unit, false)
		set_can_attack(active_unit, false)
		_clear_active_unit()
		$CanvasLayer.visible = true
		return
		
	# unit selected
	if unit:
		if not active_unit or not can_move(active_unit):
			_set_active_unit(unit)
		else:
			if _is_current_empire(unit):
				if active_unit == unit:
					# if the selected cell is the same cell with the
					# active unit, just "move" it in place
					_push_move_action()
					set_can_move(active_unit, false)
					_clear_active_unit()
				else:
					# if same unit, swap
					_set_active_unit(unit)
			else:
				_play_error(true)
	
	# location selected
	else:
		# if we own the active unit and it hasnt moved yet, try moving
		if active_unit and _is_current_empire(active_unit):
			if can_move(active_unit):
				# check if target cell is valid
				if cell in active_walkable and is_pathable(active_unit, cell) and is_placeable(active_unit, cell): 
					walk_unit_action(active_unit, cell)
					_push_move_action()
					set_can_move(active_unit, false)
					_clear_active_unit()
				else:
					_play_error(true)
			else:
				if can_attack(active_unit):
					_play_error(true)
				else:
					_clear_active_unit()
		# no active unit, not owned, or has already moved
		else:
			_clear_active_unit()
	
func _cancel():
	# if the action we want to undo is from a different unit, 
	# cancel active unit first
	if active_attack:
		active_attack = null
		draw_walkable_cells(active_walkable)
	elif active_unit:
		_clear_active_unit()
	else:
		undo_action()
	
# TODO have consistency in cells and pos

func _play_error(overlap := false):
	if overlap or not $AudioStreamPlayer2D.is_playing():
		$AudioStreamPlayer2D.stream = preload("res://error-126627.wav")
		$AudioStreamPlayer2D.play()


func walk_unit_action(unit: Unit, cell: Vector2i):
	# pre walk set-up
	set_camera_follow_target(unit)
	if Globals.prefs.camera_follow_unit_move:
		camera.drag_horizontal_enabled = false
		camera.drag_vertical_enabled = false
	set_process_unhandled_input(false)
	
	$CanvasLayer.visible = false
	
	# walk
	var start := map.cell(unit.map_pos)
	var end := cell
	var path := unit_path._pathfinder.calculate_point_path(start, cell)
	await walk_along(unit, path)
		
	$CanvasLayer.visible = true
	
	# post walk set-up
	set_process_unhandled_input(true)
	camera.drag_horizontal_enabled = true
	camera.drag_vertical_enabled = true
	set_camera_follow_target(cursor)

		
		
func _set_active_unit(unit: Unit):
	if active_unit:
		_clear_active_unit()
	unit.animation.play("highlight")
	active_unit = unit
	active_cell = map.cell(unit.map_pos)
	active_facing = unit.facing
	
	active_walkable = get_walkable_cells(unit)
	unit_path.initialize(active_walkable)
	
	if _is_current_empire(unit):
		if can_move(unit):
			draw_terrain_overlay(active_walkable, TERRAIN_GREEN, true)
		else:
			pass
	else:
		draw_terrain_overlay(active_walkable, TERRAIN_BLUE, true)
		
func _clear_active_unit():
	if active_unit:
		active_unit.animation.play("RESET")
		active_unit.animation.stop()
		active_unit = null
		clear_walkable_cells()
		
		
func set_ui_visible(portrait: bool, actions: bool):
	$CanvasLayer/UI/Name.visible = portrait
	$CanvasLayer/UI/Portrait.visible = portrait
	$CanvasLayer/UI/AttackButton.visible = actions
	$CanvasLayer/UI/SpecialButton.visible = actions
	#$CanvasLayer/UI/UndoButton.visible = actions
	#$CanvasLayer/UI/EndTurnButton.visible = actions


enum {
	TERRAIN_WHITE,
	TERRAIN_BLUE,
	TERRAIN_GREEN,
	TERRAIN_RED,
}

func draw_walkable_cells(cells: PackedVector2Array):
	draw_terrain_overlay(cells, TERRAIN_GREEN, true)
	
	
func draw_attack_cells(target: Vector2i):
	var target_rotation := 0.0
	
	if active_attack.target_melee:
#		var c := cursor.map_pos - active_unit.map_pos
#		if c.x > c.y:
#			target.y = active_unit.map_pos.y
#		else:
#			target.x = active_unit.map_pos.x
#		#target = active_unit.map_pos + Unit.Directions[active_unit.get_heading()] * cursor.map_pos
		target_rotation = active_unit.get_heading() * PI/2
	
	draw_attack_cells0(active_targetable, target, active_attack.target_shape, target_rotation)
	
		
	
func draw_attack_cells0(cells: PackedVector2Array, target: Vector2i, target_shape: PackedVector2Array, target_rotation: float):
	draw_terrain_overlay(cells, TERRAIN_RED, true)
	
	for offs in target_shape:
		var m := Transform2D()
		m = m.translated(offs)
		m = m.rotated(target_rotation)
		m = m.translated(target)
		terrain_overlay.set_cell(0, map.cell(m * Vector2.ZERO), 0, Vector2i(TERRAIN_BLUE, 0), 0)
		

func draw_terrain_overlay(cells: PackedVector2Array, idx := TERRAIN_GREEN, clear := false):
	if clear:
		terrain_overlay.clear()
	for cell in cells:
		terrain_overlay.set_cell(0, Vector2i(cell), 0, Vector2i(idx, 0), 0)


func clear_walkable_cells():
	terrain_overlay.clear()
	unit_path.clear()
	
	
@onready var camera := $Camera2D as Camera2D

func set_camera_follow_target(obj: MapObject):
	if camera.has_meta("battle_target"):
		camera.get_meta("battle_target").map_pos_changed.disconnect(camera.get_meta("battle_follow_func"))
		camera.set_meta("battle_follow_func", null)
		camera.set_meta("battle_target", null)
		
	if obj:
		var follow_func := func():
			camera.position = world.uniform_to_screen(obj.map_pos)
		obj.map_pos_changed.connect(follow_func)
		
		camera.set_meta("battle_follow_func", follow_func)
		camera.set_meta("battle_target", obj)


func _unhandled_input(event):
	# Make input local, imporant because we're using a camera
	event = make_input_local(event)
	
	# TODO transform to inputs
	if active_attack:
		# accept
		if event is InputEventMouseButton and event.button_index == 1 or \
			event is InputEventKey and (event.keycode == KEY_KP_1 or event.keycode == KEY_ENTER) and event.pressed:
			_accept_cell()
			return
		
		# cancel
		if event is InputEventMouseButton and event.button_index == 2 or \
			event is InputEventKey and (event.keycode == KEY_ESCAPE) and event.pressed:
			_cancel()
			return
		
		if active_attack.target_melee:
			var target := cursor.map_pos
			if event is InputEventMouseMotion:
				target = world.screen_to_uniform(event.position)
				if active_unit.map_pos.distance_to(target) > 0.6:
					active_unit.face_towards(target)
				
				var c := (target - active_unit.map_pos).abs()
				if c.x > c.y:
					target.y = active_unit.map_pos.y
				else:
					target.x = active_unit.map_pos.x
					
			elif event is InputEventKey and event.pressed:
				var d := active_unit.map_pos.distance_to(target)
				match event.keycode:
					KEY_W:
						if target.x == active_unit.map_pos.x and (target.y - 1 != active_unit.map_pos.y):
							target.y -= 1
						else:
							target.x = active_unit.map_pos.x
							target.y = active_unit.map_pos.y - d
							active_unit.set_heading(Unit.Heading.North)
					KEY_S:
						if target.x == active_unit.map_pos.x and (target.y + 1 != active_unit.map_pos.y):
							target.y += 1
						else:
							target.x = active_unit.map_pos.x
							target.y = active_unit.map_pos.y + d
							active_unit.set_heading(Unit.Heading.South)
					KEY_A:
						if target.y == active_unit.map_pos.y and (target.x - 1 != active_unit.map_pos.x):
							target.x -= 1
						else:
							target.x = active_unit.map_pos.x - d
							target.y = active_unit.map_pos.y 
							active_unit.set_heading(Unit.Heading.West)
					KEY_D:
						if target.y == active_unit.map_pos.y and (target.x + 1 != active_unit.map_pos.x):
							target.x += 1
						else:
							target.x = active_unit.map_pos.x + d
							target.y = active_unit.map_pos.y
							active_unit.set_heading(Unit.Heading.East)
#
			_select_cell(target)
#			_select_cell(active_unit.map_pos + Unit.Directions[active_unit.get_heading()])
			
		else:
			if event is InputEventMouseMotion:
				_select_cell(world.screen_to_uniform(event.position))
			elif event is InputEventKey and event.pressed:
				match event.keycode:
					KEY_W:
						_select_cell(cursor.map_pos + Vector2(0, -1))
					KEY_S:
						_select_cell(cursor.map_pos + Vector2(0, +1))
					KEY_A:
						_select_cell(cursor.map_pos + Vector2(-1, 0))
					KEY_D:
						_select_cell(cursor.map_pos + Vector2(+1, 0))
			
		return
	
	
	# Mouse input
	if event is InputEventMouseMotion:
		if change_facing:
			if change_facing and _is_current_empire(change_facing) and can_attack(change_facing):
				var target := world.screen_to_uniform(event.position)
				if change_facing.map_pos.distance_to(target) > 0.6:
					change_facing.face_towards(target)
		else:
			_select_cell(world.screen_to_uniform(event.position))
		
	# Mouse button input
	elif event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				1:
					_select_cell(map.cell(world.screen_to_uniform(event.position)))
					_accept_cell()
				2:
					_cancel()
				3:
					change_facing = map.get_object(world.screen_to_uniform(event.position), Map.Pathing.UNIT)
		else:
			match event.button_index:
				3:
					change_facing = null
					
	# Key input
	elif event is InputEventKey:
		if event.keycode == KEY_KP_2:
			if event.pressed:
				change_facing = map.get_object(cursor.map_pos, Map.Pathing.UNIT)
			else:
				change_facing = null
			return
		
		if event.pressed:
			if change_facing and _is_current_empire(change_facing) and can_attack(change_facing):
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
				match event.keycode:
					KEY_W:
						_select_cell(cursor.map_pos + Vector2(0, -1))
					KEY_S:
						_select_cell(cursor.map_pos + Vector2(0, +1))
					KEY_A:
						_select_cell(cursor.map_pos + Vector2(-1, 0))
					KEY_D:
						_select_cell(cursor.map_pos + Vector2(+1, 0))
					KEY_KP_1, KEY_ENTER:
						_select_cell(cursor.map_pos)
						_accept_cell()
					KEY_ESCAPE:
						_cancel()
				


func _on_attack_button_pressed():
	use_attack(active_unit, active_unit.unit_type.basic_attack)


func _on_special_button_pressed():
	use_attack(active_unit, active_unit.unit_type.special_attack)
