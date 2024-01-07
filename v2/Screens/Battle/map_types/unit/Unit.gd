@tool
class_name NewUnit
extends MapObject


const HEADING_ANGLES := [0, PI/2, PI, PI*3/4]


signal walking_started(start: Vector2, end: Vector2)
signal walking_finished(start: Vector2, end: Vector2)


@export_subgroup("Unit State")

## The angle the unit is facing in radians.
@export var facing: float:
	set(value):
		if facing == value:
			return
		facing = value
		if is_node_ready():
			model.facing = facing


@export_subgroup("Unit Stats")

@export var walk_speed: float = 200

			
			
@export_subgroup("Model Settings")

## The sprite frames of the model.
@export var sprite_frames: SpriteFrames:
	set(value):
		if sprite_frames == value:
			return
		sprite_frames = value
		if is_node_ready():
			model.sprite_frames = sprite_frames
	

## The scale of the model.
@export var model_scale := Vector2.ONE:
	set(value):
		if model_scale == value:
			return
		model_scale = value
		if is_node_ready():
			model.scale = model_scale


@onready var model: NewUnitModel = $UnitModel
		
			
func _ready():
	super._ready()
	
	model.facing = facing
	model.sprite_frames = sprite_frames
	model.scale = model_scale
	
	$UnitModel/Shadow.visible = false
		
		
func map_ready():
	# the world is iso-like rotated at 45 degrees so this should be correct.
	# if wonky things happen, then we'll just do the complete calculation
	model.position.y = world.tile_size * sqrt(2) * world.y_ratio / 2
	$UnitModel/Shadow.scale = world.world_transform.get_scale() * Vector2(1, world.y_ratio) * 0.5
	$UnitModel/Shadow.visible = true


func get_heading() -> Unit.Heading:
	return model.heading
	
	
func set_heading(heading: Unit.Heading):
	facing = HEADING_ANGLES[heading]
	
	
func play_animation(anim: String, loop: bool):
	model.play_animation(anim, loop)
	
	
func stop_animation():
	model.play_animation('idle', true)
