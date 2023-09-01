@tool
extends Node

class Action:
	var frame: int
	var fun: Callable
	var args: Array
	
var action_stack: Array[Action] = []
var frames: int = 0

var current_map: Node2D


func _process(delta):
	frames += 1
	
func push_action(fun: Callable, args: Array):
	var action := Action.new()
	action.frame = frames
	action.fun = fun
	action.args = args
	action_stack.push_back(action)

func pop_action():
	action_stack.pop_back()
	
func undo():
	pop_action()
	action_stack[-1].fun.callv(action_stack[-1].args)
	
func load_map(res: String):
	load_map_scene(load(res) as PackedScene)
	
func load_map_scene(scene: PackedScene):
	current_map = scene.instantiate() as Node2D
	
	#recalculate_world_transform()
	#recalculate_uniform_world_transform()
	
	get_tree().change_scene_to_packed(scene)

func get_viewport_size() -> Vector2i:
	# TODO get this properly
	return Vector2i(1920, 1080)
	
