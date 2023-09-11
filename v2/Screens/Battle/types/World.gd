@tool
extends Resource

## Class depicting a world.
class_name World


## The image source.
@export var texture: Texture2D

## The size of the map.
@export var map_size: Vector2i

## Tile size deduced from source (in world size units).
@export var tile_size: int
		
## The off-center offset of the level (in world size units).
@export var offset: Vector2

## Ratio of tile height to its width.
@export var y_ratio: float


## Transform matrix for world to screen.
var _world_to_screen_transform: Transform2D

## Transform matrix for screen to world.
var _screen_to_world_transform: Transform2D

## Transform matrix for uniform world space.
var _uniform_world_transform: Transform2D

## Inverse of uniform world space transform matrix.
var _uniform_world_transform_inverse: Transform2D

## This is an engine hack. Do not touch.
@export var _post_init_hook_hack: int:
	set(value):
		# 1. init will be called before the values are loaded in from file
		# 2. there are no hooks for post init after file is loaded
		# 3. export vars are loaded in order, so this setter will be called
		# after everything else has been loaded.
		recalculate_world_transforms()
		recalculate_uniform_transforms()


## Returns the internal size.
func get_internal_size() -> Vector2:
	return texture.get_size()


## Recalculates world transforms.
func recalculate_world_transforms():
	var vp = Vector2(1920, 1080) # viewport size
	
	var internal_size := get_internal_size()
	
	# some default values for calculation: they will be used in scale
	# so we have to make sure they aren't zero so we don't get det==0
	var ws = internal_size if internal_size.x != 0 and internal_size.y != 0 else vp
	var yr = y_ratio if y_ratio != 0 else 1.0
	
	var m = Transform2D()
	
	
	# apply world skew and weirdge offset
	m = m.rotated(deg_to_rad(45))
	m = m.translated(offset)
	
	# apply viewport scaling. screen coordinates is y=down so we reverse it.
	var final_scaling := Vector2()
	final_scaling.x = vp.x/ws.x
	final_scaling.y = vp.y/ws.y * yr
	m = m.scaled(final_scaling)
	
	# apply viewport translation for 0, 0
	m = m.translated(vp/2)
	
	_world_to_screen_transform = m
	_screen_to_world_transform = m.affine_inverse()
	

## Recalculates uniform transforms.
func recalculate_uniform_transforms():
	var m = Transform2D()
	
	# more det==0 safeguards
	var scaling = 1.0 if tile_size == 0 else tile_size
	
	# reverse y direction
	m = m.translated(Vector2(0.5 - map_size.x/2, 0.5 - map_size.y/2))
	m = m.scaled(Vector2(scaling, -scaling))
	#m = m.rotated(deg_to_rad(-90))
	
	_uniform_world_transform = m
	_uniform_world_transform_inverse = m.affine_inverse()
	
	
## Transforms a vector in screen space to world space.
##
## This is mainly used for positioning assets using the screen as reference
## point (e.g. mouse pos).
func screen_to_world(v: Vector2) -> Vector2:
	return _screen_to_world_transform * v
	
	
## Transforms a vector in world space to screen space.
##
## World space is the internal world space represented by the source image.
##
## This is mainly used for positioning assets directly into the map.
func world_to_screen(v: Vector2) -> Vector2:
	return _world_to_screen_transform * v


## Transforms a vector in uniform world space to screen space.
##
## Uniform world space is the space where (0, 0) is the center of the
## leftmost corner tile and 1 tile is 1 unit distance.
##
## This should be the function to use for positioning stuff around.
func uniform_to_screen(v: Vector2) -> Vector2:
	return world_to_screen(_uniform_world_transform * v)
	
	
## Transforms a vector in screen space to uniform world space.
func screen_to_uniform(v: Vector2, snap: bool=false) -> Vector2:
	var re := _uniform_world_transform_inverse * screen_to_world(v)
	if snap:
		re.x = roundf(re.x)
		re.y = roundf(re.y)
	return re
	

## Transforms a vector in uniform world space to world space.
func uniform_to_world(v: Vector2) -> Vector2:
	return _uniform_world_transform * v
	

## Transforms a vector in world space to uniform world space.
func world_to_uniform(v: Vector2) -> Vector2:
	return _uniform_world_transform_inverse * v


## Returns the viewport scale.
func get_viewport_scale() -> Vector2:
	#return Vector2(BattleAPI.get_viewport_size())/Vector2(internal_size)
	return Vector2(1920, 1080)/Vector2(get_internal_size())
	

## Returns the viewport offset.
func get_viewport_offset() -> Vector2:
	#return BattleAPI.get_viewport_size()/2
	return Vector2(1920, 1080)/2

