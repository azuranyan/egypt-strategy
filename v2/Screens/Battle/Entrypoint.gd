extends Node2D

# Just the place to enter battle map scene, until we connect the whole game
# together

@export var map_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	call_deferred("_change_scene")

func _change_scene():
	Battle.load_map_scene(map_scene)

