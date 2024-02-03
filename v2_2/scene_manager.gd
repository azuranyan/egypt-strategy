extends Node
# original: Bacon and Games
# https://www.youtube.com/@baconandgames
# https://www.youtube.com/watch?v=2uYaoQj_6o0

## Emitted when transition is started.
signal transition_started(old_scene: String, new_scene: String)

## Emitted when transition has finished.
signal transition_finished(node: Node)


const LoadingScreenScene: PackedScene = preload("res://scenes/common/loading_screen.tscn")

var _loading_screen: LoadingScreen
var _transition: String
var _content_path: String
var _load_progress_timer: Timer
var _scene_stack: Array[SceneStackFrame]


func _ready():
	add_to_group('game_event_listeners')
	
	
## Loads a new scene and pushes it to the stack.
func call_scene(content_path: String, transition: String, continuation_method: StringName = &'', continuation_data: Dictionary = {}) -> void:
	var frame := SceneStackFrame.new()
	frame.scene_path = content_path
	frame.scene = null
	frame.continuation_method = continuation_method
	frame.continuation_data = continuation_data
	_load_scene(content_path, transition, frame)
	
	
## Pops the current scene from the stack and restores the previous scene.
func scene_return(transition: String):
	if _scene_stack.is_empty():
		push_error('scene_return(): scene stack empty!')
		return
	# pop current scene
	_scene_stack.pop_back()
	
	# restore previous scene
	var restore := _scene_stack.pop_back() as SceneStackFrame
	_load_scene(restore.scene_path, transition, restore)
	
	if restore.continuation_method:
		var node: Node = await transition_finished
		var continuation := Callable(node, restore.continuation_method)
		continuation.call(restore.continuation_data)
	
	
## Replaces the current scene with a new scene.
func load_new_scene(content_path: String, transition: String) -> void:
	var frame := SceneStackFrame.new()
	frame.scene_path = content_path
	frame.scene = null # will be populated later
	_load_scene(content_path, transition, frame)
	
	
func _load_scene(content_path: String, transition: String, frame: SceneStackFrame) -> void:
	# initialize transition data
	_transition = transition
	_loading_screen = LoadingScreenScene.instantiate() as LoadingScreen
	get_tree().root.add_child(_loading_screen)
	_loading_screen.start_transition(transition)
	
	# initialize stack frame
	if _scene_stack.is_empty():
		_scene_stack.push_back(frame)
	else:
		_scene_stack[_scene_stack.size() - 1] = frame
	
	# start loading
	transition_started.emit(get_tree().current_scene.scene_file_path, content_path)
	_load_content(content_path)
	
	
## Returns the current stack frame.
func current_frame() -> SceneStackFrame:
	return _scene_stack.back() if not _scene_stack.is_empty() else null


## Returns true if a transition is active.
func is_loading() -> bool:
	return _loading_screen != null
	
	
func _load_content(content_path: String) -> void:
	_content_path = content_path
	var loader := ResourceLoader.load_threaded_request(content_path)
	if not ResourceLoader.exists(content_path) or loader == null:
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
			current_frame().scene = scene
			_loading_finished(scene.instantiate())


func _invalid_resource() -> void:
	printerr('unable to load "%s": invalid resource.' % current_frame().scene_path)
	_transition_done(null)
	
	
func _loading_failed() -> void:
	printerr('unable to load "%s": loading failed.' % current_frame().scene_path)
	_transition_done(null)


func _loading_finished(new_scene: Node) -> void:
	# if by this point transition has not reached midpoint yet, wait for it
	if not _loading_screen.is_midpoint_finished():
		await _loading_screen.transition_midpoint
		
	await _replace_current_scene(new_scene)
	
	# finalize
	_transition_done(new_scene)
	
	
func _replace_current_scene(new_scene: Node):
	_exit_scene.call_deferred(get_tree().current_scene)
	_enter_current_scene.call_deferred(new_scene)
	if is_loading():
		_loading_screen.finish_transition()
		await _loading_screen.transition_finished
	
	
func _enter_current_scene(new_scene: Node):
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
	if new_scene.has_method('enter_scene'):
		new_scene.enter_scene()
	
	
func _exit_scene(old_scene: Node):
	if old_scene.has_method('exit_scene'):
		old_scene.exit_scene()
	old_scene.free()
	
	
func _transition_done(node: Node) -> void:
	# cleanup
	_loading_screen = null # should queue_free() itself
	_transition = ''
	_content_path = ''
	if _load_progress_timer:
		_load_progress_timer.queue_free()
		_load_progress_timer = null
		
	# if loading failed, pop the stack frame
	if current_frame().scene == null:
		_scene_stack.pop_back()
		
	# notify listeners
	transition_finished.emit(node)


func on_save(save: SaveState):
	save.scene_stack = _scene_stack.duplicate()
	
	
func on_load(save: SaveState):
	_scene_stack = save.scene_stack
	assert(current_frame(), 'loaded stack frame is empty! check if Game pushed any scene before saving')
	_scene_stack.push_back(null)
	scene_return('fade_to_black')
	
