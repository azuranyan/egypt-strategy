class_name SceneTransition
extends Node


var old_scene: Node
var new_scene: Node


func transition(_old_scene: Node, _new_scene: Node):
	Game.transition_started.emit(self)
	old_scene = _old_scene
	new_scene = _new_scene
	await _transition()
	Game.transition_ended.emit(self)
	old_scene = null
	new_scene = null
	
	
	
func _transition():
	# add dummy of the old screen
	var dummy := Game.DUMMY_SCENE.instantiate() as Node
	get_tree().root.add_child(dummy)
	
	pass
	
