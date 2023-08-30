@tool
extends Node2D
class_name BattleMap

# The doodads and the map are all already centered and placed

@export_category("BattleMap")

@export_subgroup("Map Info")
## The size of the image source.
@export var internal_world_size: Vector2i:
	set(value):
		internal_world_size = value
		recalculate_world_transform()
	get:
		return internal_world_size

## The size of the map.
@export var map_size: Vector2i:
	set(value):
		map_size = value
		recalculate_uniform_world_transform()
	get:
		return map_size

## The off-center offset of the level (in world size units).
@export var offset: Vector2:
	set(value):
		offset = value
		recalculate_world_transform()
	get:
		return offset

## Tile size deduced from source (in world size units).
@export var tile_size: int:
	set(value):
		tile_size = value
		recalculate_uniform_world_transform()
	get:
		return tile_size

## Ratio of tile height to its width.
@export var y_ratio: float:
	set(value):
		y_ratio = value
		recalculate_world_transform()
	get:
		return y_ratio


## Transformation matrix for world to screen.
var world_to_screen_transform: Transform2D

## Transformation matrix for screen to world.
var screen_to_world_transform: Transform2D

var uniform_world_transform: Transform2D

var uniform_world_transform_inverse: Transform2D

class BattleMapObject:
	pass
	
class BattleMapEntity extends BattleMapObject:
	pass


func _ready():
	recalculate_world_transform()
	recalculate_uniform_world_transform()
	
func _process(delta):
	recalculate_tile()


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
	

	
func recalculate_tile():
	var m = Transform2D()
	
	m = m.scaled(Vector2(tile_size, tile_size))
	
	m = world_to_screen_transform * m
	
	$Tile.transform = m

func recalculate_world_transform():
	var vp = Vector2(1920, 1080) # viewport size
	
	# some default values for calculation: they will be used in scale
	# so we have to make sure they aren't zero so we don't get det==0
	var ws = vp if internal_world_size.x == 0 or internal_world_size.y == 0 else internal_world_size
	var yr = 1.0 if y_ratio == 0 else y_ratio
	
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

func recalculate_uniform_world_transform():
	var m = Transform2D()
	
	# more det==0 safeguards
	var scaling = 1.0 if tile_size == 0 else tile_size
	
	m = m.translated(Vector2(0.5 - map_size.x/2, 0.5 - map_size.y/2))
	m = m.scaled(Vector2(scaling, scaling))
	m = m.rotated(deg_to_rad(-90))
	
	uniform_world_transform = m
	uniform_world_transform_inverse = m.affine_inverse()
	
