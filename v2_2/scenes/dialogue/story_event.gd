class_name StoryEvent
extends Resource
## A binding structure for story events.


## The unique id of the events.
@export var event_id: StringName

## The dialog resource.
@export var dialog_resource: DialogueResource

## Where the dialogue should start.
@export var start: String

@export_group("Requirements")

## List of prerequisite events.
@export var requires: Array[StringName]

@export_group("Conditions")

## List of conditions to check.
@export var conditions: Array[StoryEventCondition]

@export_group("Settings")

## The priority of the event. Higher number = higher priority.
@export var priority: int

## The event starts in a locked state and must be unlocked first.
@export var locked: bool

## Whether the event will only be ran once.
@export var once: bool = true

## Whether the event is transient. Transient events are not saved in the list of completed events.
@export var transient: bool


func check_requirements(seen_events: Array[StringName]) -> bool:
	for req_id in requires:
		if req_id not in seen_events:
			return false
	return true


func check_conditions() -> bool:
	for condition in conditions:
		if condition and not condition.check_event_condition(self):
			return false
	return true