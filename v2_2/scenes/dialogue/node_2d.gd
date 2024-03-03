extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	test.call_deferred()


func test() -> void:
	DialogueEvents.queue_started.connect(func(): print('queue started'))
	DialogueEvents.queue_ended.connect(func(): print('queue ended'))
	DialogueEvents.event_started.connect(func(e): print('%s started' % e))
	DialogueEvents.event_ended.connect(func(e): print('%s ended' % e))

	#var resource = load("res://scenes/dialogue/test.dialogue")
	var diag := Dialogue.new()
	add_child(diag)

	diag.register_event(load('res://events/test.tres'))

	diag.refresh_event_queue()
	print(diag.event_queue)
	diag.start_queue()
