extends Panel


# Called when the node enters the scene tree for the first time.
func _ready():
	SceneManager.transition_finished.connect(refresh)
	refresh()
	
	
func refresh(_node: Node = null):
	$ItemList.clear()
	for i in range(SceneManager._scene_stack.size() - 1, -1, -1):
		$ItemList.add_item(get_scene_name(SceneManager._scene_stack[i]))
		
		
func get_scene_name(sf: SceneStackFrame) -> StringName:
	for scene_name in SceneManager.scenes:
		if SceneManager.scenes[scene_name] == sf.scene_path:
			return scene_name
	return &'INVALID'
	
	
func top_scene() -> GameScene:
	return get_tree().current_scene


func get_input_scene_name() -> StringName:
	if $LineEdit.text:
		return $LineEdit.text
	return $LineEdit.placeholder_text
	

func _on_line_edit_text_submitted(new_text):
	top_scene().scene_call(new_text)
	
	
func _on_call_button_pressed():
	top_scene().scene_call(get_input_scene_name())


func _on_load_button_pressed():
	# TODO GameScene doesn't have scene_load
	SceneManager.load_new_scene(SceneManager.scenes[get_input_scene_name()], 'fade_to_black')
		

func _on_return_button_pressed():
	top_scene().scene_return()


func _on_return_to_button_pressed():
	top_scene().scene_return_to(get_input_scene_name())


func _on_item_list_item_activated(index):
	top_scene().scene_return_to($ItemList.get_item_text(index))


func _on_item_list_item_selected(index):
	if not $LineEdit.text:
		$LineEdit.placeholder_text = $ItemList.get_item_text(index)


