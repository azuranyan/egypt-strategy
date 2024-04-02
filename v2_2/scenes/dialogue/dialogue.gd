class_name Dialogue
extends Node


const StoryEventScene := preload("story_event_scene.gd")
const ImageLibrary := preload("res://events/image_library.gd")


var image_library: ImageLibrary

var current_event_id: StringName
var current_event_scene: StoryEventScene
var is_playing_queue: bool

var event_registry: Dictionary
var character_events: Dictionary
var event_queue: Array[StringName]


static func instance() -> Dialogue:
	return Game.dialogue


func _ready() -> void:
	image_library = preload('res://events/image_library.tscn').instantiate()
	add_child(image_library)
	image_library.name = 'ImageLibrary'

	DialogueEvents.start_event_requested.connect(_on_start_event_requested)
	DialogueEvents.stop_event_requested.connect(_on_stop_event_requested)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed('vn_rollback'):
		_on_dialogue_rollback_requested()


## Registers an event. Will overwrite existing entries.
func register_event(event: StoryEvent, chara: CharacterInfo = null) -> void:
	var state := {
		event = event,
		chara = chara,
		locked = event.locked,
		times_seen = 0,
		priority = event.priority,
	}
	
	_add_event(state)
	if chara:
		_add_character_event(event.event_id, chara)


func _add_character_event(event_id: StringName, chara: CharacterInfo) -> void:
	if chara in character_events:
		if event_id not in character_events[chara]:
			character_events[chara].append(event_id)
	else:
		character_events[chara] = [event_id]


func _add_event(state: Dictionary) -> void:
	event_registry[state.event.event_id] = state


## Returns the event.
func get_event(event_id: StringName) -> StoryEvent:
	return event_registry[event_id].event


## Returns the current event.
func current_event() -> StoryEvent:
	if current_event_id:
		return get_event(current_event_id)
	return null


## Sets the locked state of an event.
func set_event_locked(event_id: StringName, locked: bool) -> void:
	event_registry[event_id].locked = locked


## Returns true if the event is locked.
func is_event_locked(event_id: StringName) -> bool:
	return event_registry[event_id].locked


## Marks an event as completed.
func mark_event_as_completed(event_id: StringName) -> void:
	event_registry[event_id].times_seen += 1


## Returns true if the event is completed.
func is_event_completed(event_id: StringName) -> bool:
	return event_registry[event_id].times_seen > 0


## Returns an array of completed events.
func get_completed_events() -> Array[StringName]:
	var arr: Array[StringName] = []
	for event_id in event_registry:
		if get_event(event_id).transient:
			continue
		if event_registry[event_id].times_seen > 0:
			arr.append(event_id)
	return arr


## Refreshes the event queue. Returns true if there are new changes.
func refresh_event_queue() -> bool:
	var old_event_queue := event_queue
	event_queue = []
	var completed_events := get_completed_events()
	for event_id in event_registry:
		var state: Dictionary = event_registry[event_id]
		if state.chara: # character events are not included in the queue
			continue
		if state.locked:
			continue
		if state.event.once and state.times_seen > 0:
			continue
		if not state.event.check_requirements(completed_events):
			continue
		if not state.event.check_conditions():
			continue
		event_queue.append(event_id)
	event_queue.sort_custom(func(a, b): return event_registry[a].priority > event_registry[b].priority)
	return old_event_queue != event_queue
	

## Returns true if this character has character events.
func has_character_events(chara: CharacterInfo) -> bool:
	return chara in character_events
	

## Returns true if there are new character events.
## This requires [method refresh_event_queue] to have been called first.
func has_new_character_event(chara: CharacterInfo) -> bool:
	if not has_character_events(chara):
		return false
	for evq in event_queue:
		for evc in character_events[chara]:
			if evq == evc:
				return true
	return false
	

## Returns the character event. Returns the latest event by default.
func get_character_event(chara: CharacterInfo, index := -1) -> StringName:
	return character_events[chara][index]


## Plays a specific event, bypassing the queue.
func start_event(event_id: StringName, extra_game_states := []) -> void:
	stop_event()

	# create the scene and add it to the *root*
	var scene := preload('story_event_scene.tscn').instantiate()
	scene.name = 'StoryEventScene'
	scene.image_library = image_library
	get_tree().root.add_child(scene)
	
	# setup our own references
	current_event_id = event_id
	current_event_scene = scene

	# finish up dialogue scene
	scene.dialogue_started.connect(func(): DialogueEvents.event_started.emit(event_id))
	scene.dialogue_finished.connect(stop_event)

	# start the scene
	var event := get_event(event_id)
	var script_env := [
		Persistent,
		Game.settings,
	]
	if event.context == StoryEvent.Context.INDEPENDENT:
		pass
	elif event.context == StoryEvent.Context.OVERWORLD:
		script_env.append(Overworld.instance())
	elif event.context == StoryEvent.Context.BATTLE:
		script_env.append(Battle.instance())
	scene.start(event.dialog_resource, event.start, script_env + extra_game_states)


## Forcefully stops current ongoing event.
func stop_event() -> void:
	if current_event_scene:
		var event_id := current_event_id
		current_event_id = ''
		current_event_scene.queue_free()
		current_event_scene = null
		mark_event_as_completed(event_id)
		DialogueEvents.event_ended.emit(event_id)


## Starts the queue.
func start_queue(extra_game_states := []) -> void:
	DialogueEvents.queue_started.emit()
	is_playing_queue = true
	while event_queue.size() > 0:
		start_event(event_queue.pop_front(), extra_game_states)
		await DialogueEvents.event_ended
	is_playing_queue = false
	DialogueEvents.queue_ended.emit()


## The next event in the queue will not be played.
func stop_queue() -> void:
	stop_event()
	event_queue.clear()


func _on_start_event_requested(event_id: StringName) -> void:
	if event_id:
		start_event(event_id)
	else:
		refresh_event_queue()
		start_queue()
		

func _on_stop_event_requested() -> void:
	if is_playing_queue:
		stop_queue()
	else:
		stop_event()


func save_state() -> Dictionary:
	return {
		current_event_id = current_event_id,
		# current_dialogue_scene = current_dialogue_scene,
		is_playing_queue = is_playing_queue,

		event_registry = event_registry.duplicate(),
		character_events = character_events.duplicate(),
		event_queue = event_queue.duplicate(),
	}


func load_state(save: Dictionary) -> void:
	stop_event()
	current_event_id = save.current_event_id
	# current_dialogue_scene = save.current_dialogue_scene
	is_playing_queue = save.is_playing_queue

	event_registry = save.event_registry
	character_events = save.character_events
	event_queue.assign(save.event_queue)

	if current_event_id:
		start_event(current_event_id)


func _on_dialogue_rollback_requested() -> void:
	current_event_scene.next(current_event().start)