@tool
class_name NewDoodad
extends MapObject


## The model (texture) to use.
@export var texture: Texture2D:
	set(value):
		if texture == value:
			return
		texture = value
		if is_node_ready():
			_update_doodad()

## Lock sprite to world transform.
@export var lock_to_world: bool = true:
	set(value):
		if lock_to_world == value:
			return
		lock_to_world = value
		if is_node_ready():
			_update_doodad()
			
## Used to adjust the visual center of the doodad.
@export var offset: Vector2:
	set(value):
		if offset == value:
			return
		offset = value
		if is_node_ready():
			_update_doodad()

## Offset is in uniform coordinates.
@export var uniform_offset: bool:
	set(value):
		if uniform_offset == value:
			return
		uniform_offset = value
		if is_node_ready():
			_update_doodad()
		
		
		
var _last_sprite_pos: Vector2


func _ready():
	super._ready()
	_update_doodad()
	

func _update_doodad():
	$Sprite2D.texture = texture
	
	var offs := (world.as_global(map_pos + offset) - position) if uniform_offset else offset
	
	if lock_to_world and world:
		var origin := -world.as_global(Vector2.ZERO)
		var parent_offset := -(world.as_global(Vector2.ZERO) - position)
		$Sprite2D.centered = false
		$Sprite2D.position = origin - parent_offset + offs
		$Sprite2D.scale = world.get_internal_scale()
	else:
		$Sprite2D.centered = true
		$Sprite2D.position = offs
		$Sprite2D.scale = Vector2.ONE
	
		
func _on_map_pos_changed():
	_update_doodad()
	pass
