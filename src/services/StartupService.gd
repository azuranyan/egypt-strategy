extends Node

signal game_started(startup_scene)
signal game_restarted()

export(bool) var startup: bool = true
export(String, FILE) var startup_scene: String



func _ready() -> void:
	var new_startup_scene = load(startup_scene)
	assert(new_startup_scene is PackedScene)
	
	if startup:
		emit_signal("game_started", startup_scene)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		
		match event.scancode: 
			KEY_F1:
				get_tree().call_deferred("quit")
			
			KEY_F2:
				emit_signal("game_restarted")
