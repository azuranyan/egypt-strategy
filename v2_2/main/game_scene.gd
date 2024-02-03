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
func call_scene(scene_name: StringName, transition := 'fade_to_black', continuation_method: StringName = &'', continuation_data := {}) -> Error:
	if not is_active():
		push_warning('%s: attempt to call another scene from non active scene' % self)
		return OK
	
	if scene_name not in SceneManager.scenes:
		return ERR_DOES_NOT_EXIST
		
	SceneManager.call_scene(scene_name, transition, continuation_method, continuation_data)
	return OK
	
	
## Ends current scene and returns to the previous scene.
func scene_return(transition := 'fade_to_black'):
	if not is_active():
		push_warning('%s: attempt to return from non active scene' % self)
		return
	SceneManager.scene_return(transition)
