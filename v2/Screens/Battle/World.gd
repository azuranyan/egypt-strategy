@tool
extends Node2D
class_name World

@export_category("World")

@export_subgroup("Map")

## The image source.
@export var texture: Texture2D:
	set(value):
		texture = value
		update_texture()
	get:
		return texture

## The size of the map.
@export var map_size: Vector2i:
	set(value):
		map_size = value
		grid.size = value
		grid.queue_redraw()
		recalculate_uniform_world_transform()
	get:
		return map_size

## The off-center offset of the level (in world size units).
@export var offset: Vector2:
	set(value):
		offset = value
		grid.queue_redraw()
		recalculate_world_transform()
	get:
		return offset

## Tile size deduced from source (in world size units).
@export var tile_size: int:
	set(value):
		tile_size = value
		grid.queue_redraw()
		recalculate_uniform_world_transform()
	get:
		return tile_size

## Ratio of tile height to its width.
@export var y_ratio: float:
	set(value):
		y_ratio = value
		grid.queue_redraw()
		recalculate_world_transform()
	get:
		return y_ratio
		
## Transform matrix for world to screen.
var world_to_screen_transform: Transform2D

## Transform matrix for screen to world.
var screen_to_world_transform: Transform2D

## Transform matrix for uniform world space.
var uniform_world_transform: Transform2D

## Inverse of uniform world space transform matrix.
var uniform_world_transform_inverse: Transform2D

## The internal sprite.
var sprite: Sprite2D = Sprite2D.new()

## The procedural grid.
var grid: Grid = Grid.new(self)

## The size of the image source.
var internal_size: Vector2i:
	set(value):
		internal_size = value
		grid.queue_redraw()
		recalculate_world_transform()
	get:
		return internal_size

class Grid extends Node2D:
	var world: World
	
	var size: Vector2i:
		set(value):
			size = value
			queue_redraw()
		get:
			return size
	
	func _init(world: World):
		self.world = world
	
	func _draw():
		var half := Vector2(0.5, 0.5)
		
		for i in size.x + 1:
			var p1 := world.uniform_to_screen(Vector2(i, 0) - half)
			var p2 := world.uniform_to_screen(Vector2(i, size.y)- half)
			draw_line(p1, p2, Color(Color.BLACK, 0.3), 1, true)
			
		for i in size.y + 1:
			var p1 := world.uniform_to_screen(Vector2(0, i) - half)
			var p2 := world.uniform_to_screen(Vector2(size.x, i) - half)
			draw_line(p1, p2, Color(Color.BLACK, 0.3), 1, true)


func _enter_tree():
	sprite.texture = texture
	
	add_child(sprite)
	add_child(grid)


## Updates the texture and world parameters.
func update_texture():
	sprite.texture = texture
		
	internal_size = texture.get_size()
	
	sprite.scale = Vector2(Battle.get_viewport_size())/Vector2(internal_size)
	sprite.position = Battle.get_viewport_size()/2
	

## Recalculates the world transform
func recalculate_world_transform():
	var vp = Vector2(1920, 1080) # viewport size
	
	# some default values for calculation: they will be used in scale
	# so we have to make sure they aren't zero so we don't get det==0
	var ws = internal_size if internal_size.x != 0 and internal_size.y != 0 else vp
	var yr = y_ratio if y_ratio != 0 else 1.0
	
	var m = Transform2D()
	
	# apply world skew and weirdge offset
	m = m.rotated(deg_to_rad(45))
	m = m.translated(offset)
	
	# apply viewport scaling
	var final_scaling := Vector2()
	final_scaling.x = vp.x/ws.x
	final_scaling.y = vp.y/ws.y * yr
	m = m.scaled(final_scaling)
	
	# apply viewport translation for 0, 0
	m = m.translated(vp/2)
	
	world_to_screen_transform = m
	screen_to_world_transform = m.affine_inverse()


## Recalculates the uniform transform.
func recalculate_uniform_world_transform():
	var m = Transform2D()
	
	# more det==0 safeguards
	var scaling = 1.0 if tile_size == 0 else tile_size
	
	m = m.translated(Vector2(0.5 - map_size.x/2, 0.5 - map_size.y/2))
	m = m.scaled(Vector2(scaling, scaling))
	m = m.rotated(deg_to_rad(-90))
	
	uniform_world_transform = m
	uniform_world_transform_inverse = m.affine_inverse()
	

## Transforms the point in screen space to world space.
##
## This is mainly used for positioning assets using the screen as reference
## point (e.g. mouse pos).
func screen_to_world(pos: Vector2) -> Vector2:
	return screen_to_world_transform * pos
	
	
## Transforms the point in world space to screen space.
##
## World space is the internal world space represented by the source image.
##
## This is mainly used for positioning assets directly into the map.
func world_to_screen(pos: Vector2) -> Vector2:
	return world_to_screen_transform * pos


## Transforms the point in uniform world space to screen space.
##
## Uniform world space is the space where (0, 0) is the center of the
## leftmost corner tile and 1 tile is 1 unit distance.
##
## This should be the function to use for positioning stuff around.
func uniform_to_screen(pos: Vector2) -> Vector2:
	return world_to_screen(uniform_world_transform * pos)
	
	
## Transforms the point in screen space to uniform world space.
func screen_to_uniform(pos: Vector2, snap: bool=false) -> Vector2:
	var re := uniform_world_transform_inverse * screen_to_world(pos)
	if snap:
		re.x = roundf(re.x)
		re.y = roundf(re.y)
	return re

