extends Node


const DEFAULT_FADE_DURATION := 2


@export_group("Volume")
@export_range(0, 1) var master_volume: float = 1.0:
	set(value):
		master_volume = value
		_set_volume('Master', value)

@export_subgroup("Audio Balance")
@export_range(0, 1) var music_volume: float = 1.0:
	set(value):
		music_volume = value
		_set_volume('Music', value)

@export_range(0, 1) var voice_volume: float = 1.0:
	set(value):
		voice_volume = value
		_set_volume('Voice', value)
		
@export_range(0, 1) var sfx_volume: float = 1.0:
	set(value):
		sfx_volume = value
		_set_volume('SFX', value)
		
@export_range(0, 1) var ui_volume: float = 1.0:
	set(value):
		ui_volume = value
		_set_volume('UI', value)
		

@export_group("Connections")
@export var music_sound_queue: SoundQueue
@export var voice_sound_queue: SoundQueue
@export var sfx_sound_queue: SoundQueue
@export var ui_sound_queue: SoundQueue


func _ready() -> void:
	Game.setting_changed.connect(_on_setting_changed)


func _set_volume(bus_name: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	var volume_db := linear_to_db(linear)
	AudioServer.set_bus_volume_db(index, volume_db)


## Plays music.
func play_music(stream: AudioStream, fade_duration: float = DEFAULT_FADE_DURATION) -> void:
	if fade_duration > 0:
		var prev_index := (music_sound_queue._next_index - 1) % music_sound_queue.queue_size
		var current_player := music_sound_queue._queue[music_sound_queue._next_index]
		var prev_player := music_sound_queue._queue[prev_index]
		
		crossfade(prev_player, current_player, fade_duration)
	music_sound_queue.play(stream)


## Plays ui sound.
func play_ui_sound(stream: AudioStream) -> void:
	ui_sound_queue.play(stream)


## Crossfades [param a] into [param b] over a given duration.
func crossfade(a: AudioStreamPlayer, b: AudioStreamPlayer, duration: float = DEFAULT_FADE_DURATION) -> void:
	fade_out(a, duration)
	fade_in(b, duration)
	

## Fades in a stream player.
func fade_in(stream_player: AudioStreamPlayer, duration: float = DEFAULT_FADE_DURATION) -> void:
	var volume := stream_player.volume_db
	stream_player.volume_db = -80

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)

	tween.tween_property(stream_player, 'volume_db', volume, duration)
	await tween.finished


## Fades out a stream player.
func fade_out(stream_player: AudioStreamPlayer, duration: float = DEFAULT_FADE_DURATION) -> void:
	var volume := stream_player.volume_db

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)

	tween.tween_property(stream_player, 'volume_db', -80, duration)
	await tween.finished
	
	stream_player.stop()
	stream_player.volume_db = volume


func _on_setting_changed(setting: StringName, value: Variant) -> void:
	match setting:
		'master_volume':
			master_volume = value
		'music_volume':
			music_volume = value
		'voice_volume':
			voice_volume = value
		'sfx_volume':
			sfx_volume = value
		'ui_volume':
			ui_volume = value