class_name Trigger
extends Node
## Base class for all scriptable event triggers.


## Whether to automatically call [method activate] on ready.
@export var autostart: bool = true


var _active: bool = false:
	set(value):
		_active = value
		process_mode = PROCESS_MODE_INHERIT if _active else PROCESS_MODE_DISABLED
		Game.trigger_state_changed.emit(self, _active)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	process_mode = PROCESS_MODE_DISABLED
	if autostart:
		activate()


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	deactivate()
	request_ready()


## Activates the objective.
func activate() -> void:
	if _active:
		return
	_active = true
	_activated()


## Deactivates the objective.
func deactivate() -> void:
	if not _active:
		return
	_deactivated()
	_active = false


## Returns true if this trigger is active.
func is_active() -> bool:
	return _active


## Called when the objective is activated.
func _activated() -> void:
	pass


## Called when the objective is deactivated.
func _deactivated() -> void:
	pass