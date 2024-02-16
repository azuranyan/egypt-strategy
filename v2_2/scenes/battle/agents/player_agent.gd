extends BattleAgent


var battle: Battle
var rotated_unit: Unit
var repositioned_unit: Unit
var spawn_points: Array[SpawnPoint]
var unit_drag_start: Vector2
var unit_drag_offset: Vector2


func _process(_delta):
	if rotated_unit:
		const ROTATION_DEADZONE := 0.2
		var mpos := battle.world().as_uniform(get_viewport().get_mouse_position())
		if rotated_unit.get_position().distance_squared_to(mpos) >= ROTATION_DEADZONE*ROTATION_DEADZONE:
			rotated_unit.face_towards(mpos)

	if repositioned_unit:
		repositioned_unit.set_global_position(get_viewport().get_mouse_position() + unit_drag_offset)
		

## Called on initialize.
func _initialize():
	battle = Game.battle
	battle.hud().end_button.pressed.connect(_on_end_pressed)
	battle.hud().undo_button.pressed.connect(_on_undo_pressed)
	battle.hud().prep_unit_list.unit_selected.connect(_on_prep_unit_selected)
	battle.hud().prep_unit_list.unit_released.connect(_on_prep_unit_released)
	battle.hud().prep_unit_list.unit_dragged.connect(_on_prep_unit_dragged)
	battle.hud().prep_unit_list.cancelled.connect(_on_prep_cancelled)

	spawn_points = battle.get_spawn_points(SpawnPoint.Type.PLAYER)


## Called on start preparation.
func _enter_prepare_units():
	# make units unselectable until they're added from play
	for id in Game.unit_registry:
		var u: Unit = Game.unit_registry[id]
		if not u.interacted.is_connected(_on_unit_interacted.bind(u)):
			u.interacted.connect(_on_unit_interacted.bind(u))
	
	
## Called on end preparation.
func _exit_prepare_units():
	pass
	
	
## Called on turn start.
func _enter_turn():
	end_turn()
	
	
### Called on turn end.
func _exit_turn():
	pass
	

## Adds unit to the play area.
func prep_add_unit(unit: Unit, cell: Vector2):
	battle.hud().prep_unit_list.remove_unit(unit)
	unit.set_position(cell)
	print('added ', unit.display_name())


## Removes unit from play area and returns it to the unit list.
func prep_remove_unit(unit: Unit):
	battle.hud().prep_unit_list.add_unit(unit)
	unit.set_position(Map.OUT_OF_BOUNDS)
	print('removed ', unit.display_name())


## Returns true if cell is a valid spawn point.
func is_spawn_cell(cell: Vector2) -> bool:
	if not battle.world_bounds().has_point(cell):
		return false
	for sp in spawn_points:
		if sp.cell() == cell:
			return true
	return false


## Tries to spawn unit at cell and returns true if successful.
func prep_try_spawn_at(unit: Unit, cell: Vector2) -> bool:
	if not is_spawn_cell(cell):
		return false
	
	var old_pos := unit_drag_start + unit_drag_offset
	unit.set_position(Map.OUT_OF_BOUNDS)

	if battle.is_occupied(cell):
		var occupant := battle.get_unit_at(cell)
		assert(occupant.is_player_owned(), 'non player unit at spawn point')

		if old_pos == Map.OUT_OF_BOUNDS:
			prep_remove_unit(occupant)
		else:
			occupant.set_position(old_pos)
	
	prep_add_unit(unit, cell)
	return true


func interact_start_battle():
	if not is_hero_deployed():
		Game.create_pause_dialog('%s required.' % empire.leader_name(), 'Confirm', '')
		return
	end_prepare_units()
	

	
func is_hero_deployed() -> bool:
	for unit in Game.get_empire_units(empire):
		if unit.chara() == empire.leader:
			return true
	return false
	

func _on_unit_interacted(cursor_pos: Vector2, button_index: int, pressed: bool, unit: Unit):
	# units are not controls and overlapping objects will cause problems
	# that's why we need to add guards to make sure it's our unit.

	if button_index == MOUSE_BUTTON_MIDDLE:
		var can_rotate := (unit.is_player_owned()
			and battle.on_turn() == empire
			and battle.hud().get_selected_unit() == null)
		if pressed and can_rotate:
			rotated_unit = unit
		elif not pressed:
			if unit == rotated_unit: # guard
				rotated_unit = null

	if button_index == MOUSE_BUTTON_LEFT:
		if pressed:
			battle.hud().set_selected_unit(unit)
			unit_drag_start = unit.cell()
			unit_drag_offset = unit.get_global_position() - cursor_pos
			repositioned_unit = unit
		else:
			if unit == repositioned_unit: # guard
				if not prep_try_spawn_at(unit, unit.cell()):
					prep_remove_unit(unit)
				repositioned_unit = null

	if not battle.is_battle_phase():
		if button_index == MOUSE_BUTTON_RIGHT and pressed and unit.is_player_owned():
			battle.hud().set_selected_unit(null)
			prep_remove_unit(unit)
	else:
		pass
	

func _on_end_pressed():
	if not battle.is_battle_phase():
		interact_start_battle()
	else:
		pass
		

func _on_undo_pressed():
	pass


func _on_prep_unit_selected(unit: Unit):
	battle.hud().set_selected_unit(unit)
	unit_drag_start = Map.OUT_OF_BOUNDS
	unit_drag_offset = Vector2.ZERO # unit sprite height or drag_offset maybe?


func _on_prep_unit_released(unit: Unit):
	battle.hud().set_selected_unit(null)

	if not prep_try_spawn_at(unit, unit.cell()):
		prep_remove_unit(unit)


func _on_prep_unit_dragged(unit: Unit, pos: Vector2):
	unit.set_global_position(pos + unit_drag_offset)


func _on_prep_cancelled(unit: Unit):
	battle.hud().set_selected_unit(null)
	prep_remove_unit(unit)
