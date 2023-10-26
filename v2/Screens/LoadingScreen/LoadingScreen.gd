extends CanvasLayer
# A modified version of background loading screen tutorial.
# https://www.youtube.com/watch?v=-_aH3n_3T1k
class_name LoadingScreen

signal safe_to_load


func update(progress: float):
	$Control/ProgressBar.value = progress


func fade_out():
	$AnimationPlayer.play('fade_out')
	await $AnimationPlayer.animation_finished
	queue_free()
