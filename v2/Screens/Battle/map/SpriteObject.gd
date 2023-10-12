@tool
extends MapObject

## A simple MapObject using a sprite.
class_name SpriteObject


signal texture_changed()
signal fit_to_grid_changed()


## The texture of the sprite.
@export var texture: Texture2D:
	set(value):
		texture = value
		texture_changed.emit()

## Fit the sprite in the grid.
@export var fit_to_grid: bool = false:
	set(value):
		fit_to_grid = value
		fit_to_grid_changed.emit()


@onready var sprite: Sprite2D = $Sprite2D


func _ready():
	texture_changed.connect(_update_texture)
	fit_to_grid_changed.connect(_update_fit_to_grid)

	texture = texture
	fit_to_grid = fit_to_grid


func _update_texture():
	sprite.texture = texture
	
	
func _update_fit_to_grid():
	_refresh()

		
func _refresh():
	var m = Transform2D()
	
	if fit_to_grid:
		if world:
			# scale to downsize to unit vector
			m = m.scaled(Vector2(1/texture.get_size().x, 1/texture.get_size().y))

			# scale to tile size
			m = m.scaled(Vector2(world.tile_size, world.tile_size))
			
			# transform to screen
			m = world._world_to_screen_transform * m
		sprite.transform = m
	else:
		sprite.transform = m
		if world:
			sprite.scale = world.get_viewport_scale()
		else:
			sprite.scale = Vector2.ONE
		
	sprite.position = Vector2()
	

func _on_world_changed():
	if not is_node_ready():
		await self.ready
	_refresh()
		
