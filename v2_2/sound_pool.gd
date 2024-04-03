class_name SoundPool
extends Node
## Selects a random stream player from its children to play.
## https://www.youtube.com/watch?v=bdsHf08QmZ4


## Whether to allow repeating the same sound twice in a row.
## This doesn't help if the audio stream players are playing the same stream though.
@export var allow_repetition: bool


var _audio_players := []
var _last_played_index := -1


func _ready() -> void:
	for child in get_children():
		if not (child is SoundQueue or child is AudioStreamPlayer):
			continue
		_audio_players.append(child)


## Plays a random sound in the pool.
func play() -> void:
	var rand_index: int
	while true:
		rand_index = randi_range(0, pool_size() - 1)
		if allow_repetition or _last_played_index != rand_index:
			break

	_audio_players[rand_index].play()
	_last_played_index = rand_index


## Returns the number of audio players in the pool.
func pool_size() -> int:
	return _audio_players.size()