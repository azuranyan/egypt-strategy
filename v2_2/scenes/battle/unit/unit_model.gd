@tool
class_name UnitModel
extends Node2D
## A simple class representing a unit model.


## Emitted when model is done animating. This will not be emitted for looping animations!
signal animation_finished(state: Unit.State)

## Emitted when the model is interacted to.
signal interacted(cursor_pos: Vector2, button_index: int, pressed: bool)


## The state of this model.
@export var state := Unit.State.IDLE:
	set(value):
		state = value
		if not is_node_ready():
			await ready
		update_animation()
		
## Which direction this unit is facing.
@export var heading: Map.Heading:
	set(value):
		heading = value
		if not is_node_ready():
			await ready
		scale.x = -1 if heading == Map.Heading.NORTH or heading == Map.Heading.EAST else 1
		update_animation()
		
		
## The sprite used for the model.
@onready var sprite: AnimatedSprite2D = %Sprite

## The [Area2D] used for mouse detections.
@onready var cursor_detector: Area2D = %CursorDetector


var _mouse_button_mask := 0


func _ready():
	set_process_input(false)
	sprite.animation_finished.connect(_emit_animation_finished)


func _emit_animation_finished():
	animation_finished.emit(state)


## Updates the animation to match the current state.
func update_animation():
	sprite.play(get_animation_name(state))
	
	
## Returns the animation name for a given state.
func get_animation_name(_state: Unit.State) -> StringName:
	const back_animation_names := {
		Unit.State.INVALID: &'back_invalid',
		Unit.State.IDLE: &'back_idle',
		Unit.State.WALKING: &'back_walk_loop',
		Unit.State.ATTACKING: &'back_attack',
		Unit.State.HURT: &'back_hurt',
		Unit.State.DYING: &'back_dying',
		Unit.State.DEAD: &'back_dead',
	}
	const front_animation_names := {
		Unit.State.INVALID: &'front_invalid',
		Unit.State.IDLE: &'front_idle',
		Unit.State.WALKING: &'front_walk_loop',
		Unit.State.ATTACKING: &'front_attack',
		Unit.State.HURT: &'front_hurt',
		Unit.State.DYING : &'front_dying',
		Unit.State.DEAD: &'front_dead',
	}
	if heading == Map.Heading.NORTH or heading == Map.Heading.WEST:
		return back_animation_names[_state]
	else:
		return front_animation_names[_state]


func _on_cursor_detector_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		_mouse_button_mask |= event.button_mask
		set_process_input(true)
		# TODO probably wrong, check position, this should be global
		interacted.emit(event.position, event.button_index, true)
		

func _input(event):
	if event is InputEventMouseButton and not event.pressed:
		var mask: int = (1 << (event.button_index - 1))
		if _mouse_button_mask & mask != 0:
			_mouse_button_mask &= ~mask
			set_process_input(_mouse_button_mask != 0)
			interacted.emit(event.position, event.button_index, false)
			
