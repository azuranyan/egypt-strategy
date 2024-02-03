class_name GameScene
extends CanvasLayer
## An abstraction for simplifying controls of [Game] and [SceneManager].


func _enter_tree():
	add_to_group('game_event_listeners')
	
	
func _exit_tree():
	remove_from_group('game_event_listeners')


## Returns true if this scene is current and active.
func is_active() -> bool:
	return is_inside_tree() and get_tree().current_scene == self
	
	
## Pops off this scene and pushes the new scene to the stack.
func scene_call(scene_name: StringName, transition := 'fade_to_black', continuation_method: StringName = &'', continuation_data := {}) -> void:
	if not is_active():
		push_error('%s: attempt to call another scene from non active scene' % self)
		return
	if scene_name not in SceneManager.scenes:
		push_error('%s: "%s" not found' % [self, scene_name])
		return
		
	SceneManager.call_scene(SceneManager.scenes[scene_name], transition, continuation_method, continuation_data)
	return
	
	
## Ends current scene and returns to the previous scene.
func scene_return(transition := 'fade_to_black') -> void:
	if not is_active():
		push_warning('%s: attempt to return from non active scene' % self)
		return
	# TODO what happens if this fails, do we just stay or we get popped?
	SceneManager.scene_return(transition)


## Replaces the current scene with a new scene.
func scene_load(scene_name: StringName, transition := 'fade_to_black') -> void:
	if not is_active():
		push_warning('%s: attempt to load another scene from non active scene' % self)
		return
	if scene_name not in SceneManager.scenes:
		push_error('%s: "%s" not found' % [self, scene_name])
		return
	SceneManager.load_new_scene(SceneManager.scenes[scene_name], transition)
