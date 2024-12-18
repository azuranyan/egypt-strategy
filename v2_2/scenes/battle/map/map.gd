@tool
class_name Map
extends Node2D


signal world_changed
signal object_added(obj: MapObject)
signal object_removed(obj: MapObject)

## Pathing group ordered by increasing strictness.
enum PathingGroup {
	## Object is always passable.
	NONE,
	
	## Object is impassable to enemy units.
	UNIT,
	
	## Object is impassable but can by bypassed with a special movement skill.
	DOODAD,
	
	## Object is impassable but can by bypassed with a special movement skill.
	TERRAIN,
	
	## Object is impassable and cannot be bypassed.
	IMPASSABLE,
}

## Heading direction.
enum Heading {EAST, SOUTH, WEST, NORTH}

## UnitState directions corresponding to heading.
const DIRECTIONS: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

## A special out of bounds location.
const OUT_OF_BOUNDS := Vector2(69, 69)


@export_group("World")

## The world to use.
@export var world: World = null:
	set(value):
		if is_instance_valid(world):
			world.world_changed.disconnect(queue_world_update)
		world = value
		queue_world_update()
		if is_instance_valid(world):
			world.world_changed.connect(queue_world_update)
		update_configuration_warnings()
		
## How often the changes are updated when world parameters are changed.
@export var world_update_frequency: float = 0.5

@export_group("Level")

## For painting custom pathing.
@export var pathing_painter: TileOverlay


var _world_update_cooldown: float = 0


## Converts facing angle to heading.
static func to_heading(facing: float) -> Heading:
	var angle := fmod(facing + PI/4, (PI*2))
	if angle < 0:
		angle += (PI*2)
	return int(angle/(PI/2)) % 4 as Heading


## Converts heading to facing angle.
static func to_facing(heading: Heading) -> float:
	return heading * (PI/2)


## Returns cell.
static func cell(pos: Vector2) -> Vector2:
	return Vector2(round(pos.x), round(pos.y))


func _ready():
	y_sort_enabled = true
	_update_world_changes()
	
	
func _enter_tree():
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)
	
	
func _exit_tree():
	child_entered_tree.disconnect(_on_child_entered_tree)
	child_exiting_tree.disconnect(_on_child_exiting_tree)
	request_ready()
	
	
func _get_configuration_warnings() -> PackedStringArray:
	var arr := PackedStringArray()
	if _world_update_cooldown > 0:
		arr.append('updating..')
	if not is_instance_valid(world):
		arr.append('world is not assigned')
	return arr
	
	
func _process(delta):
	_world_update_cooldown -= delta
	if _world_update_cooldown <= 0:
		_update_world_changes()
		update_configuration_warnings()
		set_process(false)
		

func _update_world_changes():
	get_tree().call_group("MapObjects", "_world_changed", world)
		
	
## Queues a world update.
func queue_world_update():
	if not is_node_ready():
		await ready
	if world_update_frequency >= 0:
		_world_update_cooldown = world_update_frequency
		update_configuration_warnings()
		set_process(true)
	else:
		_update_world_changes()
		

func _on_child_entered_tree(node: Node):
	if node is MapObjectContainer:
		node.object_added.connect(_add_object)
		node.object_removed.connect(_remove_object)
	elif node is MapObject:
		_add_object(node)
	
	
func _on_child_exiting_tree(node: Node):
	if node is MapObjectContainer:
		node.object_added.disconnect(_add_object)
		node.object_removed.disconnect(_remove_object)
	elif node is MapObject:
		_remove_object(node)
	
	
func _add_object(obj: MapObject):
	obj.add_to_group("MapObjects")
	obj._world_changed(world)
	object_added.emit(obj)


func _remove_object(obj: MapObject):
	obj.remove_from_group("MapObjects")
	obj._world_changed(null)
	object_removed.emit(obj)


func _is_map_object_container() -> bool:
	# Map <-> MapObject <-> MapObjectContainer <-> Map
	return true
	
	
	
