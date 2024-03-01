extends Node
# original: Bacon and Games
# https://www.youtube.com/@baconandgames
# https://www.youtube.com/watch?v=2uYaoQj_6o0

## Emitted when transition is started.
signal transition_started(old_scene: String, new_scene: String)

## Emitted when transition has finished.
signal transition_finished(node: Node)

## Emitted when scene is ready.
signal scene_ready(node: Node)


const LoadingScreenScene: PackedScene = preload("res://scenes/common/loading_screen.tscn")

## Contains the mapping of scene names to scene paths.
var scenes: Dictionary

var _scene_stack: Array[SceneStackFrame]
var _current_frame: SceneStackFrame

var _transition_ongoing: bool
var _content_path: String
var _transition: String
var _enter_ready: bool
var _exit_ready: bool
var _load_progress_timer: Timer
var _loading_screen: LoadingScreen


func _ready():
	add_to_group('game_event_listeners')

	# THIS IS EXTREMELY IMPORTANT
	process_mode = Node.PROCESS_MODE_ALWAYS
	

## Replaces the current scene with a new scene.
func load_new_scene(content_path: String, transition: String, kwargs := {}) -> void:
	await _wait_for_transition_finish()

	# instantiate new frame
	var frame := SceneStackFrame.new()
	frame.scene_path = content_path
	frame.scene = null
	frame.kwargs = kwargs
	_current_frame = frame

	# load scene
	_load_scene(transition)
	
	
## Loads a new scene and pushes it to the stack.
func call_scene(content_path: String, transition: String, kwargs := {}) -> void:
	await _wait_for_transition_finish()

	if _current_frame:
		# store current to stack
		_scene_stack.push_back(_current_frame)

	# load scene
	load_new_scene(content_path, transition, kwargs)
	
	
## Pops the current scene from the stack and restores the previous scene.
func scene_return(transition: String, kwargs := {}) -> void:
	await _wait_for_transition_finish()
	if _scene_stack.is_empty():
		push_error('scene_return(): scene stack empty!')
		get_tree().quit()
		return

	# restore previous scene
	_current_frame = _scene_stack.pop_back()
	_current_frame.kwargs = kwargs
	
	# load scene
	_load_scene(transition)
	

func _wait_for_transition_finish() -> void:
	if is_loading():
		await transition_finished
		
	
## Returns the current stack frame.
func current_frame() -> SceneStackFrame:
	return _current_frame


## Returns true if a transition is active.
func is_loading() -> bool:
	return _transition_ongoing
	
	
func _load_scene(transition: String) -> void:
	# initialize transition data
	_transition_ongoing = true
	_content_path = _current_frame.scene_path
	_transition = transition
	_enter_ready = false
	_exit_ready = false
	_load_progress_timer = null
	_loading_screen = LoadingScreenScene.instantiate() as LoadingScreen

	get_tree().root.add_child(_loading_screen)
	_loading_screen.start_transition(transition)
	
	# start loading
	transition_started.emit('' if _scene_stack.is_empty() else _scene_stack[-1].scene_path, _content_path)
	_load_content()
	

func _load_content() -> void:
	if not ResourceLoader.exists(_content_path) or ResourceLoader.load_threaded_request(_content_path) != OK:
		return _invalid_resource()
		
	_load_progress_timer = Timer.new()
	_load_progress_timer.wait_time = 0.1
	_load_progress_timer.timeout.connect(_update_load_progress)
	add_child(_load_progress_timer)
	_load_progress_timer.start()
	
	
func _update_load_progress() -> void:
	# workaround for a weird state we're still updating when it's already ended
	if not is_loading(): 
		return
		
	var load_progress := []
	var load_status := ResourceLoader.load_threaded_get_status(_content_path, load_progress)
	
	match load_status:
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
			_load_progress_timer.stop()
			_invalid_resource()
			
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
			_loading_screen.update_progress(load_progress[0])
			
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
			_load_progress_timer.stop()
			_loading_failed()
			
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			_load_progress_timer.stop()
			var scene := ResourceLoader.load_threaded_get(_content_path)
			_current_frame.scene = scene
			_loading_finished(scene.instantiate())


func _invalid_resource() -> void:
	printerr('unable to load "%s": invalid resource.' % current_frame().scene_path)
	_transition_done(null)
	
	
func _loading_failed() -> void:
	printerr('unable to load "%s": loading failed.' % current_frame().scene_path)
	_transition_done(null)


var count := 0
func _loading_finished(new_scene: Node) -> void:
	count += 1
	# if by this point transition has not reached midpoint yet, wait for it
	if not _loading_screen.is_midpoint_finished():
		await _loading_screen.transition_midpoint
	
	# this should defer adding and removing from tree preventing hiccups
	_replace_current_scene(new_scene)

	# if by this point the scenes are not added/removed from the tree yet, wait for it
	if not _enter_ready or not _exit_ready:
		await scene_ready

	if is_loading():
		_loading_screen.finish_transition()
		await _loading_screen.transition_finished

	# finalize
	_transition_done(new_scene)
	
	
func _replace_current_scene(new_scene: Node):
	# allow new scene to enter first before old scene exits:
	# this lets the old scene to send a signal as it exits and this still
	# be listened to from the entering scene.
	var old_scene := get_tree().current_scene
	assert(old_scene)
	_enter_current_scene.call_deferred(new_scene)
	_exit_scene.call_deferred(old_scene, new_scene)
	
	
func _enter_current_scene(new_scene: Node):
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
	if new_scene.has_method('set_active'):
		new_scene.set_active(true)
	if new_scene.has_method('scene_enter'):
		new_scene.scene_enter(_current_frame.kwargs)
	_enter_ready = true
	_check_scene_ready(new_scene)
	
	
func _exit_scene(old_scene: Node, new_scene: Node):
	if old_scene.has_method('set_active'):
		old_scene.set_active(false)
	if old_scene.has_method('scene_exit'):
		old_scene.scene_exit()
	old_scene.free()
	_exit_ready = true
	_check_scene_ready(new_scene)


func _check_scene_ready(new_scene: Node) -> void:
	if _enter_ready and _exit_ready:
		_enter_ready = false
		_exit_ready = false
		scene_ready.emit(new_scene)
	
	
func _transition_done(node: Node) -> void:
	# cleanup
	_content_path = ''
	_transition = ''
	_enter_ready = false
	_exit_ready = false
	if _load_progress_timer:
		_load_progress_timer.free()
		_load_progress_timer = null
	_loading_screen = null # loading screen frees itself
		
	# if loading failed, pop the stack frame
	if not node:
		_current_frame = null
		
	# notify listeners
	_transition_ongoing = false
	transition_finished.emit(node)


func save_state() -> Dictionary:
	return {
		scene_stack = _scene_stack.duplicate(),
		current_frame = _current_frame,
	}
	
	
func load_state(data: Dictionary):
	_scene_stack.assign(data.scene_stack)
	_current_frame = data.current_frame

	_load_scene('fade_to_black')
