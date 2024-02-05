class_name GameScene
extends CanvasLayer
## An abstraction for simplifying controls of [Game] and [SceneManager].


var _active := false


func _enter_tree():
	add_to_group('game_event_listeners')
	
	
func _exit_tree():
	remove_from_group('game_event_listeners')


func set_active(active: bool):
	_active = active


## Returns true if this scene is current and active.
func is_active() -> bool:
	return _active and is_inside_tree() and (get_tree().current_scene == self) and (not SceneManager.is_loading())
	
	
## Pops off this scene and pushes the new scene to the stack.
func scene_call(scene_name: StringName, transition := 'fade_to_black', kwargs := {}, continuation_method: StringName = &'', continuation_data := {}) -> void:
	if not is_active():
		push_error('%s: attempt to call another scene from non active scene' % self)
		return
	if scene_name not in SceneManager.scenes:
		push_error('%s: "%s" not found' % [self, scene_name])
		return
	set_active(false)
	SceneManager.call_scene(SceneManager.scenes[scene_name], transition, kwargs, continuation_method, continuation_data)
	
	
## Ends current scene and returns to the previous scene.
func scene_return(transition := 'fade_to_black', kwargs := {}) -> void:
	if not is_active():
		push_warning('%s: attempt to return from non active scene' % self)
		return
	set_active(false)
	SceneManager.scene_return(transition, kwargs)


## Replaces the current scene with a new scene.
func scene_load(scene_name: StringName, transition := 'fade_to_black') -> void:
	if not is_active():
		push_warning('%s: attempt to load another scene from non active scene' % self)
		return
	if scene_name not in SceneManager.scenes:
		push_error('%s: "%s" not found' % [self, scene_name])
		return
	set_active(false)
	SceneManager.load_new_scene(SceneManager.scenes[scene_name], transition)
