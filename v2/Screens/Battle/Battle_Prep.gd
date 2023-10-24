extends State

# Prep state

var battle: Battle

var prep_queue: Array = []
var prep: Empire
		
		
var dragging := false
var selected: Unit
var selected_moved := false
var selected_original_pos := Vector2.ZERO
var selected_offset := Vector2.ZERO
var heading_adjusted: Unit


func handle_input(event: InputEvent) -> void:
	if heading_adjusted:
		if event is InputEventMouseMotion:
			var target = battle.map.world.screen_to_uniform(get_global_mouse_position(), true)
			
			if heading_adjusted.map_pos != target:
				heading_adjusted.face_towards(target)
			
		if event is InputEventMouseButton:
			if event.button_index == 2:
				heading_adjusted.set_heading(Unit.Heading.West)
				
			if event.button_index == 3 and !event.pressed:
				heading_adjusted = null
			
	if selected:
		if event is InputEventMouseMotion:
			#pos = battle.viewport.canvas_transform.affine_inverse() * pos
			selected.map_pos = battle.map.world.screen_to_uniform(event.position) + selected_offset
		
#			var closest_snap_point := Vector2(roundi(selected.map_pos.x), roundi(selected.map_pos.y))
#			var snap_distance := 0.75
#
#			print(selected.map_pos, " ", closest_snap_point, " ", selected.map_pos.distance_to(closest_snap_point))
#			if selected.map_pos.distance_to(closest_snap_point) > snap_distance:
#				selected.snap_to_grid()
#			print(selected.map_pos, " ", can_spawn(selected, selected.map_pos))
			
			if can_spawn(selected, selected.map_pos):
				selected.animation.play("RESET")
			else:
				selected.animation.play("highlight_red")
			
		if event is InputEventMouseButton and !event.is_pressed() and event.button_index == 1:
			battle.character_list.get_button(selected.unit_name).release()
	

func enter(kwargs := {}) -> void:
	print("enter prep")
	battle = kwargs.battle
	prep_queue.append_array(kwargs.prep_queue)
	
	prep = prep_queue.pop_front()
	
	$UI/Prep.text = "Prep: %s" % prep.leader.name
	
	# add the units to character list
	for u in prep.units:
		# TODO we're creating all units instead of just the necessary ones
		var unit := battle.spawn_unit(u, prep, "", Map.OUT_OF_BOUNDS)
		_add_unit(unit.name, Map.OUT_OF_BOUNDS)
		battle.character_list.add_unit(u)
	battle.character_list.visible = true
	
	# show the spawn points
	for o in battle.map.get_objects():
		if o.get_meta("spawn_point", "") == "player":
			o.no_show = false
			
	# todo context and delete
	dragging = false
	selected = null
	selected_moved = false
	selected_original_pos = Vector2.ZERO
	selected_offset = Vector2.ZERO
	heading_adjusted = null
		

func done() -> void:
	state_machine.transition_to("Idle", {battle=battle})


func exit() -> void:
	for u in prep.units:
		_remove_unit(u, _get_unit(u).map_pos)
		battle.character_list.remove_unit(u)
		
	for o in battle.map.get_objects():
		if o.get_meta("spawn_point", "") == "player":
			o.no_show = true
			
	$UI.visible = false
	
	prep = null
	battle.character_list.visible = false
	
	# todo context and delete
	dragging = false
	selected = null
	selected_moved = false
	selected_original_pos = Vector2.ZERO
	selected_offset = Vector2.ZERO
	heading_adjusted = null
	print("EXIT PREP")
	

func can_spawn(unit: Unit, pos: Vector2) -> bool:
	pos = battle.map.cell(pos)
	if !battle.map.is_inside_bounds(pos):
		return false
		
	var objs := battle.map.get_objects_at(pos)
	
	# can spawn iff on a spawn point, regardless of what's there;
	# it's not for this function to check or care
	for obj in objs:
		if is_unit_spawn_point(unit, obj):
			return true
			
	return false
	
	#var obj := battle.map.get_object_at(pos)
	
	#return obj != null and is_unit_spawn_point(unit, obj)


func is_unit_spawn_point(unit: Unit, obj: MapObject) -> bool:
	if unit.empire.is_player_owned():
		return obj.get_meta("spawn_point", "") == "player"
	else:
		return obj.get_meta("spawn_point", "") == "ai"


func _get_unit(unit: String) -> Unit:
	for u in battle.map.get_units():
		if u.name == unit:
			return u
	return null


## Adds unit. Should be used within interactions.
func _add_unit(unit_name: String, pos := Map.OUT_OF_BOUNDS):
	var unit := _get_unit(unit_name)
	
	var cb = [null, null]
	cb[0] = func(button: int):
		match button:
			1:
				if unit != selected:
					selected = unit
					selected_moved = true
					selected_original_pos = unit.map_pos
					selected_offset = unit.map_pos - battle.map.world.screen_to_uniform(get_global_mouse_position())
			2:
				unit
			3:
				heading_adjusted = unit
		
	cb[1] = func(_button: int):
		pass
	
	# inject callbacks
	unit.button_down.connect(cb[0])
	unit.button_up.connect(cb[1])
	unit.set_meta("prep_phase_callbacks", cb)
	
	unit.map_pos = pos
	battle.set_unit_group(unit, 'units_standby' if pos == Map.OUT_OF_BOUNDS else 'units_alive')
	

## Removes unit. Should be used within interactions.
func _remove_unit(unit_name: String, pos := Map.OUT_OF_BOUNDS):
	var unit := _get_unit(unit_name)
	
	unit.map_pos = pos
	battle.set_unit_group(unit, 'units_standby' if pos == Map.OUT_OF_BOUNDS else 'units_alive')

	# remove callbacks
	# TODO this sometimes complains about not having callbacks, meaning a unit
	# is removed without being added. check that root problem.
	if unit.has_meta("prep_phase_callbacks"):
		var cb = unit.get_meta("prep_phase_callbacks", null)
		unit.button_down.disconnect(cb[0])
		unit.button_up.disconnect(cb[1])
		unit.remove_meta("prep_phase_callbacks")
	

func _on_character_list_unit_selected(unit: String, pos: Vector2):
	pos = battle.viewport.canvas_transform.affine_inverse() * pos
	
	selected = _get_unit(unit)
	selected_moved = false
	selected_original_pos = Vector2.ZERO
	selected_offset = Vector2.ZERO
	
	if heading_adjusted:
		heading_adjusted.set_heading(Unit.Heading.West)
		heading_adjusted = null
	
	_add_unit(unit, battle.map.world.screen_to_uniform(pos))
	
	_get_unit(unit).modulate = Color(1, 1, 1, 0.5)
	

func _on_character_list_unit_released(unit: String, pos: Vector2):
	pos = battle.viewport.canvas_transform.affine_inverse() * pos
	
	_get_unit(unit).snap_to_grid()
	var o_pos := _get_unit(unit).map_pos
		
	# remove the unit temporarily. if we can spawn there, add it again
	_remove_unit(unit)
	if can_spawn(_get_unit(unit),o_pos):
		print("can spawn ", unit, " at ", o_pos)
		#var unit2 := battle.map.get_object_at(_get_unit(unit).map_pos, false) as Unit
		var unit2: Unit = null
		for u in battle.get_units():
			if u != _get_unit(unit) and u.map_pos == o_pos:
				unit2 = u
				break
		if unit2:
			if selected_moved:
				unit2.map_pos = selected_original_pos
			else:
				_remove_unit(unit2.unit_name)
		_add_unit(unit, o_pos)
	else:
		print("cant spawn ", unit, " at ", o_pos)
		
	_get_unit(unit).animation.play("RESET")
	_get_unit(unit).modulate = Color(1, 1, 1, 1)
	
	selected = null
	if selected_moved:
		selected_moved = false


func _on_character_list_unit_dragged(unit: String, pos: Vector2):
	pos = battle.viewport.canvas_transform.affine_inverse() * pos
	
	var mp := battle.map.world.screen_to_uniform(pos)
	_get_unit(unit).map_pos = mp
	
	if can_spawn(_get_unit(unit), mp):
		_get_unit(unit).animation.play("RESET")
	else:
		_get_unit(unit).animation.play("highlight_red")
		
	_get_unit(unit).visible = true


func _on_character_list_unit_cancelled(unit: String):
	_remove_unit(unit)
	selected = null


func _on_character_list_unit_highlight_changed(unit: String, value: bool):
	if value:
		_get_unit(unit).animation.play("highlight")
	else:
		_get_unit(unit).animation.play("RESET")
