@tool
extends Node2D


signal doodad_type_changed


## The type of doodad to use.
@export var doodad_type: DoodadType:
	set(value):
		doodad_type = value
		doodad_type_changed.emit()

## Uses source_pos as map_pos on ready.
@export var use_source_pos := true


@onready var sprite := $Sprite2D as Sprite2D 

@onready var mapobject := $MapObject


func _on_doodad_type_changed():
	if doodad_type:
		sprite.texture = doodad_type.texture
		sprite.scale = mapobject.world.get_viewport_scale()
		sprite.position = mapobject.world.get_viewport_offset() - mapobject.world.uniform_to_screen(doodad_type.source_pos)
		
		if use_source_pos:
			mapobject.map_pos = doodad_type.source_pos
	else:
		sprite.texture = null
		sprite.scale = Vector2.ONE
		sprite.position = Vector2.ZERO
		
		if use_source_pos:
			mapobject.map_pos = Vector2.ZERO
		
