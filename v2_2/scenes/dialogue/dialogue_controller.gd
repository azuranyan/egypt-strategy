class_name DialogueController
extends Control


## The action to listen to to continue the dialogue.
@export var continue_action: StringName

## The action to listen to to skip the dialogue.
@export var skip_action: StringName

@export var balloon_template: Balloon

@export_group("Connections")

@export var responses_menu: DialogueResponsesMenu


var _resource: DialogueResource
var _temp_game_states := []
var _current_line: DialogueLine
var _current_balloon: Balloon


## Starts the dialogue.
func start(dialogue_resource: DialogueResource, title: String, extra_game_states := []) -> void:
	_temp_game_states = extra_game_states.duplicate()
	# _waiting_for_input = false
	_resource = dialogue_resource
	emit_signal.call_deferred('dialogue_started')
	next(title)
	


func next(next_id: String) -> void:
	_current_line = await DialogueManager.get_next_dialogue_line(_resource, next_id, _temp_game_states)


## Returns true if we're waiting for input.
func is_waiting_for_input() -> bool:
	return _current_balloon.is_waiting_for_input()

	
## Returns true if we're waiting for a response.
func is_waiting_for_response() -> bool:
	return _current_line.responses.size() > 0