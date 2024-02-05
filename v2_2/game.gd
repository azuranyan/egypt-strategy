@tool
extends Node

signal game_started
signal game_ended
signal game_resumed

signal overworld_started
signal overworld_ended

signal battle_started
signal battle_ended(result: BattleResult)

signal empire_defeated(empire: Empire)
signal player_defeated
signal boss_defeated

# signals sent here can be interrupted so should be waited with wait_for_resume

signal overworld_cycle_started(cycle: int)
signal overworld_cycle_ended(cycle: int)

signal overworld_turn_started(empire: Empire)
signal overworld_turn_ended(empire: Empire)

	
enum {
	SCENE_NONE,
	SCENE_INTRO,
	SCENE_MAIN_MENU, 
	SCENE_OVERWORLD,
	SCENE_BATTLE,
	SCENE_SAVELOAD,
	SCENE_EXTRAS,
	SCENE_CREDITS,
}


## The array of all units in the game.
var units: Array[Unit]

## Record of units by tag.
var _units_by_tag := {}


var _suspended: bool

var _overworld: Overworld
var _overworld_context: OverworldContext

var _battle: Battle
var _battle_context: BattleContext

var _event
var _event_context

var is_saveable_context: bool
	
var _start_scene_path: String

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
	_start_scene_path = kwargs.start_scene_path
	
	# TODO due to the way this works, Bootstrap is the current scene (as it's
	# set as the scene to launch on main) and will be replaced with whatever
	# it set as the main frame. Literal bootstrap.
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


func start_battle(attacker: Empire, defender: Empire, territory: Territory, map_id := 0):
	var ctx := BattleContext.new()
	ctx.attacker = attacker
	ctx.defender = defender
	ctx.territory = territory
	ctx.map_id = map_id
	ctx.units = units
	ctx.territories = _overworld_context.territories
	ctx.empires = _overworld_context.empires
	#_battle_context = ctx
	#await _start_battle()
	#_battle_context = null

	
## Suspends the game execution.[br]
##
## This is different from pause that completely stops execution and processing.
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
	
	
func quit_game():
	var should_end := [true]
	# NOTIFICATION_WM_QUIT_REQUEST is not used, instead on_quit will be called
	get_tree().call_group('game_event_listeners', 'on_quit', should_end)
	
	if not should_end[0]:
		return
	
	get_tree().quit()
	
	# TODO
	#if is_instance_valid(_battle):
		#_battle.stop_battle()
	#if is_instance_valid(_overworld):
		#_overworld.stop_overworld_cycle()
		

## Returns a texture of game's screenshot.
func capture_screenshot(size: Vector2i) -> Texture:
	var img := get_viewport().get_texture().get_image()
	img.resize(size.x, size.y, Image.INTERPOLATE_BILINEAR)
	return ImageTexture.create_from_image(img)
	

## Creates a new save data.
func create_new_data() -> SaveState:
	print('[Game] Creating new save.')
	var save := SaveState.new()
	save.timestamp = Time.get_datetime_dict_from_system()
	save.paused_event = 'overworld'
	save.paused_data.dummy = 'dummy'
	save.overworld_context = _create_new_overworld_context()
	save.battle_context = null
	save.units = []
	# TODO currently a hack
	var fr := SceneStackFrame.new()
	fr.scene_path = "res://scenes/overworld/overworld.tscn" # TODO main event
	fr.scene = null # this will be loaded in later (hopefully)
	save.scene_stack = [fr]
	return save
	
	
func _create_new_overworld_context() -> OverworldContext:
	# TODO circular dependency with overworld and lack of forward
	# declaration forces us to do this
	var overworld = load("res://scenes/overworld/overworld.tscn").instantiate()
	overworld.hide()
	add_child(overworld)
	var ctx = overworld.create_new_context()
	remove_child(overworld)
	overworld.queue_free()
	return ctx
	
	
## Saves game data to file. TODO put into SaveManager
func save_data(path: String) -> Error:
	print('[Game] Saving data to "%s".' % path)
	#if not is_saveable_context:
	#	return Error.FAILED
	# TODO show saving dialog
	return _save_state().save_to_file(path)

	
## Loads game data from file.
func load_data(path: String):
	print('[Game] Loading data from "%s".' % path)
	# TODO show loading dialog
	var save := SaveState.load_from_file(path)
	if not save:
		push_error('Cannot load save file "%s"' % path)
		return
	_load_state(save)


## Returns a copy of the game's current state.
func _save_state() -> SaveState:
	# create header
	var save := SaveState.new()
	save.slot = 0
	save.timestamp = Time.get_datetime_dict_from_system()
	save.preview = capture_screenshot(get_viewport_size() * 0.2)
	
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
func _load_state(save: SaveState):
	var dup := save.duplicate()
	print(save.overworld_context.cycle_count)
		
	# load data
	_overworld_context = dup.overworld_context
	_battle_context = dup.battle_context
	units = dup.units
	notify_property_list_changed()
	
	# dispatch event
	get_tree().call_group('game_event_listeners', 'on_load', dup)


## Loads a default game for f6 testing.
func create_testing_context():
	if not OS.is_debug_build():
		return
		
	
