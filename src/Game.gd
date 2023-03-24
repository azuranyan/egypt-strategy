extends Node2D



enum UIMode {
	FREE,
	LEFT_WIDE,
}

var game_scene: Node
var current_game_scene_path: String
var current_camera: Camera2D

onready var ui = get_node("UILayer/UI")



# TEMPORARY #
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.scancode == KEY_E:
		ui.get_node("Free/Press_E").hide()
		var actors: Array = []
		
		var ally_two = load("res://src/entities/actors/Zahra.tscn").instance()
		ally_two.grid = get_current_grid()
		actors.push_back(ally_two)
		
		var enemy_one = load("res://src/entities/actors/Alara.tscn").instance()
		enemy_one.grid = get_current_grid()
		actors.push_back(enemy_one)
		
		var ally_one = load("res://src/entities/actors/Lysandra.tscn").instance()
		ally_one.grid = get_current_grid()
		actors.push_back(ally_one)
		
		var enemy_two = load("res://src/entities/actors/Ishtar.tscn").instance()
		enemy_two.grid = get_current_grid()
		actors.push_back(enemy_two)
		
		get_node("Battle").start_battle(actors)
		set_process_input(false)
# TEMPORARY #


func get_game_scene():
	if not game_scene:
		push_error("Map doesn't exist.")
		return null 
	
	return game_scene


func set_game_scene(new_scene_path: String) -> void:
	if game_scene:
		game_scene.free()
	
	current_game_scene_path = new_scene_path
	game_scene = load(current_game_scene_path).instance()
	call_deferred("add_child", game_scene)
	call_deferred("move_child", game_scene, 0)
	
	for c in get_tree().get_nodes_in_group("camera"):
		if c.current:
			current_camera = c


func reload_game_scene() -> void:
	clear_ui()
	get_node("UILayer/UI/Free/Press_E").show()
	set_game_scene(current_game_scene_path)
	set_process_input(true)


func add_ui(new_ui: Control, mode: int = UIMode.FREE):
	assert(mode in UIMode.values())
	
	if new_ui.get_parent():
		new_ui.get_parent().remove_child(new_ui)
	
	match mode:
		UIMode.FREE:
			ui.get_node("Free").add_child(new_ui)
		UIMode.LEFT_WIDE:
			ui.get_node("LeftWide").add_child(new_ui)


func clear_ui() -> void:
	for c in ui.get_child(0).get_children():
		c.queue_free()
	
	for c in ui.get_child(1).get_children().slice(2, ui.get_child(1).get_child_count()):
		c.queue_free()


func get_current_camera_top_left() -> Vector2:
	return current_camera.get_camera_screen_center() - current_camera.get_viewport_rect().size * 0.5


func get_current_grid() -> Grid:
	return get_game_scene().get_node("Grid") as Grid




