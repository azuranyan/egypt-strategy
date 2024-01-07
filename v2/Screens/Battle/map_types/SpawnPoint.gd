@tool
class_name SpawnPoint
extends MapObject


@export_enum("Player", "Enemy") var spawn_type: String:
	set(value):
		spawn_type = value
		if spawn_type == "Player":
			debug_tile_color = Color(0.1, 0.1, 0.8, 0.4)
		else:
			debug_tile_color = Color(0.8, 0.1, 0.1, 0.4)
			
@export var spawn_list: PackedStringArray
