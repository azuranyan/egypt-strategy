extends Node


@export var buttons: Array[Button]

@export var pressed_sound: AudioStream

@export var hover_sound: AudioStream

@onready var pressed_player: AudioStreamPlayer = $PressedPlayer
@onready var hover_player: AudioStreamPlayer = $HoverPlayer


func _ready() -> void:
	pressed_player.stream = pressed_sound
	hover_player.stream = hover_sound

	for button in buttons:
		if button == null:
			continue
		
		Util.just_connect(button, "pressed", _on_button_pressed)
		Util.just_connect(button, "mouse_entered", _on_button_hovered)

	test_music.call_deferred()


func test_music() -> void:
	AudioManager.play_music(preload("res://audio/music/AE_Golden_Age_FULL_Loop.wav"))
	await get_tree().create_timer(AudioManager.DEFAULT_FADE_DURATION + 5).timeout

	AudioManager.play_music(preload("res://audio/music/AE_Hidden_City_FULL_Loop.wav"))


func _on_button_pressed() -> void:
	AudioManager.play_ui_sound(pressed_sound)


func _on_button_hovered() -> void:
	AudioManager.play_ui_sound(hover_sound)