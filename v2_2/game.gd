@tool
extends Node

signal game_started
signal game_ended
signal game_resumed


signal setting_changed(setting: StringName, value: Variant)
signal trigger_state_changed(trigger: Trigger, state: bool)


## Emitted when game is about to save state.
signal saving_state

## Emitted when game is about to load state.
signal loading_state

## Emitted on new game start.
signal new_game_started


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

## The group for game event listeners.
const GAME_EVENT_LISENERS_GROUP: StringName = 'game_event_listeners'


enum SaveError {
	SAVE_ERROR = -1,
	NO_ERROR = 0,
	
}


## Record of unit id and unit.
var unit_registry: Dictionary

## The next unit id.
var _next_unit_id: int

## Reference to the [Overworld] system.
var overworld: Overworld

## Record of playable scenes and whether they've been checked once.
var available_scenes: Dictionary

## Reference to the [Battle] system.
var battle: Battle

## Reference to the [AttackSystem].
var attack_system: AttackSystem

## Reference to the [Dialogue] system.
var dialogue: Dialogue

var audio_stream_player: AudioStreamPlayer2D

var settings: Settings

var _suspended: bool

var _pause_nodes: Array[Node]


func _ready():
	settings = Settings.new()

	var node := Node.new()
	node.name = 'Units'
	add_child(node)
	node.owner = self

	attack_system = load('res://scenes/battle/attack_system.tscn').instantiate()
	attack_system.name = 'AttackSystem'
	add_child(attack_system, true)
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
	
	
## Pauses the game. A node is passed as the key to prevent double pauses.
func push_pause(node: Node):
	if node in _pause_nodes:
		return
	_pause_nodes.append(node)
	get_tree().paused = true
	
	
## Pops a key node. Will unpause the game once all keys are popped.
func pop_pause(node: Node):
	if node not in _pause_nodes:
		return
	_pause_nodes.remove_at(_pause_nodes.rfind(node))
	if _pause_nodes.is_empty():
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
func create_unit(empire: Empire, chara_id: StringName, chara: CharacterInfo = null, unit_type: UnitType = null) -> Unit:
	if chara == null:
		chara = get_character_info(chara_id)
	if unit_type == null:
		unit_type = get_unit_type(chara_id)

	var is_placeholder := chara == preload("res://units/placeholder/chara.tres")
	var data := {
		id = _next_unit_id,
		display_name = chara_id.capitalize() if is_placeholder else chara.name,
		display_icon = chara.portrait,
		chara_id = chara_id,
		chara = chara,
		unit_type = unit_type,
		empire = empire,
		hero = empire.leader_id == chara_id,

		# special is only available for player units
		special_unlock = -1 if empire.is_player_owned() else 0,
	}
	_next_unit_id += 1
	return _create_unit_from_data(data, false)


func _create_unit_from_data(data: Dictionary, from_save_data: bool) -> Unit:
	# don't use preload to prevent a errors when UnitImpl fails to compile
	var unit = load('res://scenes/battle/unit/unit_impl.tscn').instantiate()

	# load data
	if not from_save_data:
		# we can't pass args to instantate so we do it this way
		var merged_data: Dictionary = unit.save_state()
		merged_data.merge(data, true)
		data = merged_data
	unit.load_state(data)
	unit.name = '%s_%s' % [unit._chara_id, unit._id]
	
	# finalization
	get_node('Units').add_child(unit)
	unit.add_to_group(ALL_UNITS_GROUP)
	unit_registry[data.id] = unit
	UnitEvents.created.emit(unit)
	return unit


## Loads a unit by id.
func load_unit(unit_id: int) -> Unit:
	return unit_registry.get(unit_id, null)


## Removes the unit.
func destroy_unit(unit: Unit):
	if unit.id() not in unit_registry:
		push_error('unit not in the registry')
		return

	UnitEvents.destroying.emit(unit)
	unit_registry.erase(unit.id())
	unit.remove_from_group('all_units')
	get_node('Units').remove_child(unit)
	unit.queue_free()
	
	
## Returns the first unit with given chara id.
## 
## Do note that there can be multiple units with the same `chara_id`.
## For getting the exact unit, use `load_unit` instead.
func get_unit_by_chara_id(chara_id: StringName) -> Unit:
	for u in unit_registry:
		if unit_registry[u].chara_id() == chara_id:
			return unit_registry[u]
	return null


## Returns the empire units.
func get_units(e: Empire, mask := VALID_TARGET_MASK) -> Array[Unit]:
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


## Returns the empire units.
## @deprecated
func get_empire_units(e: Empire, mask := VALID_TARGET_MASK) -> Array[Unit]:
	return get_units(e, mask)


## Returns the hero unit.
func get_hero_unit(e: Empire) -> Unit:
	for id in unit_registry:
		var u: Unit = unit_registry[id]
		if u.is_hero() and u.get_empire() == e:
			return u
	return null


## Returns the first unit with matching name.
func find_unit_by_name(display_name: String) -> Unit:
	for id in unit_registry:
		var u: Unit = unit_registry[id]
		if u.display_name() == display_name:
			return u
	return null


## Returns the first unit with matching chara id.
func find_unit_by_chara_id(chara_id: StringName) -> Unit:
	for id in unit_registry:
		var u: Unit = unit_registry[id]
		if u.chara_id() == chara_id:
			return u
	return null


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
	var pause = load('res://scenes/common/pause_dialog.tscn').instantiate()
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
func capture_screenshot(size: Vector2i = get_viewport_size()) -> Texture:
	var img := get_viewport().get_texture().get_image()
	if get_viewport().size != size:
		img.resize(size.x, size.y, Image.INTERPOLATE_BILINEAR)
	return ImageTexture.create_from_image(img)
	

## Starts a new game.
func start_new_game():
	print('[Game] Starting new game.')

	_cleanup()

	_create_subsystems()
	var err := overworld.load_new_state()
	if err != Overworld.NO_ERROR:
		push_error(err)
		return
	# battle.load_new_state()

	game_started.emit()

	# the special new game scene
	SceneManager.call_scene('res://scenes/new_game/new_game_scene.tscn', 'fade_to_black')


func _create_subsystems():
	overworld = load("res://scenes/overworld/overworld.gd").new()
	overworld.name = 'Overworld'
	add_child(overworld, true)

	battle = load('res://scenes/battle/battle_impl.gd').new()
	battle.name = 'Battle'
	add_child(battle, true)
	
	dialogue = load('res://scenes/dialogue/dialogue.gd').new()
	dialogue.name = 'Dialogue'
	add_child(dialogue, true)


## Returns a copy of the game's current state.
func save_state() -> SaveState:
	saving_state.emit()
	
	var save := _create_save()
	
	save.settings = settings.duplicate(true)

	# save unit state
	for unit in unit_registry.values():
		save.units[unit.id()] = unit.save_state()
	save.next_unit_id = _next_unit_id

	# save subsystems
	save.overworld_data = overworld.save_state()
	save.battle_data = battle.save_state()
	save.dialogue_data = dialogue.save_state()
	save.scene_manager_data = SceneManager.save_state()

	# TODO old dispatch system
	get_tree().call_group('game_event_listeners', 'on_save', save)

	return save

	
## Changes the game state.
func load_state(save: SaveState) -> void:
	loading_state.emit()
	
	_cleanup()
	
	settings = save.settings

	# load unit state
	for data in save.units.values():
		_create_unit_from_data(data, true)
	_next_unit_id = save.next_unit_id
	
	_create_subsystems()
	overworld.load_state(save.overworld_data)
	battle.load_state(save.battle_data)
	dialogue.load_state(save.dialogue_data)

	SceneManager.load_state(save.scene_manager_data)
	await SceneManager.transition_finished
	
	# TODO old dispatch system
	get_tree().call_group('game_event_listeners', 'on_load', save)
	game_started.emit()


func _create_save() -> SaveState:
	var save := SaveState.new()
	save.version = '0.1'
	save.slot = 0
	save.preview = capture_screenshot(get_viewport_size() * 0.2)
	save.timestamp = Time.get_datetime_dict_from_system()
	return save
	

## Wipes the current game state.
func _cleanup() -> void:
	for u in unit_registry.values():
		destroy_unit(u)

	_next_unit_id = 0

	if battle:
		battle.free()
		battle = null

	if overworld:
		overworld.free()
		overworld = null

	if dialogue:
		dialogue.free()
		dialogue = null
