@tool
extends MapObject

## A MapObject for objects exported together with the world image asset.
class_name Doodad


## The type of doodad to use.
@export var doodad_type: DoodadType
		
## Uses source_pos as map_pos on ready.
@export var use_source_pos := true


var sprite: Sprite2D


func _ready():
	sprite = Sprite2D.new()
	#sprite.z_index = 1
	add_child(sprite)
	
	
func map_init():
	sprite.texture = doodad_type.texture
	sprite.scale = world.get_viewport_scale()
	sprite.position = world.get_viewport_offset() - world.uniform_to_screen(doodad_type.source_pos)
	
	if use_source_pos:
		map_pos = doodad_type.source_pos

	# connect properties
	
	# refresh properties
