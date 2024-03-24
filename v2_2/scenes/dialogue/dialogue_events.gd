extends Node


## Emitted to send a request to start an event.
## If [code]event_id[/code] is empty, the queue will be started.
signal start_event_requested(event_id: StringName)

## Emitted to send a request to stop playing the current event.
signal stop_event_requested

## Emitted when an event queue is started.
## Events will continuously play until the queue has been cleared.
signal queue_started

## Emitted when an event queue is ended.
signal queue_ended

## Emitted when an event is started.
signal event_started(event_id: StringName)

## Emitted when an event has ended.
signal event_ended(event_id: StringName)

## Emitted when new event is added to the queue.
signal new_event_unlocked(event_id: StringName)

## Emitted when rollback is requested.
signal rollback_requested(source)

## Emitted when dialogue is continued.
signal next_requested(source)

signal dialogue_line_started(dialogue_line, balloon)

signal dialogue_line_finished(dialogue_line, balloon)