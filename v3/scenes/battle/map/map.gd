@tool
class_name Map
extends Node2D


signal world_changed


const OUT_OF_BOUNDS := Vector2(69, 69)


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

## The world to use.
@export var world: World = null:
	set(value):
		if is_instance_valid(world):
			world.world_changed.disconnect(queue_world_update)
		world = value
		if is_instance_valid(world):
			world.world_changed.connect(queue_world_update)
		update_configuration_warnings()
			

## How often the changes are updated when world parameters are changed.
@export var world_update_frequency: float = 0.5

var world_sprite: Sprite2D
var grid: MapGrid
var world_transform: Transform2D
var uniform_transform: Transform2D

var _world_update_cooldown: float = 0


func _ready():
	_remove_hidden_child()
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
	
	
func _remove_hidden_child():
	var expunged := []
	for child in get_children(true):
		if child.has_meta("Map_hidden_child"):
			expunged.append(child)
	for child in expunged:
		child.queue_free()


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
	if node is ObjectContainer:
		node.object_added.connect(_add_object)
		node.object_removed.connect(_remove_object)
	elif node is MapObject:
		_add_object(node)
	
	
func _on_child_exiting_tree(node: Node):
	if node is ObjectContainer:
		node.object_added.disconnect(_add_object)
		node.object_removed.disconnect(_remove_object)
	elif node is MapObject:
		_remove_object(node)
	
	
func _add_object(obj: MapObject):
	obj.add_to_group("MapObjects")


func _remove_object(obj: MapObject):
	obj.remove_from_group("MapObjects")
