@tool
extends Node2D

@onready var world := $Map.world as World
@onready var unit := $Map/Unit as Unit
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



func _ready():
	# TODO this doesnt work when set from editor
	unit.unit_type = preload("res://Screens/Battle/data/UnitType_Lysandra.tres")
	$Map/Unit2.unit_type = preload("res://Screens/Battle/data/UnitType_Maia.tres")
	$Map/Unit3.unit_type = preload("res://Screens/Battle/data/UnitType_Zahra.tres")
	
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
	
	var arr := get_walkable_cells(unit)
	unit_path.initialize(arr)
	
	add_unit_callbacks(unit)
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
	return make_random_path(length, unit.map_pos, Vector2.ZERO, world.map_size - Vector2i.ONE, true)


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

class Context:
	var state := STATE_IDLE
	var unit: Unit
	var old_pos: Vector2
	var old_facing: float
	var walkable: PackedVector2Array
	
	var location_selected: Vector2
	var location_hovered: Vector2
	

var context := Context.new()

enum {
	STATE_IDLE,
	STATE_UNIT_SELECTED,
	STATE_WALKING,
	STATE_DONE,
}

class UnitMoveAction:
	var unit: Unit
	var pos: Vector2
	var facing: float


func _transition_to(state: int, kwargs: Dictionary = {}):
	_on_exit(context.state, kwargs)
	context.state = state
	_on_enter(context.state, kwargs)


func _on_enter(state: int, kwargs: Dictionary):
	match state:
		STATE_IDLE:
			pass
			
		STATE_UNIT_SELECTED:
			var walkable := get_walkable_cells(kwargs.unit)
			
			kwargs.unit.animation.play("highlight")
			
			unit_path.initialize(walkable)
			
			for pos in walkable:
				terrain_overlay.set_cell(0, Vector2i(pos), 0, Vector2i(0, 0), 0)
			
			context.unit = kwargs.unit
			context.old_pos = kwargs.unit.map_pos
			context.old_facing = kwargs.unit.facing
			context.walkable = walkable
		
		STATE_WALKING:
			walk_towards(context.unit, context.location_selected)
			
		STATE_DONE:
			# TODO place somewhere appropriate
			map.get_objects_at(context.old_pos).erase(context.unit)
			map.get_objects_at(context.unit.map_pos).append(context.unit)
			
			context.unit = null
			context.old_pos = Vector2.ZERO
			context.old_facing = 0
			context.walkable = []
			
			# TODO commit_action
			
			_transition_to.call_deferred(STATE_IDLE)
			
			
func _on_exit(state: int, kwargs: Dictionary):
	match state:
		STATE_IDLE:
			pass
			
		STATE_UNIT_SELECTED:
			context.unit.animation.stop()
			unit_path.clear()
			terrain_overlay.clear()
			
		STATE_WALKING:
			pass
			
		STATE_DONE:
			pass


func _on_unit_selected(unit: Unit):
#	print("selected ", unit)
#	if context.state == STATE_IDLE:
#		print("  %s == %s? %s" % [context.unit, unit, context.unit == unit])
#		if context.unit == unit:
#			print("  same unit")
#		else:
#			print("  transition")
#			_transition_to(STATE_UNIT_SELECTED, {unit=unit})
	pass


func _on_rmb_pressed():
#	match context.state:
#		STATE_IDLE:
#			# TODO pop action
#			pass
#
#		STATE_UNIT_SELECTED:
#			#_transition_to(STATE_IDLE)
#			_transition_to(STATE_DONE)
#
#		STATE_WALKING:
#			stop_walking(context.unit)
#
#		STATE_DONE:
#			_transition_to(STATE_IDLE)
#			unit.map_pos = context.old_pos
#			unit.facing = context.old_facing
	pass


func _on_location_selected(pos: Vector2):
#	if context.state == STATE_UNIT_SELECTED:
#		if pos == context.old_pos:
#			pass
#			#_transition_to(STATE_DONE)
#		else:
#			_transition_to(STATE_WALKING)
	pass
			
			
func _on_walking_finished(unit: Unit, cancelled: bool):
#	if cancelled:
#		unit.map_pos = context.old_pos
#		unit.facing = context.old_facing
#		_transition_to(STATE_UNIT_SELECTED, {unit=unit})
#	else:
#		_transition_to(STATE_DONE)
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
		return false
	for obj in map.get_objects_at(pos):
		if not unit.can_place(obj):
			return false
	return true
	



#func _input(event):
#	match context.state:
#		STATE_IDLE:
#			pass
#
#		STATE_UNIT_SELECTED:
#			if event is InputEventMouseMotion:
#				var end := world.screen_to_uniform(event.position, true)
#				if end != context.location_hovered:
#					if end != context.old_pos and \
#							end in context.walkable and \
#							is_placeable(context.unit, end):
#						var start := context.old_pos
#						unit_path.draw(start, end)
#					else:
#						unit_path.clear()
#					context.location_hovered = end
#
#			if event is InputEventMouseButton:
#				if event.button_index == 1 and event.pressed:
#					var pos := world.screen_to_uniform(event.position, true)
#					if pos in context.walkable and is_placeable(context.unit, pos):
#						context.location_selected = pos
#						location_selected.emit(pos)
#
#		STATE_WALKING:
#			pass
#
#		STATE_DONE:
#		
class UnitBattleInfo:
	var unit: Unit
	var has_moved: bool
	var has_attacked: bool
	
	
func _is_current_empire(unit: Unit) -> bool:
	# TODO to be replaced with real code
	#return unit.empire == context.current
	return unit != $Map/Unit3


	
func _select_cell(pos: Vector2):
	var cell := world.clamp_pos(Vector2(roundi(pos.x), roundi(pos.y)))
	var unit := map.get_object(cell, Map.Pathing.UNIT) as Unit
	
	cursor.map_pos = cell
	
	if active_unit_action:
		if unit and unit != active_unit_action.unit:
			# show unit info
			$CanvasLayer/UI/Name/Label.text = unit.unit_type.name
			$CanvasLayer/UI/Portrait/Control/TextureRect.texture = unit.unit_type.chara.portrait
			set_ui_visible(true, false)
			
		else:
			if _is_current_empire(active_unit_action.unit):
				# show extended info
				$CanvasLayer/UI/Name/Label.text = active_unit_action.unit.unit_type.name
				$CanvasLayer/UI/Portrait/Control/TextureRect.texture = active_unit_action.unit.unit_type.chara.portrait
				set_ui_visible(true, true)
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
	

	
# TODO have consistency in cells and pos

func _play_error(overlap := false):
	if overlap or not $AudioStreamPlayer2D.is_playing():
		$AudioStreamPlayer2D.stream = preload("res://error-126627.wav")
		$AudioStreamPlayer2D.play()


func walk_unit_action(unit: Unit, target: Variant):
	set_camera_follow_target(unit)
	if Globals.prefs.camera_follow_unit_move:
		camera.drag_horizontal_enabled = false
		camera.drag_vertical_enabled = false
	set_process_unhandled_input(false)
	
	if target is Unit:
		var path := unit_path._pathfinder.calculate_point_path(map.cell(unit.map_pos), target.map_pos)
		path.resize(path.size() - 1)
		if path.size() == 1:
			unit.face_towards(target.map_pos)
		await walk_along(unit, path)
	
	if target is Vector2i:
		var path := unit_path._pathfinder.calculate_point_path(map.cell(unit.map_pos), target)
		await walk_along(unit, path)
		
	if target is Vector2:
		var path := unit_path._pathfinder.calculate_point_path(map.cell(unit.map_pos), map.cell(target))
		await walk_along(unit, path)
		
	set_process_unhandled_input(true)
	camera.drag_horizontal_enabled = true
	camera.drag_vertical_enabled = true
	set_camera_follow_target(cursor)

func _accept_cell():
	var cell := world.clamp_pos(Vector2(roundi(cursor.map_pos.x), roundi(cursor.map_pos.y)))
	var unit: Unit = map.get_object(cell, Map.Pathing.UNIT)
	
	# unit selected
	if unit:
		if active_unit_action and _is_current_empire(active_unit_action.unit) and not _is_current_empire(unit):
			# if there's an active unit is owned and target is valid, move
			walk_unit_action(active_unit_action.unit, unit)
			_clear_active_unit()
		else:
			# otherwise just switch selection to that unit
			_set_active_unit(unit)
	
	# location selected
	else:
		if active_unit_action and _is_current_empire(active_unit_action.unit):
			# if there's an active unit and it's owned, try moving
			if cell in active_unit_action.walkable and \
					is_pathable(active_unit_action.unit, cell) and \
					is_placeable(active_unit_action.unit, cell): 
				# if there's an active unit is owned and target is valid, move
				walk_unit_action(active_unit_action.unit, cell)
				_clear_active_unit()
			else:
				# otherwise just play an error
				_play_error(true)
		else:
			# if there's no active unit or it is not owned, clear it
			_clear_active_unit()
		
		
func _set_active_unit(unit: Unit):
	if active_unit_action:
		_clear_active_unit()
	unit.animation.play("highlight")
	active_unit_action = UnitAction.new()
	active_unit_action.unit = unit
	active_unit_action.map_pos = unit.map_pos
	active_unit_action.facing = unit.facing
	active_unit_action.has_moved = false
	active_unit_action.has_attacked = false
	
	active_unit_action.walkable = get_walkable_cells(unit)
	
	draw_walkable_cells(active_unit_action.walkable, _is_current_empire(unit))
	
	
func _reset_active_unit():
	if active_unit_action:
		active_unit_action.unit.map_pos = active_unit_action.map_pos
		active_unit_action.unit.facing = active_unit_action.facing
	
		
func _clear_active_unit():
	if active_unit_action:
		active_unit_action.unit.animation.play("RESET")
		active_unit_action.unit.animation.stop()
		active_unit_action = null
		clear_walkable_cells()
	

func _set_walk_enable(enable: bool):
	if enable:
		var walkable := get_walkable_cells(active_unit_action.unit)
		
		unit_path.initialize(walkable)
		
		for pos in walkable:
			terrain_overlay.set_cell(0, Vector2i(pos), 0, Vector2i(0, 0), 0)
			
		active_unit_action.walkable = walkable
	else:
		unit_path.clear()
		terrain_overlay.clear()
		
		active_unit_action.walkable.clear()
		
		
func set_ui_visible(portrait: bool, actions: bool):
	$CanvasLayer/UI/Name.visible = portrait
	$CanvasLayer/UI/Portrait.visible = portrait
	$CanvasLayer/UI/Move.visible = actions
	$CanvasLayer/UI/Attack.visible = actions
	$CanvasLayer/UI/Special.visible = actions
	$CanvasLayer/UI/Undo.visible = actions
	$CanvasLayer/UI/EndTurn.visible = actions


func draw_walkable_cells(cells: PackedVector2Array, show_path: bool):
	for pos in cells:
		terrain_overlay.set_cell(0, Vector2i(pos), 0, Vector2i(0, 0), 0)
	if show_path:
		unit_path.initialize(cells)
	
		
func clear_walkable_cells():
	terrain_overlay.clear()
	unit_path.stop()
	
	
@onready var camera := $Camera2D as Camera2D

func set_camera_follow_target(obj: MapObject):
	if camera.get_meta("target", null):
		obj.map_pos_changed.disconnect(camera.get_meta("follow_func"))
		camera.set_meta("follow_func", null)
		camera.set_meta("target", null)
		
	if obj:
		var follow_func := func():
			camera.position = world.uniform_to_screen(obj.map_pos)
		obj.map_pos_changed.connect(follow_func)
		
		camera.set_meta("follow_func", follow_func)
		camera.set_meta("target", obj)


class UnitAction:
	var unit: Unit
	var map_pos: Vector2
	var facing: float
	var has_moved: bool
	var has_attacked: bool
	var walkable: PackedVector2Array
	
var active_unit_action: UnitAction

func _unhandled_input(event):
	
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_W:
					_select_cell(cursor.map_pos + Vector2(0, -1))
				KEY_S:
					_select_cell(cursor.map_pos + Vector2(0, +1))
				KEY_A:
					_select_cell(cursor.map_pos + Vector2(-1, 0))
				KEY_D:
					_select_cell(cursor.map_pos + Vector2(+1, 0))
				KEY_ESCAPE:
					#_reset_active_unit()
					#_clear_active_unit()
					#rmb_pressed.emit()
					pass
	
	if event is InputEventMouseButton:
		event = make_input_local(event)
		if event.pressed:
			match event.button_index:
				1:
					_select_cell(map.cell(world.screen_to_uniform(event.position)))
					_accept_cell()
				2:
					#_reset_active_unit()
					#_clear_active_unit()
					#rmb_pressed.emit()
					pass
				
	if event is InputEventMouseMotion:
		event = make_input_local(event)
		_select_cell(world.screen_to_uniform(event.position))
