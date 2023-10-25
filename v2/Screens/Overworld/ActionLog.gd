extends Node2D
class_name ActionLog

const ActionLogEntry := preload("res://Screens/Overworld/ActionLogEntry.tscn")


@export var display_duration: float = 5.0


func display(message: String):
	var widget := ActionLogEntry.instantiate()
	widget.get_node('Label').text = message
	$VBoxContainer.add_child(widget)
	await get_tree().create_timer(display_duration).timeout
	var anim: AnimationPlayer = widget.get_node('AnimationPlayer')
	anim.play('disappear')
	await anim.animation_finished
	$VBoxContainer.remove_child(widget)
	
