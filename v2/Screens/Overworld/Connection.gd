@tool
extends Node2D

@export var edge_thickness: float = 0.3:
	set(value):
		edge_thickness = value
		queue_redraw()
		
@export var width: float = 5:
	set(value):
		width = value
		queue_redraw()


var a: Vector2 = Vector2.ZERO:
	set(value):
		a = value
		_update_transform()
		queue_redraw()
		
var b: Vector2 = Vector2(1920, 0):
	set(value):
		b = value
		_update_transform()
		queue_redraw()


func _update_transform():
	position = a
	# line is drawn upright so we need to un-rotate to neutral
	rotation = a.angle_to_point(b) - PI/2


func _draw():
	var d = a.distance_to(b)
	var border_offset = (width + width*(1 + edge_thickness))/2
	draw_line(Vector2.ZERO, Vector2(0, d), Color.WHITE, width, true)
	draw_line(Vector2(+border_offset, 0), Vector2(+border_offset, d), Color.BLACK, width * edge_thickness, true)
	draw_line(Vector2(-border_offset, 0), Vector2(-border_offset, d), Color.BLACK, width * edge_thickness, true)
	
