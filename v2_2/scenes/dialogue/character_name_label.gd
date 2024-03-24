@tool
extends RichTextLabel


enum Capitalize {
	NONE,
	CAPITALIZE,
	ALL_CAPS,
}


@export var capitalize: Capitalize
@export var chara_name: String
@export var translate: bool = true
@export var colored_outline: bool = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

