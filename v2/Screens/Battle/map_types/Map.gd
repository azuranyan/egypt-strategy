@tool
class_name NewMap
extends Node2D


signal map_changed


## A special out of bounds position.
const OUT_OF_BOUNDS := Vector2(69, 420)

## Extra size around the map world that isn't playable but still interactible.
const PLAYABLE_BOUNDS := 5


var world: World

# World changes are quite expensive so we only refresh on a fixed time.
@export var world_update_frequency: float = 0.5


var _world_update_cooldown: float = 0
var _errors: PackedStringArray = []


#region Node
func _ready():
	update_configuration_warnings()
	# will force a tick of update after _ready
	set_process(true)
	
	
	# TODO custom draw unit path given path
	#var path := [Vector2(0, 0), Vector2(3, 0), Vector2(3, 4), Vector2(0, 4), Vector2(0, 0)]
	# change draw() name, godot intellisense craps out
	# having to call initialize() is dum
	$UnitPath.initialize(Util.flood_fill($Entities/Unit.cell(), 999, get_world_bounds()))
	$UnitPath.draw(Vector2.ZERO, Vector2(11, 2))
	$Entities/UnitDriver.start_driver($UnitPath.current_path)
	
	


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
	
	
## Returns the spawn points of given spawn type.
func get_spawn_points(spawn_type: String) -> Array[SpawnPoint]:
	var arr: Array[SpawnPoint] = []
	for obj in get_tree().get_nodes_in_group("MapObjects"):
		if obj is SpawnPoint:
			if obj.spawn_type == spawn_type:
				arr.append(obj)
	return arr
			

## Returns the playable rect area.
func get_playable_bounds() -> Rect2:
	return Rect2(-PLAYABLE_BOUNDS, -PLAYABLE_BOUNDS, world.map_size.x + PLAYABLE_BOUNDS*2, world.map_size.y + PLAYABLE_BOUNDS*2)
	

## Returns the world bounds where units can be placed.
func get_world_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, world.map_size)
	
	
func _queue_update():
	if world_update_frequency >= 0:
		_world_update_cooldown = world_update_frequency
		update_configuration_warnings() # 'Updating' message
		set_process(true)
	else:
		_update()
		

func _update():
	map_changed.emit()
	get_tree().call_group("MapObjects", "_update")
	

func _add_object(obj: MapObject):
	obj.add_to_group("MapObjects")
	obj._enter_map(self, world)


func _remove_object(obj: MapObject):
	obj._exit_map()
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
	
	
	
