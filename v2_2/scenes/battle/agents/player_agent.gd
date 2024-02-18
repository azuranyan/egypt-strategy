extends BattleAgent


var battle: Battle
var rotated_unit: Unit
var repositioned_unit: Unit
var spawn_points: Array[SpawnPoint]
var unit_drag_start: Vector2
var unit_drag_offset: Vector2


var ghost: MapObject


func _process(_delta):
	if rotated_unit:
		const ROTATION_DEADZONE := 0.2
		var mpos := battle.world().as_uniform(get_viewport().get_mouse_position())
		if rotated_unit.get_position().distance_squared_to(mpos) >= ROTATION_DEADZONE*ROTATION_DEADZONE:
			rotated_unit.face_towards(mpos)

	if repositioned_unit:
		repositioned_unit.set_global_position(get_viewport().get_mouse_position() - unit_drag_offset)
		if battle.is_occupied(repositioned_unit.cell()):
			if not ghost:
				ghost = repositioned_unit.get_map_object().duplicate()
				battle.add_map_object(ghost)
				ghost.map_position = ghost.world.as_uniform(unit_drag_start)
				print(ghost.map_position)
		

## Called on initialize.
func _initialize():
	battle = Game.battle
	battle.hud().end_button.pressed.connect(_on_end_pressed)
	battle.hud().undo_button.pressed.connect(_on_undo_pressed)
	battle.hud().undo_button.disabled = true
	battle.hud().prep_unit_list.unit_selected.connect(_on_prep_unit_selected)
	battle.hud().prep_unit_list.unit_released.connect(_on_prep_unit_released)
	battle.hud().prep_unit_list.unit_dragged.connect(_on_prep_unit_dragged)
	battle.hud().prep_unit_list.cancelled.connect(_on_prep_cancelled)

	spawn_points = battle.get_spawn_points(SpawnPoint.Type.PLAYER)


## Called on start preparation.
func _enter_prepare_units():
	UnitEvents.clicked.connect(global_on_unit_clicked)
	UnitEvents.clicked.connect(prep_on_unit_clicked)
	
	
## Called on end preparation.
func _exit_prepare_units():
	UnitEvents.clicked.disconnect(global_on_unit_clicked)
	UnitEvents.clicked.disconnect(prep_on_unit_clicked)
	
	
## Called on turn start.
func _enter_turn():
	UnitEvents.clicked.connect(global_on_unit_clicked)
	UnitEvents.clicked.connect(battle_on_unit_clicked)
	
	
### Called on turn end.
func _exit_turn():
	UnitEvents.clicked.disconnect(global_on_unit_clicked)
	UnitEvents.clicked.disconnect(battle_on_unit_clicked)
	

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
	
	var old_pos := Map.cell(unit_drag_start)# + unit_drag_offset
	unit.set_position(Map.OUT_OF_BOUNDS)

	if battle.is_occupied(cell):
		var occupant := battle.get_unit_at(cell)
		assert(occupant.is_player_owned(), 'non player unit at spawn point')

		if old_pos == Map.OUT_OF_BOUNDS:
			prep_remove_unit(occupant)
		else:
			occupant.set_global_position(old_pos)
	
	prep_add_unit(unit, cell)
	return true


func can_reposition(unit: Unit) -> bool:
	return (unit.is_player_owned()
		and not unit.has_meta('preplaced')
		and battle.on_turn() == empire)


func can_rotate(unit: Unit) -> bool:
	return (unit.is_player_owned()
		and not unit.has_meta('preplaced')
		and battle.on_turn() == empire
		and Game.get_selected_unit() == null)


## Accepts interacted event from unit.
func global_on_unit_clicked(unit: Unit, _mouse_pos: Vector2, button_index: int, pressed: bool):
	if button_index == MOUSE_BUTTON_MIDDLE:
		if pressed and can_rotate(unit):
			rotated_unit = unit
		elif not pressed and unit == rotated_unit: 
			rotated_unit = null

		
## Accepts interacted event from unit.
func prep_on_unit_clicked(unit: Unit, mouse_pos: Vector2, button_index: int, pressed: bool):
	if button_index == MOUSE_BUTTON_LEFT:
		if pressed and can_reposition(unit):
			Game.select_unit(unit)
			unit_drag_start = unit.get_global_position()
			unit_drag_offset = mouse_pos - unit.get_global_position() 
			repositioned_unit = unit
		elif not pressed and unit == repositioned_unit:
			if not prep_try_spawn_at(unit, unit.cell()):
				prep_remove_unit(unit)
			Game.deselect_unit(unit)
			repositioned_unit = null

	if button_index == MOUSE_BUTTON_RIGHT and pressed and can_reposition(unit):
		Game.deselect_unit(unit)
		prep_remove_unit(unit)



## Accepts interacted event from unit.
func battle_on_unit_clicked(unit: Unit, mouse_pos: Vector2, button_index: int, pressed: bool):
	pass


func interact_start_battle():
	if not is_hero_deployed():
		Game.create_pause_dialog('%s required.' % empire.leader_name(), 'Confirm', '')
		return
	end_prepare_units()
	

func interact_try_use_attack() -> bool:
	return false

	
func is_hero_deployed() -> bool:
	for unit in Game.get_empire_units(empire):
		if unit.chara() == empire.leader:
			return true
	return false
	




	

func _on_end_pressed():
	if not battle.is_battle_phase():
		interact_start_battle()
	else:
		pass
		

func _on_undo_pressed():
	pass


func _on_prep_unit_selected(unit: Unit):
	Game.select_unit(unit)
	unit_drag_start = Map.OUT_OF_BOUNDS
	unit_drag_offset = Vector2.ZERO # unit sprite height or drag_offset maybe?


func _on_prep_unit_released(unit: Unit):
	Game.deselect_unit(unit)
	battle.hud().set_selected_unit(null)

	if not prep_try_spawn_at(unit, unit.cell()):
		prep_remove_unit(unit)


func _on_prep_unit_dragged(unit: Unit, pos: Vector2):
	unit.set_global_position(pos + unit_drag_offset)


func _on_prep_cancelled(unit: Unit):
	battle.hud().set_selected_unit(null)
	prep_remove_unit(unit)
