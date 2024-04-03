@tool
class_name SpawnPoint
extends MapObject


@export_enum("Player", "Enemy") var spawn_type: String:
	set(value):
		spawn_type = value
		if is_node_ready():
			_update_debug_tile()
		
@export var spawn_list: PackedStringArray

@onready var debug_tile := $DebugTile


func _ready():
	_update_debug_tile()


func _exit_tree():
	request_ready()
	

func _update_debug_tile():
	debug_tile.hide()
	if not is_instance_valid(map):
		return
	if spawn_type == "Player":
		debug_tile.self_modulate = Color(0.1, 0.1, 0.8, 0.4)
	else:
		debug_tile.self_modulate = Color(0.8, 0.1, 0.1, 0.4)
	
	debug_tile.transform = map.world.world_transform
	debug_tile.position = map.world.as_aligned(cell()) - position  
	
	var p: PackedVector2Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for i in range(4):
		p[i] = p[i] * map.world.tile_size
	debug_tile.polygon = p
	debug_tile.show()
