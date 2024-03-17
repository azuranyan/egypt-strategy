class_name SoundQueue
extends Node
## Allows sounds to be queued up.
## https://www.youtube.com/watch?v=bdsHf08QmZ4


const DEFAULT_QUEUE_SIZE := 5


## The audio stream player to be used as a base for the queue.[br]
## [br]
## [b]This should be set before ready and will not be updated if changed after ready.[/b]
@export var audio_stream_player: AudioStreamPlayer

## The maximum queue size.[br]
## [br]
## [b]This should be set before ready and will not be updated if changed after ready.[/b]
@export_range(1, 100) var queue_size: int = DEFAULT_QUEUE_SIZE


var _queue: Array[AudioStreamPlayer] = []	
var _next_index := 0


func _ready() -> void:
	assert(audio_stream_player, "Audio stream player is not set!")

	for i in queue_size:
		var node := audio_stream_player.duplicate()
		add_child(node)
		_queue.append(node)


## Plays the sound of [member audio_stream_player].
func play(stream: AudioStream) -> void:
	# if the queue is full, sound will be skipped
	if _queue[_next_index].playing:
		return
	
	_queue[_next_index].stream = stream
	_queue[_next_index].play()
	_next_index = (_next_index + 1) % queue_size
