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


## Returns true if a transition is active.
func is_loading() -> bool:
	return _loading_screen != null
	
	
## Loads in a new scene with a given transition.
func load_new_scene(content_path: String, transition: String = 'fade_to_black') -> void:
	if is_loading():
		push_warning('transitioning while on transition: double check')
	transition_started.emit(get_tree().current_scene.scene_file_path, content_path)
	
	_transition = transition
	_loading_screen = LoadingScreenScene.instantiate() as LoadingScreen
	get_tree().root.add_child(_loading_screen)
	_loading_screen.start_transition(transition)
	
	_load_content(content_path)
	
	
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
			_loading_finished(ResourceLoader.load_threaded_get(_content_path).instantiate())


func _invalid_resource() -> void:
	printerr("unable to load: invalid resource.")
	_transition_done(null)
	
	
func _loading_failed() -> void:
	printerr("unable to load: loading failed.")
	_transition_done(null)


func _loading_finished(new_scene: Node) -> void:
	# if by this point transition has not reached midpoint yet, wait for it
	if not _loading_screen.is_midpoint_finished():
		await _loading_screen.transition_midpoint
		
	# add new scene
	get_tree().root.add_child.call_deferred(new_scene)
	get_tree().set_deferred('current_scene', new_scene)
	
	# remove the old scene
	var old_scene := get_tree().current_scene
	if old_scene.has_method('exit_scene'):
		old_scene.exit_scene()
	old_scene.queue_free()
	
	# finish the loading screen
	_loading_screen.finish_transition()
	await _loading_screen.transition_finished
	if new_scene.has_method('enter_scene'):
		new_scene.enter_scene()
	
	# finalize
	_transition_done(new_scene)
	
	
func _transition_done(node: Node) -> void:
	# cleanup
	_loading_screen = null # should queue_free() itself
	_transition = ''
	_content_path = ''
	if _load_progress_timer:
		_load_progress_timer.queue_free()
		_load_progress_timer = null
		
	# notify listeners
	transition_finished.emit(node)
