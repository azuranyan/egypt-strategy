class_name Dialogue
extends Node


const StoryEventScene := preload("story_event_scene.gd")
const ImageLibrary := preload("res://events/image_library.gd")


var image_library: ImageLibrary

var current_event_id: StringName
var current_event_scene: StoryEventScene

var event_registry: Dictionary
var character_events: Dictionary
var event_queue: Array[StringName]
var script_env: Array


static func instance() -> Dialogue:
	return Game.dialogue


func _ready() -> void:
	image_library = preload('res://events/image_library.tscn').instantiate()
	add_child(image_library)
	image_library.name = 'ImageLibrary'

	DialogueEvents.start_queue_requested.connect(start_queue)
	DialogueEvents.stop_queue_requested.connect(stop_queue)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed('vn_rollback'):
		_on_dialogue_rollback_requested()


#region Queue Controls
## Starts the event queue.
func start_queue(queue: Array[StringName], extra_game_states := []) -> void:
	stop_queue()

	event_queue = queue.duplicate()
	DialogueEvents.event_ended.connect(_queue_event_finished.unbind(1))

	# start the queue
	DialogueEvents.queue_started.emit()
	if event_queue:
		start_event(event_queue.pop_front(), extra_game_states)
	else:
		_queue_event_finished.call_deferred()


## Forcefully stops the event queue. This will cause the current event to not finish.
func stop_queue() -> void:
	if event_queue:
		event_queue.clear()
		stop_event()
	

func _queue_event_finished() -> void:
	if event_queue:
		_start_event.call_deferred(event_queue.pop_front(), script_env)
	else:
		DialogueEvents.event_ended.disconnect(_queue_event_finished)
		DialogueEvents.queue_ended.emit()


## Plays a specific event, bypassing the queue.
func start_event(event_id: StringName, extra_game_states := []) -> void:
	stop_event()

	# initialize the script environment
	var event := get_event(event_id)
	var env := [
		Persistent,
		Game.settings,
	]
	if event.context == StoryEvent.Context.INDEPENDENT:
		pass
	elif event.context == StoryEvent.Context.OVERWORLD:
		env.append(Overworld.instance())
	elif event.context == StoryEvent.Context.BATTLE:
		env.append(Battle.instance())
	env += extra_game_states

	_start_event(event_id, env)


func _start_event(event_id: StringName, env: Array) -> void:
	# create the scene and add it to the *root*
	var scene := preload('story_event_scene.tscn').instantiate()
	scene.name = 'StoryEventScene'
	scene.image_library = image_library
	get_tree().root.add_child(scene)
	
	# setup our own references
	current_event_id = event_id
	current_event_scene = scene
	scene.dialogue_finished.connect(_finish_event)

	# initialize the script environment
	script_env = env

	# start the scene
	var event := get_event(event_id)
	scene.start(event.dialog_resource, event.start, script_env)
	DialogueEvents.event_started.emit(event_id)


## Skips the event, marking it as finished.
func skip_event() -> void:
	if current_event_scene:
		current_event_scene.stop()


## Forcefully stops the current ongoing event.
func stop_event() -> void:
	if current_event_scene:
		current_event_scene.queue_free()
		_finish_event(false)


func _finish_event(completed: bool = true) -> void:
	var event_id := current_event_id
	if completed:
		mark_event_as_completed(event_id)

	current_event_id = ''
	current_event_scene = null
	DialogueEvents.event_ended.emit(event_id)
#endregion Queue Controls


#region Event Management
## Registers an event. Will overwrite existing entries.
func register_event(event: StoryEvent, chara: CharacterInfo = null) -> void:
	var state := {
		event = event,
		chara = chara,
		locked = event.locked,
		times_seen = 0,
		priority = event.priority,
	}
	
	var event_id := event.event_id

	event_registry[event_id] = state

	if chara:
		if chara in character_events:
			if event_id not in character_events[chara]:
				character_events[chara].append(event_id)
		else:
			character_events[chara] = [event_id]


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


## Returns a fresh list of available events.
func get_available_events(chara: CharacterInfo = null) -> Array[StringName]:
	var queue: Array[StringName] = []
	var completed_events := get_completed_events()
	for event_id in event_registry:
		var state: Dictionary = event_registry[event_id]
		if chara == null or state.chara != chara:
			continue
		if state.locked:
			continue
		if state.event.once and state.times_seen > 0:
			continue
		if not state.event.check_requirements(completed_events):
			continue
		if not state.event.check_conditions():
			continue
		queue.append(event_id)
	queue.sort_custom(func(a, b): return event_registry[a].priority > event_registry[b].priority)
	return queue


## Returns true if this character has character events.
func has_character_events(chara: CharacterInfo) -> bool:
	return chara in character_events
	

## Returns true if there are new character events.
## This requires [method refresh_event_queue] to have been called first.
func has_new_character_event(chara: CharacterInfo) -> bool:
	return has_character_events(chara) and get_available_events(chara)
#endregion Event Management


func save_state() -> Dictionary:
	return {
		current_event_id = current_event_id,
		# current_dialogue_scene = current_dialogue_scene,

		event_registry = event_registry.duplicate(),
		character_events = character_events.duplicate(),
		event_queue = event_queue.duplicate(),
	}


func load_state(save: Dictionary) -> void:
	stop_event()
	current_event_id = save.current_event_id
	# current_dialogue_scene = save.current_dialogue_scene

	event_registry = save.event_registry
	character_events = save.character_events
	event_queue.assign(save.event_queue)

	if current_event_id:
		start_event(current_event_id)


func _on_dialogue_rollback_requested() -> void:
	current_event_scene.next(current_event().start)
