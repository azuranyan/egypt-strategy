@tool
extends Node

signal game_started
signal game_ended
signal game_resumed

## Emitted when the battle enters scene. [b]Cannot be suspended.[/b]
signal battle_started

## Emitted when the battle exits scene. [b]Cannot be suspended.[/b]
signal battle_ended(result: BattleResult)


## Reference to the [Overworld] system.
var overworld: Overworld


var unit_registry: Dictionary

## Reference to the [Battle] system.
var battle: Battle

## Reference to the [Dialog] aka event system.
var dialog: Variant



var _suspended: bool

var _battle: Battle
var _battle_context: BattleContext

var _event
var _event_context


func _ready():
	overworld = preload("res://scenes/overworld/overworld_impl.gd").new()
	add_child(overworld)



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
## Creates a new unit.
func create_unit(save: SaveState, chara_id: StringName) -> Unit:
	# load unit data
	var chara := get_character_info(chara_id)
	var unit_type := get_unit_type(chara_id)
	assert(chara != null, 'placeholder chara not found')
	assert(unit_type != null, 'placeholder unit_type expected')

	# create new unit
	var unit := Unit.new(chara, unit_type)
	unit.id = save.next_unit_id
	save.units[save.next_unit_id] = unit
	save.next_unit_id += 1
	return unit


## Loads a unit by id.
func load_unit(unit_id: int) -> Unit:
	return unit_registry.get(unit_id, null)


## Removes the unit.
func destroy_unit(unit: Unit):
	unit_registry.erase(unit)
	

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
	get_tree().call_group('game_event_listeners', 'on_new_save', save)
	
	save.battle_context = BattleContext.new()
	
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
	
	# dispatch event
	get_tree().call_group('game_event_listeners', 'on_save', save)
	
	if _battle_context:
		save.battle_context = _battle_context.duplicate()
	return save
	

## Changes the game state.
func load_state(save: SaveState):
	print('[Game] Loading state.')
	# dispatch event
	get_tree().call_group('game_event_listeners', 'on_load', save)
	
	# load data
	_battle_context = save.battle_context
	
	# TODO hack
	overworld.start_overworld_cycle()


