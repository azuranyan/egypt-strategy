@tool
class_name NewMap extends Node2D


signal map_changed

## A special out of bounds position.
const OUT_OF_BOUNDS := Vector2(69, 420)


@export var world: World

# World changes are quite expensive so we only refresh on a fixed time.
@export var world_update_frequency: float = 0.5


var _world_update_cooldown: float = 0
var _errors: PackedStringArray = []

#region Node
func _ready():
	world.world_changed.connect(_queue_update)
	
	# will force a tick of update after _ready
	set_process(true)

	
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
	

func _on_object_container_object_added(obj: MapObject):
	obj.map = self
	obj.world = world
	obj.add_to_group("MapObjects")


func _on_object_container_object_removed(obj: MapObject):
	obj.map = null
	obj.world = null
	obj.remove_from_group("MapObjects")
