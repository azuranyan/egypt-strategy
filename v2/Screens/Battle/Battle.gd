@tool
extends Node

class Action:
	var frame: int
	var fun: Callable
	var args: Array
	
var action_stack: Array[Action] = []
var frames: int = 0

## Transformation matrix for world to screen.
var world_to_screen_transform: Transform2D

## Transformation matrix for screen to world.
var screen_to_world_transform: Transform2D

var uniform_world_transform: Transform2D

var uniform_world_transform_inverse: Transform2D

var current_map: BattleMap


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
	current_map = scene.instantiate() as BattleMap
	
	recalculate_world_transform()
	recalculate_uniform_world_transform()
	
	get_tree().change_scene_to_packed(scene)

func get_viewport_size() -> Vector2i:
	# TODO get this properly
	return Vector2i(1920, 1080)
	
func recalculate_world_transform():
	var vp = get_viewport_size()
	
	# some default values for calculation: they will be used in scale
	# so we have to make sure they aren't zero so we don't get det==0
	var ws := current_map.internal_world_size
	if current_map.internal_world_size.x == 0 or current_map.internal_world_size.y == 0:
		ws = vp
		
	var yr := current_map.y_ratio
	if current_map.y_ratio == 0:
		yr = 1.0
	
	var m := Transform2D()
	
	# apply world skew and weirdge offset
	m = m.rotated(deg_to_rad(45))
	m = m.translated(current_map.offset)
	
	# apply viewport scaling
	var final_scaling := Vector2()
	final_scaling.x = vp.x/ws.x
	final_scaling.y = vp.y/ws.y * yr
	m = m.scaled(final_scaling)
	
	# apply viewport translation for 0, 0
	m = m.translated(vp/2)
	
	world_to_screen_transform = m
	screen_to_world_transform = m.affine_inverse()

func recalculate_uniform_world_transform():
	var m = Transform2D()
	
	# more det==0 safeguards
	var scaling: float = current_map.tile_size if current_map.tile_size != 0 else 1.0
	
	m = m.translated(Vector2(0.5, 0.5) - Vector2(current_map.map_size)/2)
	m = m.scaled(Vector2(scaling, scaling))
	m = m.rotated(deg_to_rad(-90))
	
	uniform_world_transform = m
	uniform_world_transform_inverse = m.affine_inverse()
	
