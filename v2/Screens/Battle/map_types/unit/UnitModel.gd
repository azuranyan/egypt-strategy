@tool
class_name UnitModel
extends Node2D


@export var sprite_frames: SpriteFrames:
	set(value):
		if sprite_frames == value:
			return
		sprite_frames = value
		if is_node_ready():
			update_configuration_warnings()
			_update_animation()


@export_enum("idle", "attack", "special", "walk", "hurt", "victory") var animation := "idle":
	set(value):
		if animation == value:
			return
		animation = value
		if is_node_ready():
			_update_animation()
			

@export var loop: bool:
	set(value):
		if loop == value:
			return
		loop = value
		if is_node_ready():
			_update_animation()
	
			
@export var facing: float = 0:
	set(value):
		if facing == value:
			return
		facing = value
		if is_node_ready():
			_update_heading()
		
		
@export var heading: Unit.Heading:
	set(value):
		if heading == value:
			return
		heading = value
		if is_node_ready():
			_update_facing()
		
			
			
@onready var sprite := $Sprite as AnimatedSprite2D


static func animation_name(animation: String, loop: bool, heading: Unit.Heading) -> String:
	# walk_loop -> FrontWalk_loop
	var anim := animation.to_pascal_case()
	if loop:
		anim = anim + "_loop"
		
	if heading == Unit.Heading.North or heading == Unit.Heading.West:
		return "Back" + anim
	else:
		return "Front" + anim
		
		
func _ready():
	_update_heading()
	_update_animation()


func _exit_tree():
	request_ready()
	

func _get_configuration_warnings() -> PackedStringArray:
	if sprite_frames == null:
		return ["sprite_frames is not set"]
	return []


## Returns the wrangled animation name.
func get_animation_name() -> String:
	return animation_name(animation, loop, heading)
	
	
## Change animation.
func play_animation(animation: String, loop: bool):
	self.animation = animation
	self.loop = loop
	sprite.play()


## Refreshes the animation for state changes.
func refresh_animation():
	sprite.play()


## Stop animation.
func stop_animation():
	sprite.stop()
	
	
func _calculate_heading() -> Unit.Heading:
	# don't ask me why, don't ask me to simplify
	# my head is mush but this is correct
	var angle := fmod(facing + PI*2 + PI/4, PI*2)
	return (angle/PI*2) as int as Unit.Heading
	
	
func _update_heading():
	heading = _calculate_heading()
	_update_animation()
	

func _update_facing():
	if _calculate_heading() != heading:
		facing = heading * (PI/2)
	

func _update_animation():
	sprite.sprite_frames = sprite_frames
	
	# TODO check if animation has L/R otherwise, flip
	sprite.flip_h = heading == Unit.Heading.North or heading == Unit.Heading.East
	
	var anim := get_animation_name()
	
	# try to load animation, defaulting to idle loop if nonexistent
	if sprite.sprite_frames.has_animation(anim):
		sprite.animation = anim
	else:
		sprite.animation = animation_name("idle", loop, heading)
		# if animation has no idle, we won't show anything
	
	# for editor convenience, autoplay on changes
	if Engine.is_editor_hint():
		refresh_animation()
	
