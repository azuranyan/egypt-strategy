@tool
extends Node

signal game_started
signal game_ended
signal game_resumed

signal quit_requested

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


const OverworldScene := preload("res://scenes/overworld/overworld.tscn")
const BattleScene := preload("res://scenes/battle/battle.tscn")
const MainMenuScene := preload("res://scenes/main_menu/main_menu.tscn")

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

## Preferences.
var prefs: Preferences

## Persistent data.
var persistent: Persistent

## The array of all units in the game.
var units: Array[Unit]

## Record of units by tag.
var _units_by_tag := {}

## Data pending to be loaded at the next checkpoint.
var _pending_data: SaveState

var _last_battle_result: BattleResult

var _scene: int

var suspended: bool

var _should_end: bool

var _overworld: Overworld
var _overworld_context: OverworldContext

var _battle: Battle
var _battle_context: BattleContext

var _event
var _event_context

var is_saveable_context: bool


func _ready():
	# default handler for quit. this can be overridden by connecting to
	# the request and rejecting quit.
	quit_requested.connect(func(): _should_end = true)


func _main(args := {}):
	# allows the game to launch a save file immediately
	_pending_data = args.get('quickload')

	# debug tools
	if OS.is_debug_build() or args.get('activate_debug_tools', false):
		var debug_overlay := load("res://scenes/test/overlay.tscn").instantiate() as TestOverlay
		debug_overlay.quit_button_pressed.connect(quit_game)
		#debug_overlay.save_button_pressed.connect(save_state)
		#debug_overlay.load_button_pressed.connect(load_state)
		add_child(debug_overlay)
	
	# load persitent data and start game
	_load_persistent_data()
	SceneManager.call_scene(args.start_scene_path, 'fade_to_black')
		
		
func _load_persistent_data():
	var persistent_path := "user://persistent.tres"
	if FileAccess.file_exists(persistent_path):
		persistent = load(persistent_path)
		
	if not persistent:
		persistent = Persistent.new()
		ResourceSaver.save(persistent, persistent_path)
	
		
func _start_overworld():
	if is_instance_valid(_overworld):
		push_error('Overworld already running.')
		return
	assert(_overworld_context)

	# create the overworld
	print('[Game] Starting Overworld.')
	_overworld = OverworldScene.instantiate()
	add_child(_overworld)
	
	# start the overworld
	is_saveable_context = true
	_overworld.start_overworld_cycle(_overworld_context)
	
	# wait for the overworld to end
	_last_battle_result = await overworld_ended

	# end the overworld
	print('[Game] Exiting Overworld.')
	is_saveable_context = false
	remove_child(_overworld)
	_overworld.queue_free()
 

func _start_battle():
	if is_instance_valid(_battle):
		push_error('Battle already running.')
		return
	assert(_battle_context)
	
	# create the battle
	print('[Game] Starting Battle.')
	#_battle = BattleScene.instantiate()
	#add_child(_battle)
	SceneManager.load_new_scene(BattleScene.resource_path, 'fade_to_black')
	_battle = await SceneManager.transition_finished
	
	
	# start the battle
	is_saveable_context = true
	_battle.start_battle(_battle_context)

	# wait for the battle to finish
	await battle_ended

	# end the battle
	print('[Game] Exiting Battle.')
	is_saveable_context = false
	
	SceneManager.load_new_scene(OverworldScene.resource_path, 'fade_to_black')
	_overworld = await SceneManager.transition_finished
	#remove_child(_battle)
	#_battle.queue_free()
 

func _start_main_menu():
	var main_menu := MainMenuScene.instantiate()
	add_child(main_menu)
	await main_menu.show_main_menu()
	remove_child(main_menu)
	main_menu.queue_free()


func _start_event():
	pass


func _start_intro():
	pass
	
		
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


func start_new_game():
	_pending_data = create_new_data()


func start_overworld_cycle():
	# overworld context is always loaded in data so we just call this
	await _start_overworld()
	
	
func stop_overworld_cycle():
	if is_instance_valid(_overworld):
		_overworld.stop_overworld_cycle()
		

func start_battle(attacker: Empire, defender: Empire, territory: Territory, map_id := 0):
	var ctx := BattleContext.new()
	ctx.attacker = attacker
	ctx.defender = defender
	ctx.territory = territory
	ctx.map_id = map_id
	ctx.units = units
	ctx.territories = _overworld_context.territories
	ctx.empires = _overworld_context.empires
	_battle_context = ctx
	await _start_battle()
	_battle_context = null


func stop_battle():
	pass
	
	
func suspend():
	suspended = true
	
	
func resume():
	if suspended:
		suspended = false
		game_resumed.emit()
	
	
func wait_for_resume():
	if suspended:
		await game_resumed
	
	
func quit_game():
	quit_requested.emit()
	# TODO
	
	if is_instance_valid(_battle):
		_battle.stop_battle()
	if is_instance_valid(_overworld):
		_overworld.stop_overworld_cycle()
		
		
func dont_quit():
	_should_end = false
	

func restart_game():
	_overworld.queue_free()
	if _battle:
		_battle.queue_free()
	
		
		
func show_main_menu() -> int:
	var main_menu := MainMenuScene.instantiate()
	add_child(main_menu)
	#main_menu.start_selected
	#main_menu.continue_selected
	#main_menu.load_selected
	#main_menu.settings_selected
	#main_menu.extras_selected
	#main_menu.credits_selected
	#main_menu.exit_selected.connect(emit_signal.bind('_main_menu_choice', 1))
	#var re := await _main_menu_choice
	#main_menu.queue_free()
	return 1
		
	
func _initiate_load():
	# if we're still running
	pass


## Creates a new save data.
func create_new_data() -> SaveState:
	print('[Game] Creating new save.')
	var save := SaveState.new()
	save.paused_event = 'overworld'
	save.paused_data.dummy = 'dummy'
	save.prefs = Preferences.new()
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
	var overworld := OverworldScene.instantiate() as Overworld
	overworld.hide()
	add_child(overworld)
	var ctx := overworld.create_new_context()
	remove_child(overworld)
	overworld.queue_free()
	return ctx
	

## Saves game data to file.
func save_data(path: String) -> Error:
	print('[Game] Saving data to "%s".' % path)
	if not is_saveable_context:
		return Error.FAILED
	# TODO show saving dialog
	return _save_state().save_to_file(path)

	
func _save_state() -> SaveState:
	assert(is_instance_valid(_overworld), 'tried to save without a valid Overworld!')
	var save := SaveState.new()
	get_tree().call_group('game_event_listeners', 'on_save', save)
	save.prefs = prefs.duplicate()
	save.overworld_context = _overworld_context.duplicate()
	if _battle:
		save.battle_context = _battle_context.duplicate()
	save.units = units.duplicate()
	return save
	

## Loads game data from file.
func load_data(path: String):
	print('[Game] Loading data from "%s".' % path)
	# TODO show loading dialog
	var save := SaveState.load_from_file(path)
	if not save:
		push_error('Cannot load save file "%s"' % path)
		return
	_load_state(save)
	restart_game()

	
func _load_state(save: SaveState):
	var dup := save.duplicate()
	get_tree().call_group('game_event_listeners', 'on_load', dup)
	prefs = dup.prefs
	_overworld_context = dup.overworld_context
	_battle_context = dup.battle_context
	units = dup.units
