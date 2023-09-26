@tool
extends Node2D


signal world_changed


@export var world: World:
	set(value):
		world = value
		world_changed.emit()
		

var world_instance: WorldInstance
		

func _ready():
	world_instance = preload("res://Screens/Battle/WorldInstance.tscn").instantiate()
	add_child(world_instance, false, Node.INTERNAL_MODE_BACK)
	
	world_instance.world = world
	
	for c in get_children(true):
		print(c)


func _on_world_changed():
	world_instance.world = world
