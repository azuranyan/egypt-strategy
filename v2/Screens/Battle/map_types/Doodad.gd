@tool
extends MapObject

## The model (texture) to use.
@export var texture: Texture2D:
	set(value):
		texture = value
		if not is_node_ready():
			await ready
		_update()

## Used to adjust the visual center of the doodad.
@export var offset: Vector2:
	set(value):
		offset = value
		if not is_node_ready():
			await ready
		_update()

## Lock map pos to equal offset. Useful for repositioning objects.
@export var lock_map_pos: bool = true:
	set(value):
		lock_map_pos = value
		if not is_node_ready():
			await ready
		_update()
	
	
func _on_world_changed():
	_update()


func _on_map_pos_changed():
	_update()


func _update():
	$Sprite2D.texture = texture
	
	if map:
		
		$Sprite2D.position = world.get_viewport_offset() - map.to_global(offset)
		$Sprite2D.scale = world.get_viewport_scale()
	else:
		$Sprite2D.position = Vector2.ZERO
		$Sprite2D.scale = Vector2.ONE
		
	if lock_map_pos:
		if map_pos != offset:
			map_pos = offset
	
