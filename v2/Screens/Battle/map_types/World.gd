@tool
## Contains the world data like texture and transforms.
class_name World
extends Node2D


signal world_changed


## The image source.
@export var texture: Texture2D:
	set(value):
		if texture == value:
			return
		texture = value
		if is_node_ready():
			_update()

## The size of the map.
@export var map_size: Vector2i:
	set(value):
		if map_size == value:
			return
		map_size = value
		if is_node_ready():
			_update()

## Tile size deduced from source (in world_instance size units).
@export var tile_size: float:
	set(value):
		if tile_size == value:
			return
		tile_size = value
		if is_node_ready():
			_update()

## The off-center offset of the level (in world_instance size units).
@export var offset: Vector2:
	set(value):
		if offset == value:
			return
		offset = value
		if is_node_ready():
			_update()

## Ratio of tile height to its width.
@export var y_ratio: float:
	set(value):
		if y_ratio == value:
			return
		y_ratio = value
		if is_node_ready():
			_update()
	

## World transformation matrix.
var world_transform: Transform2D
var world_inverse: Transform2D

var _cached_global_transform: Transform2D
var _cached_global_inverse: Transform2D

var _transform_errors: PackedStringArray = []


@onready var texture_rect := $FullRect/TextureRect


#region Node
func _ready():
	_update()
	

func _exit_tree():
	request_ready()
	
	
func _get_configuration_warnings() -> PackedStringArray:
	var arr: PackedStringArray = []
	arr.append_array(_transform_errors)
	return arr
#endregion Node


func _update():
	recalculate_world_transforms()
	
	texture_rect.texture = texture
			
	world_changed.emit()
	

## Returns the internal size.
func get_internal_size() -> Vector2:
	if texture:
		return texture.get_size()
	else:
		return Vector2.ZERO
	

## Returns the internal scaling.
func get_internal_scale() -> Vector2:
	var internal_size = get_internal_size()
	if internal_size != Vector2.ZERO:
		return texture_rect.size / internal_size
	else:
		return Vector2.ONE


## Returns the global coordinates of uniform v.
func as_global(v: Vector2) -> Vector2:
	return _cached_global_transform * v


## Returns the uniform coordinates of global v.
func as_uniform(v: Vector2) -> Vector2:
	return _cached_global_inverse * v
	

func as_aligned(v: Vector2) -> Vector2:
	return as_global(v - Vector2(0.5, 0.5))
	
	
## Snaps the node to the cell.
# TODO do not use, awful func to be replaced later
func snap(node: Node2D):
	if node is MapObject:
		node.map_pos = Vector2(int(node.map_pos.x), int(node.map_pos.y))
	else:
		var v := as_uniform(node.position)
		node.position = as_global(Vector2(int(v.x), int(v.y)))
		

## Returns the cell as an index for a 1D array. This only takes the world bounds,
## so callers should make sure it's not trying to use with playable bounds.
# TODO prob should not be here? idk. feels very much like implementation detail;
# heck even the description sounds so much like an implementation detail
func to_index(v: Vector2) -> int:
	return int(v.y * map_size.x + v.x)

	
## Recalculates world transforms.
func recalculate_world_transforms():
	_transform_errors.clear()
	
	var internal_size := get_internal_size()
	if internal_size.x == 0 or internal_size.y == 0:
		_transform_errors.append('Invalid internal size (check texture).')
	
	if y_ratio <= 0:
		_transform_errors.append('Invalid y_ratio.')
	
	update_configuration_warnings()
	
	var m = Transform2D()
	if _transform_errors.size() == 0:
		# apply world skew
		m = m.rotated(deg_to_rad(45))
		
		# apply y_ratio
		m = m.scaled(Vector2(1, y_ratio))
		
		# apply offset
		m = m.translated(offset)
		
		
	world_transform = m
	world_inverse = m.affine_inverse()
	
	recalculate_global_transform()


## Recalculates combined world and global transform.
func recalculate_global_transform():
	# cache this so we dont recompute everytime
	#_cached_global_transform = get_global_transform() * world_transform * Transform2D(0, Vector2(tile_size, tile_size), 0, Vector2.ZERO)#.scaled(Vector2(tile_size, tile_size))
	_cached_global_transform = get_global_transform() * world_transform * Transform2D(0, Vector2(tile_size, tile_size), 0, Vector2(0.5, 0.5) * tile_size)
	_cached_global_inverse = _cached_global_transform.affine_inverse()
	
	
