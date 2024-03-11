class_name AutopauseNode
extends Node
## A node that automatically pauses the game when it enters the tree.
##
## This will also properly unpause the game once all the nodes exit the tree.


func _ready() -> void:
	Game.push_pause(self)


func _exit_tree() -> void:
	Game.pop_pause(self)