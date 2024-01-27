@tool
class_name World
extends Node2D


signal world_changed


@export var texture: Texture2D:
	set(value):
		texture = value
		_update()
		world_changed.emit()
		
@export var map_size: Vector2i = Vector2(12, 12):
	set(value):
		map_size = value
		_update()
		world_changed.emit()
		
@export var tile_size: float = 68:
	set(value):
		tile_size = value
		_update()
		world_changed.emit()
		
@export var offset: Vector2:
	set(value):
		offset = value
		_update()
		world_changed.emit()
		
@export var y_ratio: float = 1:
	set(value):
		y_ratio = value
		_update()
		world_changed.emit()
		

var world_transform: Transform2D
var world_inverse: Transform2D

var uniform_transform: Transform2D
var uniform_inverse: Transform2D


func _update():
	if not is_node_ready():
		await ready
	
	var internal_size := get_internal_size()
	if internal_size.x != 0 and internal_size.y != 0 and y_ratio > 0:
		world_transform = calculate_world_transform()
		world_inverse = world_transform.affine_inverse()
	else:
		world_transform = Transform2D()
		world_inverse = Transform2D()
	
	if tile_size != 0:
		uniform_transform = calculate_uniform_transform()
		uniform_inverse = uniform_transform.affine_inverse()
	else:
		uniform_transform = Transform2D()
		uniform_inverse = Transform2D()
	
	var viewport_size := Game.get_viewport_size()
	$Sprite2D.texture = texture
	$Sprite2D.scale = viewport_size/get_internal_size()
	
	$WorldGrid.tile_size = tile_size
	$WorldGrid.size = map_size
	$WorldGrid.transform = world_transform


## Returns the internal size.
func get_internal_size() -> Vector2:
	if texture:
		return texture.get_size()
	else:
		return Vector2.ZERO
		
		
## Returns the global coordinates of uniform v.
func as_global(v: Vector2) -> Vector2:
	return uniform_transform * v


## Returns the uniform coordinates of global v.
func as_uniform(v: Vector2) -> Vector2:
	return uniform_inverse * v
	

func as_aligned(v: Vector2) -> Vector2:
	return as_global(v - Vector2(0.5, 0.5))
	
	
## Returns world transforms.
func calculate_world_transform() -> Transform2D:
	var m = Transform2D()
	m = m.rotated(deg_to_rad(45))
	m = m.scaled(Vector2(1, y_ratio))
	m = m.translated(offset)
		
	return m


## Returns the uniform transforms.
func calculate_uniform_transform() -> Transform2D:
	return get_global_transform() * world_transform * Transform2D(0, Vector2(tile_size, tile_size), 0, Vector2(0.5, 0.5) * tile_size)
	
