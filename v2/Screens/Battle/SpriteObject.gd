@tool
extends MapObject

## A simple MapObject using a sprite.
class_name SpriteObject


signal texture_changed()
signal fit_to_grid_changed()


@export var texture: Texture2D:
	set(value):
		texture = value
		texture_changed.emit()

@export var fit_to_grid: bool = false:
	set(value):
		fit_to_grid = value
		fit_to_grid_changed.emit()


var sprite: Sprite2D


func _ready():
	sprite = Sprite2D.new()
	#sprite.z_index = 1
	add_child(sprite)


func map_init():
	# connect properties
	texture_changed.connect(_update_texture)
	fit_to_grid_changed.connect(_update_fit_to_grid)
	
	# refresh properties
	texture = texture
	fit_to_grid = fit_to_grid


func _update_texture():
	sprite.texture = texture
	
	
func _update_fit_to_grid():
	var m = Transform2D()
	
	if fit_to_grid:
		# scale to downsize to unit vector
		m = m.scaled(Vector2(1/texture.get_size().x, 1/texture.get_size().y))

		# scale to tile size
		m = m.scaled(Vector2(world.tile_size, world.tile_size))

		sprite.transform = world._world_to_screen_transform * m
	else:
		sprite.transform = m
		sprite.scale = world.get_viewport_scale()
		
	sprite.position = Vector2()
