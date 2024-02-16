@tool
extends MapObject


## The model (texture) to use.
@export var texture: Texture2D:
	set(value):
		texture = value
		_update_doodad()

## Lock sprite to world transform.
@export var lock_to_world: bool = true:
	set(value):
		lock_to_world = value
		_update_doodad()
			
## Used to adjust the visual center of the doodad.
@export var offset: Vector2:
	set(value):
		offset = value
		_update_doodad()

## Offset is in uniform coordinates.
@export var uniform_offset: bool:
	set(value):
		uniform_offset = value
		_update_doodad()
		


func _update_doodad():
	if not is_node_ready():
		await ready

	%Sprite2D.texture = texture
	
	# var offs := (world.as_global(map_pos + offset) - position) if uniform_offset else offset
	
	# if lock_to_world and world:
	# 	var origin := -world.as_global(Vector2.ZERO)
	# 	var parent_offset := -(world.as_global(Vector2.ZERO) - position)
	# 	$Sprite2D.centered = false
	# 	$Sprite2D.position = origin - parent_offset + offs
	# 	$Sprite2D.scale = world.get_internal_scale()
	# else:
	# 	$Sprite2D.centered = true
	# 	$Sprite2D.position = offs
	# 	$Sprite2D.scale = Vector2.ONE
	


func _update_position():
	super._update_position()
	pass # TODO