class_name GameScene
extends CanvasLayer
## An abstraction for simplifying controls of [Game] and [SceneManager].


## The transition to use when transitioning in.
## Leave empty for fallback or [code]"skip"[/code] to skip.
## 
## If both the entering scene and exiting scene have transitions specified,
## the entering scene will be prioritized.
@export var transition_in: StringName

## The transition to use when transitioning out.
## Leave empty for fallback or [code]"skip"[/code] to skip.
## 
## If both the entering scene and exiting scene have transitions specified,
## the entering scene will be prioritized.
@export var transition_out: StringName


var _active := false


func _enter_tree():
	add_to_group('game_event_listeners')
	
	
func _exit_tree():
	remove_from_group('game_event_listeners')


## Sets this node active.
func set_active(active: bool):
	_active = active


## Returns true if this scene is current and active.
func is_active() -> bool:
	return _active and is_inside_tree() and (get_tree().current_scene == self) and (not SceneManager.is_loading())
	
	
## Pops off this scene and pushes the new scene to the stack.
func scene_call(scene_name: StringName, kwargs := {}) -> void:
	if not is_active():
		return push_error('%s: attempt to call another scene from non active scene' % self)
		
	if scene_name not in SceneManager.scenes:
		return push_error('%s: "%s" not found' % [self, scene_name])
		
	set_active(false)
	SceneManager.call_scene(
		SceneManager.scenes[scene_name],
		kwargs.get('transition', 'fade_to_black'),
		kwargs,
	)
	
	
## Ends current scene and returns to the previous scene.
func scene_return(kwargs := {}) -> void:
	if not is_active():
		return push_warning('%s: attempt to return from non active scene' % self)
		
	set_active(false)
	SceneManager.scene_return(
		kwargs.get('transition', 'fade_to_black'),
		kwargs
	)
	
	
## Drops all scene, skipping transitions until it reaches the scene with label.
func scene_return_to(scene_name: StringName, kwargs := {}) -> void:
	if not is_active():
		return push_warning('%s: attempt to return from non active scene' % self)
		
	if scene_name not in SceneManager.scenes:
		return push_error('%s: "%s" not found' % [self, scene_name])
		
	# inspect if scene exists
	var idx := -1
	for i in range(SceneManager._scene_stack.size() - 1, -1, -1):
		if SceneManager._scene_stack[i].scene_path == SceneManager.scenes[scene_name]:
			idx = i
			
	if idx == -1:
		return push_error('%s: "%s" not found in call stack' % [self, scene_name])
	
	set_active(false)
	StackUnwinder.new().unwind(idx, kwargs)
	

func _which_transition(enter: StringName, exit: StringName, override: StringName) -> StringName:
	return override if override else enter if enter else exit


class StackUnwinder extends Object:
	
	func unwind(idx: int, kwargs := {}) -> void:
		# skip and pop until last item
		for i in range(SceneManager._scene_stack.size() - 1, idx + 1, -1):
			SceneManager.scene_return('skip')
			await SceneManager.transition_finished
		
		# show transition on last pop
		SceneManager.scene_return(
			kwargs.get('transition', 'fade_to_black'),
			kwargs
		)
		await SceneManager.transition_finished
		free()
		
		
