@tool
extends MapObject


## The model (texture) to use.
@export var texture: Texture2D:
	set(value):
		texture = value
		if not is_node_ready():
			await ready
		%Sprite2D.texture = texture
		%Sprite2D.centered = false
		_update_position()


func _update_position():
	super._update_position()
	if world:
		%Sprite2D.position = -position
		%Sprite2D.scale = world.get_internal_scale()
	else:
		%Sprite2D.global_position = Vector2.ZERO
		%Sprite2D.scale = Vector2.ONE

