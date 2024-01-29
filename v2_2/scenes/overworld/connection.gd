@tool
class_name TerritoryConnection
extends Node2D

@export var edge_thickness: float = 0.3:
	set(value):
		edge_thickness = value
		queue_redraw()
		
@export var width: float = 5:
	set(value):
		width = value
		queue_redraw()
		
@export var point_a: Vector2 = Vector2.ZERO:
	set(value):
		point_a = value
		_update_transform()
		
@export var point_b: Vector2 = Vector2(1920, 0):
	set(value):
		point_b = value
		_update_transform()


func _ready():
	_update_transform()


func _update_transform():
	global_position = point_a
	# line is drawn upright so we need to un-rotate to neutral
	rotation = point_a.angle_to_point(point_b) - PI/2
	queue_redraw()


func _draw():
	var d = point_a.distance_to(point_b)
	var border_offset = (width + width*(1 + edge_thickness))/2
	draw_line(Vector2.ZERO, Vector2(0, d), Color.WHITE, width, true)
	draw_line(Vector2(+border_offset, 0), Vector2(+border_offset, d), Color.BLACK, width * edge_thickness, true)
	draw_line(Vector2(-border_offset, 0), Vector2(-border_offset, d), Color.BLACK, width * edge_thickness, true)
	
