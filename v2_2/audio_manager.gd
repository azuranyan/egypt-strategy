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
		

@export_group("Sounds")
@export var sounds := {
	button_click = null,
	button_toggle = null,
	button_hover = null,
	select_move = null,
	invalid_action = null,
	save_load = null,
}

@export_group("Connections")
@export var music_sound_queue: SoundQueue
@export var voice_sound_queue: SoundQueue
@export var sfx_sound_queue: SoundQueue
@export var ui_sound_queue: SoundQueue


var _tweens := {}


func _ready() -> void:
	Game.setting_changed.connect(_on_setting_changed)
	if Game.settings:
		master_volume = Game.settings.master_volume
		music_volume = Game.settings.music_volume
		voice_volume = Game.settings.voice_volume
		sfx_volume = Game.settings.sfx_volume
		ui_volume = Game.settings.ui_volume


func _set_volume(bus_name: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	var volume_db := linear_to_db(linear)
	AudioServer.set_bus_volume_db(index, volume_db)


## Plays music.
func play_music(stream: AudioStream, fade_duration: float = DEFAULT_FADE_DURATION) -> AudioStreamPlayer:
	if fade_duration > 0:
		var prev_index := (music_sound_queue._next_index - 1) % music_sound_queue.queue_size
		var prev_player := music_sound_queue._queue[prev_index]
		var current_player := music_sound_queue._queue[music_sound_queue._next_index]

		crossfade(prev_player, current_player, fade_duration)
	return music_sound_queue.play(stream)


## Plays ui sound.
func play_ui_sound(stream: AudioStream) -> AudioStreamPlayer:
	return ui_sound_queue.play(stream)


## Plays SFX
func play_sfx(stream: AudioStream) -> AudioStreamPlayer:
	return sfx_sound_queue.play(stream)


## Adds button sounds to a button.
func add_button_sounds(button: BaseButton) -> void:
	if button.has_meta('button_sounds_added'):
		return
	if button.toggle_mode:
		button.toggled.connect(play_ui_sound.bind(sounds.button_toggle).unbind(1))
	else:
		button.pressed.connect(play_ui_sound.bind(sounds.button_click))
	
	button.mouse_entered.connect(play_ui_sound.bind(sounds.button_hover))
	button.set_meta('button_sounds_added', true)


func add_item_list_sounds(item_list: ItemList) -> void:
	item_list.item_selected.connect(play_ui_sound.bind(sounds.button_hover).unbind(1))
	#item_list.item_activated.connect(play_ui_sound.bind(sounds.button_click).unbind(1))


## Crossfades [param a] into [param b] over a given duration. This stops [param a] from playing.
func crossfade(a: AudioStreamPlayer, b: AudioStreamPlayer, duration: float = DEFAULT_FADE_DURATION) -> void:
	fade_out(a, duration)
	fade_in(b, duration)
	

## Fades in a stream player.
func fade_in(stream_player: AudioStreamPlayer, duration: float = DEFAULT_FADE_DURATION) -> void:
	await tween_volume(stream_player, -80, stream_player.volume_db, duration)


## Fades out a stream player.
func fade_out(stream_player: AudioStreamPlayer, duration: float = DEFAULT_FADE_DURATION) -> void:
	var volume := stream_player.volume_db

	await tween_volume(stream_player, stream_player.volume_db, -80, duration)

	stream_player.stop()
	stream_player.volume_db = volume


## Tweens the volume of a stream player.
func tween_volume(stream_player: AudioStreamPlayer, start_volume: float, end_volume: float, duration: float = DEFAULT_FADE_DURATION) -> void:
	finish_tween(stream_player)

	var tween := create_tween()
	_tweens[stream_player] = tween
		
	# set initial values
	stream_player.volume_db = start_volume

	# tween
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(stream_player, 'volume_db', end_volume, duration)

	# cleanup
	await tween.finished
	_tweens.erase(stream_player)


func is_tweening(stream_player: AudioStreamPlayer) -> bool:
	return stream_player in _tweens


func finish_tween(stream_player: AudioStreamPlayer) -> void:
	if is_tweening(stream_player):
		_tweens[stream_player].pause()
		_tweens[stream_player].custom_step(9999)

		if stream_player in _tweens:
			push_error("expired tween detected: erase when finished")
			_tweens.erase(stream_player)


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