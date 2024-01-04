@tool
extends Node2D


@export var tile_size: float:
	set(value):
		tile_size = value
		if not is_node_ready():
			await ready
		queue_redraw()
		
@export var size: Vector2i:
	set(value):
		size = value
		if not is_node_ready():
			await ready
		queue_redraw()

@export var thickness: float = 1:
	set(value):
		thickness = value
		if not is_node_ready():
			await ready
		queue_redraw()
	

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
		
	#if world:
		#var half := Vector2(0.5, 0.5)
		#
		#for i in size.x + 1:
			#var p1: Vector2 = world.uniform_to_screen(Vector2(i, 0) - half)
			#var p2: Vector2 = world.uniform_to_screen(Vector2(i, size.y)- half)
			#draw_line(p1, p2, Color(Color.BLACK, 0.3), 1, true)
			#
		#for i in size.y + 1:
			#var p1: Vector2 = world.uniform_to_screen(Vector2(0, i) - half)
			#var p2: Vector2 = world.uniform_to_screen(Vector2(size.x, i) - half)
			#draw_line(p1, p2, Color(Color.BLACK, 0.3), 1, true)
		
