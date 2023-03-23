extends Node

func wait_for_seconds(seconds: float, pause: bool = false) -> void:
	yield(get_tree().create_timer(seconds, pause), "timeout")


func wait_for_physics_frames(frames: int, pause: bool = false) -> void:
	for i in range(frames):
		yield(get_tree(), "physics_frame")


func wait_for_frames(frames: int, pause: bool = false) -> void:
	for i in range(frames):
		yield(get_tree(), "idle_frame")
