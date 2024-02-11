@tool
class_name UnitModel
extends Node2D


signal animation_finished(state: Unit.State)
signal interacted(cursor_pos: Vector2, button_index: int, pressed: bool)


const ANIMATION_NAMES := {
	Unit.State.INVALID: 'invalid',
	Unit.State.IDLE: 'idle',
	Unit.State.WALKING: 'walk_loop',
	Unit.State.ATTACKING: 'attack',
	Unit.State.HURT: 'hurt',
	Unit.State.DYING: 'dying',
	Unit.State.DEAD: 'dead',
}


@export var state := Unit.State.INVALID:
	set(value):
		state = value
		if not is_node_ready():
			await ready
		update_animation()
		

@export var heading: Map.Heading:
	set(value):
		heading = value
		if not is_node_ready():
			await ready
		scale.x = -1 if heading == Map.Heading.NORTH or heading == Map.Heading.EAST else 1
		update_animation()
		
		
@onready var sprite = %Sprite
@onready var cursor_detector = %CursorDetector


var _mouse_button_mask := 0


func _ready():
	set_process_input(false)
	sprite.animation_finished.connect(_emit_animation_finished)


func _emit_animation_finished():
	animation_finished.emit(state)


func update_animation():
	if heading == Map.Heading.NORTH or heading == Map.Heading.WEST:
		sprite.play('back_' + ANIMATION_NAMES[state])
	else:
		sprite.play('front_' + ANIMATION_NAMES[state])
	

func _on_cursor_detector_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		_mouse_button_mask |= event.button_mask
		set_process_input(true)
		interacted.emit(event.position, event.button_index, true)
		

func _input(event):
	if event is InputEventMouseButton and not event.pressed:
		var mask: int = (1 << (event.button_index - 1))
		if _mouse_button_mask & mask != 0:
			_mouse_button_mask &= ~mask
			set_process_input(_mouse_button_mask != 0)
			interacted.emit(event.position, event.button_index, false)
			
