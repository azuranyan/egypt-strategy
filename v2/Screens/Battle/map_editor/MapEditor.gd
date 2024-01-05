@tool
class_name MapEditor extends Node2D


signal world_changed


# World changes are quite expensive so we only refresh on a fixed time.
const WORLD_CHANGE_UPDATE_FREQUENCY: float = 0.5


@export_subgroup("World Settings")

## The image source.
@export var texture: Texture2D:
	set(value):
		texture = value
		_queue_update()

## The size of the map.
@export var map_size: Vector2i:
	set(value):
		map_size = value
		_queue_update()

## Tile size deduced from source (in world_instance size units).
@export var tile_size: float:
	set(value):
		tile_size = value
		_queue_update()

## The off-center offset of the level (in world_instance size units).
@export var offset: Vector2:
	set(value):
		offset = value
		_queue_update()

## Ratio of tile height to its width.
@export var y_ratio: float:
	set(value):
		y_ratio = value
		_queue_update()
		

## World transformation matrix.
var world_transform: Transform2D

## World transformation inverse.
var world_inverse: Transform2D

var _cached_global_transform: Transform2D
var _cached_global_inverse: Transform2D

var _world_update_cooldown: float = 0
var _errors: PackedStringArray = []


func _ready():
	_update_world.call_deferred()


func _process(delta):
	_world_update_cooldown -= delta
	if _world_update_cooldown <= 0:
		_update_world()
		set_process(false)
		

func _get_configuration_warnings() -> PackedStringArray:
	var arr: PackedStringArray = []
	
	if _world_update_cooldown > 0:
		arr.append('Updating')
		
	arr.append_array(_errors)
	
	return arr
	
	
func _queue_update():
	if not is_node_ready():
		await ready
	if WORLD_CHANGE_UPDATE_FREQUENCY >= 0:
		_world_update_cooldown = WORLD_CHANGE_UPDATE_FREQUENCY
		update_configuration_warnings() # 'Updating' message
		set_process(true)
	else:
		_update_world()
		
		
func _update_world():
	recalculate_world_transforms()
	world_changed.emit()
	
	#$TextureRect.texture = texture
	
	#$Grid.tile_size = tile_size
	#$Grid.size = map_size
	#$Grid.transform = world_transform


func recalculate_world_transforms():
	_errors.clear()
	
	var internal_size := get_internal_size()
	 
	var ws = internal_size
	var yr = y_ratio
	
	if internal_size.x == 0 or internal_size.y == 0:
		_errors.append('Invalid internal size (check texture).')
	
	if y_ratio <= 0:
		_errors.append('Invalid y_ratio.')
	
	update_configuration_warnings()
	
	var m = Transform2D()
	if _errors.size() == 0:
		# apply world skew and  offset
		m = m.rotated(deg_to_rad(45))
		m = m.translated(offset)
		
		# apply y_ratio
		m = m.scaled(Vector2(1, yr))
		
	world_transform = m
	world_inverse = m.affine_inverse()

	recalculate_global_transform()


func recalculate_global_transform():
	# cache this so we dont recompute everytime
	_cached_global_transform = get_global_transform() * world_transform.scaled(Vector2(tile_size, tile_size))
	_cached_global_inverse = _cached_global_transform.affine_inverse()
	
	
