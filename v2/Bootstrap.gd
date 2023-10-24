extends Node


func _ready():
	Globals.push_screen.call_deferred(Globals.overworld, '')
	var diag := preload("res://Screens/Dialogue/Dialogue.tscn").instantiate()
	diag.visible = false
	get_tree().root.add_child.call_deferred(diag)
