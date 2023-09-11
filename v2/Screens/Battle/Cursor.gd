@tool
extends MapObject

## A MapObject cursor.
class_name Cursor


var texture := preload("res://Screens/Battle/cursor.png") as Texture2D
	
var sprite: Sprite2D

func map_init():
	sprite = Sprite2D.new()
	sprite.texture = texture
	
	sprite.z_index = -1 # so it always draws under objects
	
	add_child(sprite)
	
	var m = Transform2D()
	
	# scale to downsize to unit vector
	m = m.scaled(Vector2(1/texture.get_size().x, 1/texture.get_size().y))

	# scale to tile size
	m = m.scaled(Vector2(world.tile_size, world.tile_size))

	sprite.transform = world._world_to_screen_transform * m
	sprite.position = Vector2.ZERO
	

#extends Sprite2D
#class_name Cursor
#
#signal position_changed(pos)
#
#var _last_position: Vector2
#
#var enable_mouse_control := false
#
#var map: Map
#
#func _enter_tree():
#	set_process_input(true)
#
## Called when the node enters the scene tree for the first time.
#func _ready():
#	await find_parent("Battle").map_loaded
#	map = find_parent("Battle").map
#
#	var m = Transform2D()
#
#	# scale to downsize to unit vector
#	m = m.scaled(Vector2(1/texture.get_size().x, 1/texture.get_size().y))
#
#	# scale to tile size
#	m = m.scaled(Vector2(map.world.tile_size, map.world.tile_size))
#
#	transform = map.world.world_to_screen_transform * m
#
#	$Node2D.global_rotation = 0
#	$Node2D.global_scale = Vector2(1, 1)
#
#
#
##func get_map() -> Map:
##	var node = get_parent()
##	while node != null:
##		if node is Battle:
##			node = node.map
##			break
##		else:
##			node = node.get_parent()
##	return node
#
#
#
#
#
