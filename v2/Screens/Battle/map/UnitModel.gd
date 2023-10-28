@tool
extends Node2D

class_name UnitModel


signal sprite_frames_changed
signal facing_changed


@export var sprite_frames: SpriteFrames:
	set(value):
		sprite_frames = value
		sprite_frames_changed.emit()
		

var facing: float = 0:
	set(value):
		facing = value
		facing_changed.emit()
		
		
var animation := "idle":
	set = play_animation
	
	
var _heading: Unit.Heading

		

@onready var sprite := $Sprite as AnimatedSprite2D


## Sets the general direction this unit is facing.
func set_heading(value: Unit.Heading):
	facing = value * PI/2
	
	
## Returns the general direction this unit is facing.
func get_heading() -> Unit.Heading:
	return _heading
		
		
## Refreshes the animation for state changes.
func refresh_animation():
	play_animation(animation)


## Change animation.
func play_animation(_animation: String):
	sprite.flip_h = _heading == Unit.Heading.North or _heading == Unit.Heading.East
	
	var anim := ""
	match _animation:
		"walk":
			anim = "Walk"
		"attack":
			anim = "Attack"
		"death":
			anim = 'Death'
		_:
			anim = "Idle"
			
	if _animation.ends_with('_loop') or _animation == 'walk':
		anim = anim + '_loop'
	print('play anim MODEL ', anim)
			
	if _heading == Unit.Heading.North or _heading == Unit.Heading.West:
		sprite.play("Back" + anim)
	else:
		sprite.play("Front" + anim)
	
	animation = _animation


## Stop animation.
func stop_animation():
	sprite.stop()


func _calculate_heading() -> Unit.Heading:
	var angle := fmod(facing + PI*2 + PI/4, PI*2)
	return (angle/PI*2) as int as Unit.Heading
		

func _on_sprite_frames_changed():
	sprite.sprite_frames = sprite_frames


func _on_facing_changed():
	var old_heading := _heading
	_heading = _calculate_heading()
	
	if _heading != old_heading:
		refresh_animation()
	
