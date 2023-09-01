@tool
extends Node2D
class_name Doodad

@export_category("Doodad")

## The image texture to use.
@export var texture: Texture2D:
	set(value):
		texture = value
		$Sprite2D.texture = value
	get:
		return texture

## The world space to reference.
@export var world: World:
	set(value):
		world = value
		_update_tile()
	get:
		return world
	
## The position of this object uniform world space.
@export var source_pos: Vector2:
	set(value):
		source_pos = value
		_update_tile()
	get:
		return source_pos

func _update_tile():
	if !is_inside_tree() or world == null: return
	
	# position ourselves here
	position = world.uniform_to_screen(source_pos)
	_update_sprite()
	
	var p := [
		Vector2(-0.5, -0.5),
		Vector2(+0.5, -0.5),
		Vector2(+0.5, +0.5),
		Vector2(-0.5, +0.5),
	]
	
	# scale the tile to world size
	for i in range(4):
		p[i] *= world.tile_size
		
	var pos = world.uniform_world_transform * source_pos
	
	# translate the tile to where it should be
	for i in range(4):
		p[i] += world.uniform_world_transform * source_pos
	
	# put the tile in world space to screen space
	for i in range(4):
		$Polygon2D.polygon[i] = world.world_to_screen_transform * p[i] - position
		
		

func _update_sprite():
	if !is_inside_tree() or world == null: return
	
	$Sprite2D.scale = world.get_viewport_scale()
	$Sprite2D.position = world.get_viewport_offset() - position
	
	
func _ready():
	var map = get_map()
	if map != null:
		world = map.world
	_update_sprite()
	_update_tile()


func get_map() -> Map:
	var node = get_parent()
	while node != null:
		if node is Map:
			break
		else:
			node = node.get_parent()
	return node


func _notification(what):
	if what == NOTIFICATION_PARENTED:
		var map := get_map()
		if map != null:
			world = map.world
	
		
