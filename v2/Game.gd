extends Node


## Emitted when scene is started.
signal scene_started(scene)

## Emitted when scene is ended.
signal scene_ended

## Emitted when scene queue is finished.
signal scene_queue_finished

## Emitted when screen is ready.
signal screen_ready

## Emitted when the transition is finished.
signal transition_finished


signal _notify_end_scene


## The general direction.
enum Heading { East, South, West, North }

## List of direction vectors. Order is important!
const DIRECTIONS := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

## Record of game scenes.
#const SCENES := {
#	'overworld': preload("res://Screens/Overworld/Overworld.tscn"),
#	'battle': preload("res://Screens/Battle/Battle.tscn"),
#	'dialogue': preload("res://Screens/Dialogue/Dialogue.tscn"),
#	'main_menu': preload("res://Screens/MainMenu/MainMenu.tscn"),
#	'loading_screen': preload("res://Screens/LoadingScreen/LoadingScreen.tscn"),
#}
const loading_screen_scene := preload("res://Screens/LoadingScreen/LoadingScreen.tscn")
const dummy_scene := preload("res://Screens/LoadingScreen/DummyScene.tscn")


var territories := {
	# This will be auto populated in Overworld._ready
}

var empires := {
	# This will be auto populated in Overworld._ready
}

var maps := {
	# This will be auto populated in Entrypoint._ready
}

var prefs := {
	'defeat_if_home_territory_captured': true,
	'camera_follow_unit_move': true,
	'mouse_edge_scrolling': true, # TODO
	'auto_end_turn': false,
}

var attack := {
	# This will be auto populated in Entrypoint._ready
}

var chara := {
	# This will be auto populated in Entrypoint._ready
}

var doodad_type := {
	# This will be auto populated in Entrypoint._ready
}

var status_effect := {
	# This will be auto populated in Entrypoint._ready
}

var unit_type := {
	# This will be auto populated in Entrypoint._ready
}

var world := {
	# This will be auto populated in Entrypoint._ready
}

var scene_queue: Array[String] = []
var overworld: Overworld = preload("res://Screens/Overworld/Overworld.tscn").instantiate()

## Access to global battle variable.
var battle: Battle

var screen_stack: Array[Node] = []


## Registers data from /battle.
static func register_data(subdir: String, get_id: Callable):
	var path := "res://Screens/Battle/data/" + subdir + '/'
	var dir := DirAccess.open(path)
	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if !dir.current_is_dir() and filename.ends_with(".tres"):
			var res = load(path + filename)
			Globals.get(subdir)[get_id.call(res)] = res
		filename = dir.get_next()
		
		
## Replaces the top screen with another.
func transition_screen(new: Node, transition: String = ''):
	if screen_stack.size() == 0:
		push_screen(new, transition)
	else:
		var old := screen_stack[-1]
		screen_stack[-1] = new
		_transition.call_deferred(old, new, transition)


## Pushes a new screen on top.
func push_screen(new: Node, transition_effect: String = ''):
	# this check is not necessary but back() spits an error if null is empty
	# which is undesirable instead of just being fucking quiet about it 
	var old: Node = null if screen_stack.is_empty() else screen_stack.back()
	screen_stack.push_back(new)
	_transition.call_deferred(old, new, transition_effect)


## Pops the top screen and restores the previous screen.
func pop_screen(transition_effect: String = ''):
	var old: Node = screen_stack.pop_back()
	var new: Node = screen_stack.back()
	_transition.call_deferred(old, new, transition_effect)
	

func _transition(old: Node, new: Node, _transition_effect: String): # TODO different transitions
	print('transitioning from ', old, ' to ', new)
	# replace old screen with a dummy (dummy first to hide the remove)
	var dummy := dummy_scene.instantiate()
	get_tree().root.add_child(dummy)
	if old:
		get_tree().root.remove_child.call_deferred(old)
		
	# add loading screen
	var loading_screen := loading_screen_scene.instantiate() as LoadingScreen
	get_tree().root.add_child(loading_screen)
	
	# add new scene, deferred so the lag is hidden behind the transition
	get_tree().root.add_child.call_deferred(new)
	
	# wait for the loading screen to fade in
	await loading_screen.safe_to_load
	
	# replace dummy with new scene (child first so it's already there)
	#get_tree().root.add_child(new)
	screen_ready.emit()
	get_tree().root.remove_child(dummy)
	
	# wait for the loading screen to fade out
	await loading_screen.fade_out()
	transition_finished.emit()
	
	
## Plays queued insert scenes.
func play_queued_scenes():
	_dequeue_scene.call_deferred()
	await scene_queue_finished
		

## Notifies the game that scene has ended.
func notify_end_scene():
	_notify_end_scene.emit()
	
	
func _dequeue_scene():
	if not Globals.scene_queue.is_empty():
		var scn: String = Globals.scene_queue.pop_front()
		scene_started.emit(scn)
	else:
		scene_queue_finished.emit()
		
		
## This is the entry point of the game.
func start_game():
	pass
	
#func load_scene(old_scene: String, new_scene: String, transition: String):
#	var loading_screen_inst := SCENES.loading_screen.instantiate() as LoadingScreen
#	get_tree().root.add_child.call_deferred(loading_screen_inst)
#
#	var load_path: String = SCENES.get(new_scene, new_scene)
#	if not ResourceLoader.exists(load_path):
#		push_error("scene '%s' does not exist." % load_path)
#		return
#	var loader_new_scene := ResourceLoader.load_threaded_request(load_path)
#
#	await loading_screen_inst.safe_to_load
#	SCENES.get(old_scene, old_scene)
#	# queue free old_scene_inst
#
#	while true:
#		var load_progress := []
#		var load_status = ResourceLoader.load_threaded_get_status(load_path, load_progress)
#
#		match load_status:
#			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
#				push_error("unable to load: invalid resource.")
#				return null
#			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
#				loading_screen_inst.update(load_progress[0])
#			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
#				push_error("unable to load: loading failed.")
#				return null
#			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
#				var new_scene_inst := (ResourceLoader.load_threaded_get(load_path) as PackedScene).instantiate()
#				get_tree().root.add_child.call_deferred(new_scene_inst)
#				loading_screen_inst.fade_out()
