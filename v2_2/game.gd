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




const OverworldScene := preload("res://scenes/overworld/overworld.tscn")

var test_individual_scenes := true


## Preferences.
var prefs := {
	defeat_if_home_territory_captured = true,
}


## The array of all units in the game.
var units: Array[Unit]

## Record of units by tag.
var _units_by_tag := {}

var suspended: bool



var _overworld: Overworld
var _state: SaveState


func _ready():
	if OS.is_debug_build():
		print("[Game] Loading default overworld (debug).")
		#overworld = OverworldScene.instantiate()
		#add_child(overworld)


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
	var c := load('res://units/%s/chara.tres' % dirname)
	if not c:
		push_warning('%s: "res://units/%s/chara.tres" not found' % [unit_name, dirname])
		return preload('res://units/placeholder/chara.tres')
	return c


## Returns the unit type for given unit name.
func get_unit_type(unit_name: String) -> UnitType:
	var dirname := unit_name.to_snake_case()
	var ut := load('res://units/%s/unit_type.tres' % dirname)
	if not ut:
		push_warning('%s: "res://units/%s/unit_type.tres" not found' % [unit_name, dirname])
		return preload('res://units/placeholder/unit_type.tres')
	return ut

	


	
func start_overworld_cycle():
	if is_instance_valid(_overworld):
		push_error('Overworld already running.')
		return
	print('[Game] Starting Overworld.')
	if not _state:
		push_error('no state loaded.')
		return
	_overworld = OverworldScene.instantiate()
	add_child(_overworld)
	_overworld.start_overworld_cycle(_state.overworld_context)
	await overworld_ended
	print('[Game] Exiting Overworld.')
	remove_child(_overworld)
	_overworld.queue_free()
	

func start_battle(attacker: Empire, defender: Empire, territory: Territory, map_id := 0):
	# TODO
	battle_started.emit()
	var result := BattleResult.new(BattleResult.ATTACKER_VICTORY, attacker, defender, territory, map_id)
	battle_ended.emit(result)
	
	
func suspend():
	suspended = true
	
	
func resume():
	if suspended:
		suspended = false
		game_resumed.emit()
	
	
func wait_for_resume():
	if suspended:
		await game_resumed
	
	
func start_game(args := {}):
	test_individual_scenes = false
	game_started.emit()
	await _main(args)
	game_ended.emit()
	get_tree().quit()
	
	
func _main(_args := {}):
	#var custom_state := create_new_state()
	
	var custom_state := SaveState.load_from_file('user://save_file4.res')
	load_state(custom_state)
	await start_overworld_cycle()
	_state = null


func create_new_state() -> SaveState:
	print('[Game] Creating new save.')
	var state := SaveState.new()
	state.overworld_context = create_new_overworld_context()
	return state
	
	
func create_new_overworld_context() -> OverworldContext:
	var overworld := OverworldScene.instantiate() as Overworld
	overworld.hide()
	add_child(overworld)
	var ctx := overworld.create_new_context()
	remove_child(overworld)
	overworld.queue_free()
	return ctx
	
	
func save_state() -> SaveState:
	print('[Game] Saving...')
	assert(is_instance_valid(_overworld), 'tried to save without a valid Overworld!')
	return _state.duplicate(false)
	
	
func load_state(state: SaveState):
	print('[Game] Loading...')
	_state = state
	
