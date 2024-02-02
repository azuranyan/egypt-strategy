extends Node2D

@export var unit: Unit

# Called when the node enters the scene tree for the first time.
func _ready():
	unit = Unit.new()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
