@tool
class_name NewMap
extends Control


signal world_changed

# World changes are quite expensive so we only refresh on a fixed time.
const WORLD_CHANGE_UPDATE_FREQUENCY: float = 0.0

const OUT_OF_BOUNDS := Vector2(69, 420)

@export_subgroup("World")

## The image source.
@export var texture: Texture2D:
	set(value):
		texture = value
		if not is_node_ready():
			await ready
		_queue_update()

## The size of the map.
@export var map_size: Vector2i:
	set(value):
		map_size = value
		if not is_node_ready():
			await ready
		_queue_update()

## Tile size deduced from source (in world_instance size units).
@export var tile_size: float:
	set(value):
		tile_size = value
		if not is_node_ready():
			await ready
		_queue_update()

## The off-center offset of the level (in world_instance size units).
@export var offset: Vector2:
	set(value):
		offset = value
		if not is_node_ready():
			await ready
		_queue_update()

## Ratio of tile height to its width.
@export var y_ratio: float:
	set(value):
		y_ratio = value
		if not is_node_ready():
			await ready
		_queue_update()
	

## World transformation matrix.
var world_transform: Transform2D
var world_inverse: Transform2D

var _world_update_cooldown: float = 0
var _transform_errors: PackedStringArray = []

#region Node
func _ready():
	#world = World.new()
	#world_instance = preload("res://Screens/Battle/map/WorldInstance.tscn").instantiate()
	#world_instance.z_index -= 10
	#add_child(world_instance, false, Node.INTERNAL_MODE_BACK)
	pass

	
func _process(delta):
	_world_update_cooldown -= delta
	if _world_update_cooldown <= 0:
		_update_world()
		set_process(false)
		

func _get_configuration_warnings() -> PackedStringArray:
	var arr: PackedStringArray = []
	
	if _world_update_cooldown > 0:
		arr.append('Updating')
		
	arr.append_array(_transform_errors)
	
	return arr
	
	
func _on_child_entered_tree(node: Node):
	if node is MapObject:
		# node may not be ready at this point and doing anything to it before
		# it's ready causes tons of headache
		if not node.is_node_ready():
			await node.ready
		_map_object_added(node)


func _on_child_exiting_tree(node: Node):
	if node is MapObject:
		_map_object_removed(node)
		
#endregion Node


## Returns the internal size.
func get_internal_size() -> Vector2:
	return texture.get_size()
	

## Returns the internal scaling.
func get_internal_scale() -> Vector2:
	return $TextureRect.size / get_internal_size()


## Returns the global coordinates of uniform v.
func to_global(v: Vector2) -> Vector2:
	#return get_global_transform() * world_transform * ((v + Vector2(0.5, 0.5)) * tile_size)
	return get_global_transform() * world_transform * (v * tile_size)


## Returns the uniform coordinates of global v.
func to_uniform(v: Vector2) -> Vector2:
	var m := get_global_transform() * world_transform * Transform2D(0, Vector2(tile_size, tile_size), 0, Vector2.ZERO)
	#return m.affine_inverse() * v - Vector2(0.5, 0.5)
	return m.affine_inverse() * v
	
	
## Recalculates world transforms.
func recalculate_world_transforms():
	_transform_errors.clear()
	
	var internal_size := get_internal_size()
	 
	var ws = internal_size
	var yr = y_ratio
	
	if internal_size.x == 0 or internal_size.y == 0:
		_transform_errors.append('Invalid internal size (check texture).')
	
	if y_ratio <= 0:
		_transform_errors.append('Invalid y_ratio.')
	
	update_configuration_warnings()
	
	var m = Transform2D()
	if _transform_errors.size() == 0:
		# apply world skew and  offset
		m = m.rotated(deg_to_rad(45))
		m = m.translated(offset)
		
		# apply y_ratio
		m = m.scaled(Vector2(1, yr))
		
	world_transform = m
	world_inverse = m.affine_inverse()
	
	
func _queue_update():
	if WORLD_CHANGE_UPDATE_FREQUENCY >= 0:
		_world_update_cooldown = WORLD_CHANGE_UPDATE_FREQUENCY
		update_configuration_warnings()
		set_process(true)
	else:
		_update_world()
	

func _update_world():
	recalculate_world_transforms()
	world_changed.emit()
	
	$TextureRect.texture = texture
	
	$Grid.tile_size = tile_size
	$Grid.size = map_size
	$Grid.transform = world_transform
	
	
func _map_object_added(obj: MapObject):
	obj.map = self
	
	
func _map_object_removed(obj: MapObject):
	obj.map = null
