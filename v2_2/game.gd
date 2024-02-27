@tool
extends Node

signal game_started
signal game_ended
signal game_resumed

const ALL_UNITS_GROUP := &'all_units'

## Alive unit mask for [method get_empire_units].
const ALIVE_MASK := 1

## Dead unit mask for [method get_empire_units].
const DEAD_MASK := 2

## Unit on-field mask for [method get_empire_units].
const FIELDED_MASK := 4

## Unit standby mask for [method get_empire_units].
const STANDBY_MASK := 8

## Selectable unit mask
const SELECTABLE_MASK := 16

## Valid target mask for [method get_empire_units].
const VALID_TARGET_MASK := ALIVE_MASK | FIELDED_MASK | SELECTABLE_MASK

## All units mask for [method get_empire_units].
const ALL_UNITS_MASK := ~0


## Reference to the [Overworld] system.
var overworld: Overworld

## Record of unit id and unit.
var unit_registry: Dictionary

## Record of playable scenes and whether they've been checked once.
var available_scenes: Dictionary

## Reference to the [Battle] system.
var battle: Battle

## Reference to the [AttackSystem].
var attack_system: AttackSystem

## Reference to the [Dialog] aka event system.
var dialog: Variant

var audio_stream_player: AudioStreamPlayer2D

var _suspended: bool

var _pause_count: int

var _interaction_handler



## Returns the last selected unit.
func get_selected_unit() -> Unit:
	if is_instance_valid(_interaction_handler):
		return _interaction_handler.get_selected_unit()
	return null
	

## Selects a unit.
func select_unit(unit: Unit):
	if is_instance_valid(_interaction_handler):
		_interaction_handler.select_unit(unit)


## Deselects a unit.
func deselect_unit(unit: Unit = get_selected_unit()):
	if is_instance_valid(_interaction_handler):
		_interaction_handler.deselect_unit(unit)


func _ready():
	var node := Node.new()
	node.name = 'Units'
	add_child(node)
	node.owner = self
	
	overworld = load("res://scenes/overworld/overworld_impl.gd").new()
	overworld.name = 'Overworld'
	add_child(overworld)
	overworld.owner = self
	
	battle = load('res://scenes/battle/battle_impl.gd').new()
	battle.name = 'Battle'
	add_child(battle)
	battle.owner = self

	attack_system = load('res://scenes/battle/attack_system.tscn').instantiate()
	attack_system.name = 'AttackSystem'
	add_child(attack_system)
	attack_system.owner = self

	audio_stream_player = AudioStreamPlayer2D.new()
	add_child(audio_stream_player)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()
		
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		# TODO should check if in main menu, then quit else go back
		quit_game()


func _main(kwargs := {}):
	# debug tools
	if OS.is_debug_build() or kwargs.get('activate_debug_tools', false):
		var debug_overlay := load("res://scenes/debug/overlay.tscn").instantiate() as TestOverlay
		add_child(debug_overlay)
	
	get_tree().set_auto_accept_quit(false)
	
	# due to the way this works, Bootstrap is the current scene, as set as
	# the scene to launch on main and will be replaced by the start scene.
	SceneManager.call_scene(kwargs.start_scene_path, 'fade_to_black')
		
		
## Returns true if there are scenes that have not been checked yet.
func has_new_scenes() -> bool:
	for scene_id in available_scenes:
		if not available_scenes[scene_id]:
			return true
	return false
	
	
## Pushes a pause. Pauses the game.
func push_pause():
	_pause_count += 1
	get_tree().paused = true
	
	
## Pops a pause. Unpauses if pause count is 0.
func pop_pause():
	_pause_count -= 1
	if _pause_count <= 0:
		_pause_count = 0
		get_tree().paused = false
	

## Calls a function with minimum delay time.
func delay_function(callable: Callable, delay: float, argv := []) -> Variant:
	if delay <= 0:
		return callable.callv(argv)
	
	var timer := Timer.new()
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = delay
	add_child(timer)
	
	var rv = await callable.callv(argv)
	
	if timer.time_left > 0:
		await timer.timeout
	timer.queue_free()
	return rv
	
	
## Returns the viewport size.
func get_viewport_size() -> Vector2:
	# TODO get_viewport().size doesn't work, even with stretch mode set to
	# viewport. despite what godot says, it doesn't change the viewport to
	# project settings set size if window is launched with a fixed size 
	# like maximized and force window size.
	return Vector2(1920, 1080)


#region Unit
## Creates a new unit.
func create_unit(save: SaveState, chara_id: StringName, empire: Empire = null) -> Unit:
	# load unit data
	var chara := get_character_info(chara_id)
	var unit_type := get_unit_type(chara_id)
	assert(chara != null, 'placeholder chara not found')
	assert(unit_type != null, 'placeholder unit_type expected')

	# don't use preload to prevent a cascading error when UnitImpl
	# fails to compile and avoid circular dependencies.
	var unit = load('res://scenes/battle/unit/unit_impl.tscn').instantiate()
	var unit_id := save.next_unit_id

	# we can't pass args to instantate so we do it this way
	var data = unit.save_state()
	data.id = unit_id
	if chara != preload("res://units/placeholder/chara.tres"):
		data.display_name = chara.name
	else:
		data.display_name = chara_id.capitalize()
	data.display_icon = chara.portrait
	data.chara_id = chara_id
	data.chara = chara
	data.unit_type = unit_type
	data.empire = empire
	unit.load_state(data)
	
	# making it look nice in the remote inspector
	unit.name = '%s%s' % [chara_id, unit_id]
	
	# adding to registry
	get_node('Units').add_child(unit)
	save.units[unit_id] = unit.save_state()
	save.next_unit_id = unit_id + 1
	unit_registry[unit_id] = unit
	unit.add_to_group(ALL_UNITS_GROUP)
	UnitEvents.created.emit(unit)
	return unit
	

## Loads a unit by id.
func load_unit(unit_id: int) -> Unit:
	return unit_registry.get(unit_id, null)


## Removes the unit.
func destroy_unit(unit: Unit):
	if unit.id() not in unit_registry:
		push_error('destroying unit not in the registry')
		return

	UnitEvents.destroying.emit(unit)
	unit.remove_from_group('all_units')
	unit_registry.erase(unit.id())
	get_node('Units').remove_child(unit)
	unit.queue_free()
	
	
## Returns the empire units.
func get_empire_units(e: Empire, mask := VALID_TARGET_MASK) -> Array[Unit]:
	var arr: Array[Unit] = []
	for id in unit_registry:
		var u: Unit = unit_registry[id]
		if e and u.get_empire() != e:
			continue
		if mask != ALL_UNITS_MASK:
			if bool(mask & ALIVE_MASK) != u.is_alive():
				continue
			if bool(mask & DEAD_MASK) != u.is_dead():
				continue
			if bool(mask & STANDBY_MASK) != u.is_standby():
				continue
			if bool(mask & FIELDED_MASK) != u.is_fielded():
				continue
			if bool(mask & SELECTABLE_MASK) != u.is_selectable():
				continue
		arr.append(u)
	return arr
	

## Returns the character info for given unit name.
func get_character_info(unit_name: String) -> CharacterInfo:
	var dirname := unit_name.to_snake_case()
	var path := 'res://units/%s/chara.tres' % dirname
	if FileAccess.file_exists(path):
		return load(path)
	else:
		push_warning('%s: "res://units/%s/chara.tres" not found' % [unit_name, dirname])
		return preload('res://units/placeholder/chara.tres')


## Returns the unit type for given unit name.
func get_unit_type(unit_name: String) -> UnitType:
	var dirname := unit_name.to_snake_case()
	var path := 'res://units/%s/unit_type.tres' % dirname
	if FileAccess.file_exists(path):
		return load(path)
	else:
		push_warning('%s: "res://units/%s/unit_type.tres" not found' % [unit_name, dirname])
		return preload('res://units/placeholder/unit_type.tres')
#endregion Unit


## Plays error sound.
func play_error_sound():
	if not audio_stream_player.is_playing():
		audio_stream_player.stream = preload("res://scenes/data/error-126627.wav")
		audio_stream_player.play()


## Creates a pause dialog.
func create_pause_dialog(message: String, confirm: String, cancel: String, background := true) -> PauseDialog:
	# avoid circular ref(!!)
	var pause = load('res://scenes/battle/hud/pause_dialog.tscn').instantiate()
	get_tree().root.add_child(pause)
	pause.background = background
	pause.open_dialog(message, confirm, cancel)
	return pause


## Suspends the game execution.[br]
##
## This is different from pause that stops game execution and processing.
## This lets systems powered by coroutines to be suspended and resumed later.
func suspend() -> void:
	_suspended = true
	
	
## Resumes the game execution.
func resume() -> void:
	if _suspended:
		_suspended = false
		game_resumed.emit()
	
	
## Awaits for resume if suspended.
func wait_for_resume() -> void:
	if _suspended:
		await game_resumed
	
	
## Quits the game. Broadcasts [code]on_quit[/code] event.
func quit_game():
	var should_end := [true]
	# NOTIFICATION_WM_QUIT_REQUEST is not used, instead on_quit will be called
	get_tree().call_group('game_event_listeners', 'on_quit', should_end)
	
	if not should_end[0]:
		return
	get_tree().quit()
		
		
## Returns a texture of game's screenshot.
func capture_screenshot(size: Vector2i) -> Texture:
	var img := get_viewport().get_texture().get_image()
	img.resize(size.x, size.y, Image.INTERPOLATE_BILINEAR)
	return ImageTexture.create_from_image(img)
	

## Creates a new save data.
func create_new_data() -> SaveState:
	print('[Game] Creating new save.')
	var save := _create_save()
	get_tree().call_group('game_event_listeners', 'on_new_save', save)
	
	# TODO currently a hack, change this to the real start point later
	var fr := SceneStackFrame.new()
	fr.scene_path = SceneManager.scenes.overworld # TODO main event
	fr.scene = null # this will be loaded in later (hopefully)
	save.scene_stack = [fr]
	return save
	
	
func _create_save() -> SaveState:
	var save := SaveState.new()
	save.version = '0.1'
	save.slot = 0
	save.preview = capture_screenshot(get_viewport_size() * 0.2)
	save.timestamp = Time.get_datetime_dict_from_system()
	return save
	
	
## Returns a copy of the game's current state.
func save_state() -> SaveState:
	print('[Game] Saving state.')
	var save := _create_save()
	
	# we created this unit so we know it's a UnitImpl
	for unit in unit_registry.values():
		save.units[unit.id()] = unit.save_state()
		
	# dispatch event
	get_tree().call_group('game_event_listeners', 'on_save', save)
	
	return save
	

## Changes the game state.
func load_state(save: SaveState):
	print('[Game] Loading state.')
	
	for u in unit_registry.values():
		destroy_unit(u)
		
	# load them again as UnitImpl's
	for data in save.units.values():
		var unit = load('res://scenes/battle/unit/unit_impl.tscn').instantiate()
		unit.load_state(data)
		unit.name = '%s%s' % [unit._chara_id, unit.id()]
		unit_registry[unit.id()] = unit
		get_node('Units').add_child(unit)
		unit.add_to_group(ALL_UNITS_GROUP)
		UnitEvents.created.emit(unit)
		
	# dispatch event
	get_tree().call_group('game_event_listeners', 'on_load', save)
	
	# TODO hack
	overworld.start_overworld_cycle()
	


