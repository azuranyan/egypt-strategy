class_name Empire extends Node

export(float, 0, 1) var aggression_rating = 0.0
var territories = []
var units = []
var leader = 5
export var is_AI_controlled = true
export var use_mock_str_rateing = true
export(float, 0, 1) var mock_strength_rating: float = 0.5
var strength_rating = 0.5
var hp_multiplier: float = 1.0

var home_territory

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
