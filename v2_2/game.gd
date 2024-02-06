@tool
extends Node

signal game_started
signal game_ended
signal game_resumed

## Emitted when the overworld enters scene.
signal overworld_started

## Emitted when the overworld exits. [b]Cannot be suspended.[/b]
signal overworld_ended # TODO FIX: never emitted

## Emitted when a new cycle starts. Can be suspended.
signal overworld_cycle_started(cycle: int)

## Emitted when a cycle ends. Can be suspended.
signal overworld_cycle_ended(cycle: int)

## Emitted an empire's turn starts. Can be suspended.
signal overworld_turn_started(empire: Empire)

## Emitted an empire's turn ends. Can be suspended.
signal overworld_turn_ended(empire: Empire)

## Emitted when an empire is defeated. Can be suspended.
signal empire_defeated(empire: Empire)

## Emitted when the battle enters scene. [b]Cannot be suspended.[/b]
signal battle_started

## Emitted when the battle exits scene. [b]Cannot be suspended.[/b]
signal battle_ended(result: BattleResult)


## The array of all units in the game.
var units: Array[Unit]:
	set(value):
		units = value

## Record of units by tag.
var _units_by_tag := {}

var _suspended: bool

var _overworld: Overworld
var _overworld_context: OverworldContext

var _battle: Battle
var _battle_context: BattleContext

var _event
var _event_context


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
## Loads a unit by name for empire.
func load_unit(unit_name: String, tag: StringName, prop := {}) -> Unit:
	if is_tag_used(tag):
		return get_unit_by_tag(tag)
	var chara := get_character_info(unit_name)
	var unit_type := get_unit_type(unit_name)
	assert(chara != null, 'placeholder chara not found')
	assert(unit_type != null, 'placeholder unit_type expected')
	return create_unit(chara, unit_type, tag, prop)


## Creates a new unit for empire. Returns null if tag already exists.
func create_unit(chara: CharacterInfo, unit_type: UnitType, tag: StringName, prop := {}) -> Unit:
	if is_tag_used(tag):
		return null
	var unit := Unit.new(chara, unit_type, prop)
	units.append(unit)
	unit.set_meta('tag', tag)
	_units_by_tag[tag] = unit
	return unit


## Returns the unit with the given tag.
func get_unit_by_tag(tag: String) -> Unit:
	return _units_by_tag.get(tag)


## Returns the unit tag.
func get_unit_tag(unit: Unit) -> String:
	if unit.has_meta('tag'):
		return unit.get_meta('tag')
	return ''


## Returns true if unit with tag exists.
func is_tag_used(tag: String) -> bool:
	return tag in _units_by_tag


## Removes the unit.
func destroy_unit(unit: Unit):
	units.erase(unit)
	_units_by_tag.erase(get_unit_tag(unit))
	

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
	
	save.overworld_context = _create_new_overworld_context()
	save.battle_context = BattleContext.new()
	save.battle_context.territories = save.overworld_context.territories
	save.battle_context.empires = save.overworld_context.empires
	save.units = units.duplicate() # TODO this feels REALLY weird
	
	# TODO this is useless, check trello
	get_tree().call_group('game_event_listeners', 'on_new_save', save)
	
	# TODO currently a hack, change this to the real start point later
	var fr := SceneStackFrame.new()
	fr.scene_path = "res://scenes/overworld/overworld.tscn" # TODO main event
	fr.scene = null # this will be loaded in later (hopefully)
	save.scene_stack = [fr]
	return save
	
	
func _create_new_overworld_context() -> OverworldContext:
	# can't preload or declare type (circular dependency)
	var overworld = load("res://scenes/overworld/overworld.tscn").instantiate()
	overworld.hide()
	add_child(overworld)
	var ctx = overworld.create_new_context()
	remove_child(overworld)
	overworld.queue_free()
	return ctx
	
	
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
	
	# dispatch event
	get_tree().call_group('game_event_listeners', 'on_save', save)
	
	# create data
	if _overworld:
		save.overworld_context = _overworld_context.duplicate()
	if _battle:
		save.battle_context = _battle_context.duplicate()
	save.units = units.duplicate()
	return save
	

## Changes the game state.
func load_state(save: SaveState):
	print('[Game] Loading state.')
	# load data
	_overworld_context = save.overworld_context
	_battle_context = save.battle_context
	units = save.units
	notify_property_list_changed()
	
	# dispatch event
	get_tree().call_group('game_event_listeners', 'on_load', save)


