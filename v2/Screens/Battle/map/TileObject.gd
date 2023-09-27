@tool
extends MapObject

## A simple MapObject with a solid color.
class_name TileObject


signal color_changed()


@export var color: Color:
	set(value):
		color = value
		color_changed.emit()

# polygon2d because colorrect is a fucking retard when created from code.
# yes, i have set the size. no, it doesn't show up unless you set top level.
var rect: Polygon2D


func _ready():
	rect = Polygon2D.new()
	rect.z_index = -1 # set z as -1 so it draws under default z index objects
	
	add_child(rect)
	

func map_init():
	# force debug tile to not show
	tile.visible = false
	
	var p := PackedVector2Array()
	p.resize(4)
	p.fill(Vector2.ZERO)
	
	# recalculate position of tile
	var pos := world.uniform_to_world(map_pos)
	p[0] = world.world_to_screen(Vector2(-0.5, -0.5) * world.tile_size + pos) - position
	p[1] = world.world_to_screen(Vector2(+0.5, -0.5) * world.tile_size + pos) - position
	p[2] = world.world_to_screen(Vector2(+0.5, +0.5) * world.tile_size + pos) - position
	p[3] = world.world_to_screen(Vector2(-0.5, +0.5) * world.tile_size + pos) - position

	rect.polygon = p
	
	# connect properties
	color_changed.connect(_update_color)
	
	# refresh properties
	color = color
	

func _update_color():
	rect.color = color
	
