@tool
class_name Map
extends Node2D


signal map_changed


## A special out of bounds position.
const OUT_OF_BOUNDS := Vector2(69, 420)

## Extra size around the map world that isn't playable but still interactible.
const PLAYABLE_BOUNDS := 5

## Pathing group ordered by increasing strictness.
enum Pathing {
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

# World changes are quite expensive so we only refresh on a fixed time.
@export var world_update_frequency: float = 0.5


# The world is initialized in a different way, earlier than other variables.
var world: World

var _world_update_cooldown: float = 0
var _errors: PackedStringArray = []

@onready var unit_path := $UnitPath
@onready var pathing_overlay := $PathingOverlay
@onready var attack_overlay := $AttackOverlay
@onready var target_overlay := $TargetOverlay
@onready var drivers := $Drivers

#region Node
func _ready():
	update_configuration_warnings()
	_snap_all_objects()
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
	
	
## Returns the spawn points of given spawn type.
func get_spawn_points(spawn_type: String) -> Array[SpawnPoint]:
	var z: Array[SpawnPoint] = []
	z.assign(_get_objects().filter(func (x): return x is SpawnPoint and x.spawn_type == spawn_type))
	return z


## Returns all the units owned by empire or all units if empire == null.
func get_units(empire: Empire = null) -> Array[Unit]:
	var z: Array[Unit] = []
	z.assign(_get_objects().filter(func (x): return _is_selectable_unit(x) and (empire == null or x.empire == empire)))
	return z


## Returns the unit in cell.
func get_unit(_cell: Vector2, empire: Empire = null) -> Unit:
	for obj in _get_objects():
		if _is_selectable_unit(obj) and obj.cell() == _cell and (empire == null or obj.empire == empire):
			return obj as Unit
	return null


func _is_selectable_unit(obj: MapObject) -> bool:
	return obj is Unit and obj.alive


## Returns all the objects.
func get_objects() -> Array[MapObject]:
	# yes, this is horrible
	var z: Array[MapObject] = []
	z.assign(_get_objects())
	return z
	
	
func _get_objects() -> Array[Node]:
	return get_tree().get_nodes_in_group("MapObjects")
	
	
## Returns all the objects at cell.
func get_objects_at(_cell: Vector2) -> Array[MapObject]:
	return get_objects().filter(func (x): return x.cell() == _cell)


## Returns the playable rect area.
func get_playable_bounds() -> Rect2:
	return Rect2(-PLAYABLE_BOUNDS, -PLAYABLE_BOUNDS, world.map_size.x + PLAYABLE_BOUNDS*2, world.map_size.y + PLAYABLE_BOUNDS*2)
	

## Returns the world bounds where units can be placed.
func get_world_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, world.map_size)
	

## Returns true if the point is within world bounds.
func is_inside_bounds(v: Vector2) -> bool:
	return get_world_bounds().has_point(v)
	

## Returns the cell of a point.
func to_cell(p: Vector2) -> Vector2:
	return Vector2(int(round(p.x)), int(round(p.y)))


func cell(p: Vector2) -> Vector2:
	return Vector2(int(round(p.x)), int(round(p.y)))
	
	
func _snap_all_objects():
	for obj in _get_objects():
		obj.map_pos = obj.cell()
		
	
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
	
	
	
