@tool
extends MapObject

## A simple MapObject with a solid color.
class_name TileObject


signal color_changed()


## Tile color.
@export var color: Color = Color.WHITE:
	set(value):
		color = value
		color_changed.emit()


@onready var rect: Polygon2D = $Polygon2D


func _refresh_tile():
	var p := PackedVector2Array()
	p.resize(4)
	p.fill(Vector2.ZERO)
	var world
	
	if world:
		pass
		# recalculate position of tile
		#var pos := world.uniform_to_world(map_pos)
		#p[0] = world.world_to_screen(Vector2(-0.5, -0.5) * world.tile_size + pos) - position
		#p[1] = world.world_to_screen(Vector2(+0.5, -0.5) * world.tile_size + pos) - position
		#p[2] = world.world_to_screen(Vector2(+0.5, +0.5) * world.tile_size + pos) - position
		#p[3] = world.world_to_screen(Vector2(-0.5, +0.5) * world.tile_size + pos) - position
	
	rect.polygon = p
	

func _on_color_changed():
	if not is_node_ready():
		await self.ready
	rect.color = color


func _on_world_changed():
	if not is_node_ready():
		await self.ready
	_refresh_tile()
	
