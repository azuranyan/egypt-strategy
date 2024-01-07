@tool
## Simple grid class that syncs itself to world changes.
class_name Grid
extends Node2D

@export var world: World:
	set(value):
		if world == value:
			return
		world = value
		if is_node_ready():
			update_configuration_warnings()

@export var tile_size: float:
	set(value):
		if tile_size == value:
			return
		tile_size = value
		if is_node_ready():
			_update()
		
@export var size: Vector2i:
	set(value):
		if size == value:
			return
		size = value
		if is_node_ready():
			_update()

@export var thickness: float = 1:
	set(value):
		if thickness == value:
			return
		thickness = value
		if is_node_ready():
			_update()
		
	
func _draw():
	var thick_x := Vector2(0.5, 0) * thickness
	var thick_y := Vector2(0, 0.5) * thickness
	
	for i in size.x + 1:
		var p1 := (Vector2(i, 0)) * tile_size - thick_y
		var p2 := (Vector2(i, size.y)) * tile_size + thick_y
		draw_line(p1, p2, Color.WHITE, thickness, true)
		
	for i in size.y + 1:
		var p1 := (Vector2(0, i)) * tile_size - thick_x
		var p2 := (Vector2(size.x, i)) * tile_size + thick_x
		draw_line(p1, p2, Color.WHITE, thickness, true)


func _get_configuration_warnings() -> PackedStringArray:
	if not world:
		return ["World is not assigned!"]
	return []


func _exit_tree():
	request_ready()
	

func _update():
	tile_size = world.tile_size
	size = world.map_size
	transform = world.world_transform
	queue_redraw()
	

func _on_world_world_changed():
	_update()
