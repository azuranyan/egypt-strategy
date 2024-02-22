extends Node
# issue: viewport with object picking = true and handle_inputs_locally = false
# will cause input to be handled even if no objects are picked/collided
# https://github.com/godotengine/godot/issues/79897


@export var remote_path: NodePath:
	set(value):
		remote_path = value
		var node := get_node_or_null(remote_path)
		if node and node.has_method('_unhandled_input') and node.is_processing_unhandled_input():
			_remote_node = node
			set_process_unhandled_input(true)
		else:
			_remote_node = null
			set_process_unhandled_input(false)


var _remote_node: Node


func _ready():
	set_process_unhandled_input(false)
	remote_path = remote_path


func _unhandled_input(event):
	_remote_node._unhandled_input(event)
