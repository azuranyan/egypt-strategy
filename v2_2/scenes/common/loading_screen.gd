class_name LoadingScreen
extends CanvasLayer
# original: Bacon and Games
# https://www.youtube.com/@baconandgames
# https://www.youtube.com/watch?v=2uYaoQj_6o0


## Emitted after transition is initialized and starts loading.
signal transition_started(anim)

## Emitted after the screen fully transitions in, before transitioning out.
signal transition_midpoint(anim)

## Emitted after the transition finishes.
signal transition_finished(anim)


@export_enum('fade_to_black') var default_transition: String = 'fade_to_black'

var _animation_name: String
var _midpoint_finished: bool

@onready var progress_bar := %ProgressBar as ProgressBar
@onready var animation_player := $AnimationPlayer as AnimationPlayer
@onready var timer := $Timer as Timer 


func _ready():
	progress_bar.hide()
	

func start_transition(anim: String) -> void:
	_animation_name = anim if animation_player.has_animation(anim) else default_transition
	_midpoint_finished = false
	animation_player.play(_animation_name)
	timer.start()
	transition_started.emit(_animation_name)


func update_progress(v: float) -> void:
	progress_bar.value = v


func finish_transition() -> void:
	timer.stop()
	if animation_player.is_playing():
		await animation_player.animation_finished
	animation_player.play_backwards(_animation_name)
	await animation_player.animation_finished
	queue_free()
	transition_finished.emit(_animation_name)


func is_midpoint_finished() -> bool:
	return _midpoint_finished


func _transition_midpoint() -> void:
	_midpoint_finished = true
	transition_midpoint.emit(_animation_name)


func _on_timer_timeout():
	progress_bar.show()
