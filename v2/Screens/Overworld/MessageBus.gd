extends Node

class_name MessageBus

var event_buffers := [Array(), Array()]
var current_buffer := 0
var callbacks := {}

func _init() -> void:
	pass
	
func _ready():
	pass # Replace with function body.

func _process(_delta):
	update_events()
	
# TODO circular re-emitting events etc
func emit_event(event: String, data: Variant=null) -> void:
	var events = event_buffers[current_buffer]
	events.append([event, data])
	
func add_callback(event: String, callback: Callable) -> void:
	if not callbacks.has(event):
		callbacks[event] = Array()
	callbacks[event].append(callback)
	
func remove_callback(event: String, callback: Callable) -> void:
	var arr = callbacks.get(event)
	if arr != null:
		arr.remove(callback)
	
func update_events() -> void:
	var events = event_buffers[current_buffer]
	swap_buffers()
	for tup in events:
		var event = tup[0]
		var data = tup[1]
		var cbs = callbacks.get(event)
		
		if cbs != null:
			for cb in cbs:
				# TODO is this safe? should we call this in new context?
				# TODO this call can also generate events, so how do we
				# manage that and when can we execute it safely and in a
				# timely manner?
				cb.call(data)
	events.clear()
	
func swap_buffers() -> void:
	if current_buffer == 0:
		current_buffer = 1
	else:
		current_buffer = 0
