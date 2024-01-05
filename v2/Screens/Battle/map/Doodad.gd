@tool
extends MapObject

class_name Doodad

signal doodad_type_changed


## The type of doodad to use.
@export var doodad_type: DoodadType:
	set(value):
		doodad_type = value
		doodad_type_changed.emit()

## Whether to use the source position as map position on load.
@export var use_source_pos: bool = true


@onready var sprite := $Sprite2D as Sprite2D 


func _refresh():
	if not is_node_ready():
		await self.ready
	var world
	if doodad_type:
		sprite.texture = doodad_type.texture
		
		if world:
			sprite.position = world.get_viewport_offset() - world.uniform_to_screen(doodad_type.source_pos)
		else:
			sprite.position = Vector2.ZERO
			
		sprite.scale = world.get_viewport_scale()
		if use_source_pos:
			map_pos = doodad_type.source_pos
	else:
		sprite.texture = null
		sprite.scale = Vector2.ONE
		sprite.position = Vector2.ZERO


func _on_doodad_type_changed():
	_refresh()


func _on_world_changed():
	_refresh()
