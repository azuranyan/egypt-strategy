extends BattleAgent
class_name BattleAgentPlayer


signal prep_done


## The unit that's being rotated.
var heading_adjusted: Unit

## The selected unit.
var selected: Unit

## If selected was already in the board and is being moved.
var selected_moved := false

## The original position, if selected was moved.
var selected_original_pos := Vector2.ZERO

## Mouse offset for dragging.
var selected_offset := Vector2.ZERO

## A record of unit name -> unit.
var unit_map := {}


class BattleContext:
	pass


func initialize():
	# add the units to character list
	for type_name in empire.units:
		var unit := battle.spawn_unit(type_name, empire)
		add_unit_hooks(unit)
		battle.character_list.add_unit(type_name)
		
		# this way we don't lose a reference to the unit
		unit_map[type_name] = unit
	
	# configure character list
	battle.character_list.visible = true
	battle.character_list.unit_selected.connect(_on_character_list_unit_selected)
	battle.character_list.unit_released.connect(_on_character_list_unit_released)
	battle.character_list.unit_dragged.connect(_on_character_list_unit_dragged)
	battle.character_list.unit_cancelled.connect(_on_character_list_unit_cancelled)
	battle.character_list.unit_highlight_changed.connect(_on_character_list_unit_highlight_changed)
	
	# connect to battle
	battle.get_node('UI/DonePrep').pressed.connect(func(): prep_done.emit())
	#battle.get_node('UI/CancelPrep').pressed.connect(func(): prep_done.emit())
	
	# show the spawn points
	for o in battle.map.get_objects():
		if o.get_meta("spawn_point", "") == "player":
			o.no_show = false


func prepare_units():
	await prep_done


func do_turn():
	pass
	

func add_unit_hooks(unit: Unit):
	var on_button_down := func(button):
		match button:
			1:
				# if a unit that isn't selected is left clicked, select
				if unit != selected:
					selected = unit
					selected_moved = true
					selected_original_pos = unit.map_pos
					selected_offset = unit.map_pos - battle.map.world.screen_to_uniform(get_viewport().get_mouse_position())
			2:
				# if selected unit is right clicked, deselect
				if unit == selected:
					battle.set_unit_group(unit, 'units_standby')
					selected = null
					print('rmb')
			3:
				# if mmb is pressed on the unit, adjust heading
				heading_adjusted = unit
		
	var on_button_up := func(_button):
		pass
		
	unit.button_down.connect(on_button_down)
	unit.button_up.connect(on_button_up)
	
	
func _unhandled_input(event):
	if heading_adjusted:
		if event is InputEventMouseMotion:
			# make unit face the mouse
			var target = battle.map.world.screen_to_uniform(event.position, true)
			if heading_adjusted.map_pos != target:
				heading_adjusted.face_towards(target)
		
		if event is InputEventMouseButton:
			# clicking rmb cancels the movement and returns facing to default
			if event.button_index == 2:
				heading_adjusted.set_heading(Unit.Heading.West)
				
			# releasing mmb stops the heading adjustment interaction
			if event.button_index == 3 and not event.pressed:
				heading_adjusted = null
				
		# mark input as handled
		get_viewport().set_input_as_handled()
				
			
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
		if occupant:
			# if the unit is being moved, swap positions, otherwise take over
			if selected_moved:
				occupant.map_pos = selected_original_pos
			else:
				battle.set_unit_position(unit, Map.OUT_OF_BOUNDS)
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
		
