@tool
class_name BalloonTail
extends Control
## The tail is a special control that expands with the balloon and draws under the dialog panel.


## The direction the tail is facing. By default the image should be facing left.
@export_enum("Left", "Right") var tail_facing:
	set(value):
		tail_facing = value
		if not is_node_ready():
			await ready
		_texture_rect.flip_h = tail_facing != 0


@export_enum("Bottom Left", "Bottom Right") var tail_position:
	set(value):
		tail_position = value
		if not is_node_ready():
			await ready
		_hbox_container.alignment = BoxContainer.ALIGNMENT_BEGIN if tail_position == 0 else BoxContainer.ALIGNMENT_END
		 

@onready var _hbox_container: HBoxContainer = %HBoxContainer
@onready var _texture_rect: TextureRect = %TextureRect


func set_target(target: Node2D) -> void:
	var left_or_right := int(target.global_position.x > global_position.x)
	tail_facing = left_or_right
	tail_position = left_or_right