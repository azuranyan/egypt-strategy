@tool
class_name NewMap extends Node2D


signal map_changed

## A special out of bounds position.
const OUT_OF_BOUNDS := Vector2(69, 420)


var world: World

# World changes are quite expensive so we only refresh on a fixed time.
@export var world_update_frequency: float = 0.5


var _world_update_cooldown: float = 0
var _errors: PackedStringArray = []


## Returns the spawn points of given spawn type.
func get_spawn_points(spawn_type: String) -> Array[SpawnPoint]:
	var arr: Array[SpawnPoint] = []
	for obj in get_tree().get_nodes_in_group("MapObjects"):
		if obj is SpawnPoint:
			if obj.spawn_type == spawn_type:
				arr.append(obj)
	return arr
			

#region Node
func _ready():
	update_configuration_warnings()
	# will force a tick of update after _ready
	set_process(true)


func _enter_tree():
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)
	
	
func _exit_tree():
	child_entered_tree.disconnect(_on_child_entered_tree)
	child_exiting_tree.disconnect(_on_child_exiting_tree)
	request_ready()
	
	
func _process(delta):
	_world_update_cooldown -= delta
	if _world_update_cooldown <= 0:
		update_configuration_warnings() # 'Updating' message
		_update()
		set_process(false)
		

func _get_configuration_warnings() -> PackedStringArray:
	var arr: PackedStringArray = []
	
	if not world:
		arr.append("World not assigned.")
		
	if _world_update_cooldown > 0:
		arr.append('Updating')
		
	arr.append_array(_errors)
	
	return arr
#endregion Node
	
	
func _queue_update():
	if world_update_frequency >= 0:
		_world_update_cooldown = world_update_frequency
		update_configuration_warnings() # 'Updating' message
		set_process(true)
	else:
		_update()
		

func _update():
	print("map::_update")
	map_changed.emit()
	get_tree().call_group("MapObjects", "_update")
	

func _add_object(obj: MapObject):
	print('map: ', obj, ' added')
	obj.map = self
	obj.world = world
	obj.add_to_group("MapObjects")


func _remove_object(obj: MapObject):
	print('map: ', obj, ' removed')
	obj.map = null
	obj.world = null
	obj.remove_from_group("MapObjects")


func _on_child_entered_tree(node: Node):
	if node is ObjectContainer:
		node.object_added.connect(_add_object)
		node.object_removed.connect(_remove_object)
	elif node is World:
		node.world_changed.connect(_queue_update)
		world = node
	
	
func _on_child_exiting_tree(node: Node):
	if node is ObjectContainer:
		node.object_added.disconnect(_add_object)
		node.object_removed.disconnect(_remove_object)
	elif node is World:
		node.world_changed.disconnect(_queue_update)
		world = null
	
	
	
