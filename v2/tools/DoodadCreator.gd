@tool
extends Node2D


signal property_changed(prop, value)

@export_subgroup("DoodadType")

## The image texture to use.
@export var texture: Texture2D

## The world space it uses as a reference.
@export var world: World

## The position of this object in the source world (in uniform world space).
@export var source_pos: Vector2

@export_subgroup("Export")

@export var doodad_type: DoodadType

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
