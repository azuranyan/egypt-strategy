extends Panel


# Called when the node enters the scene tree for the first time.
func _ready():
	SceneManager.transition_finished.connect(refresh)
	refresh()
	
	
func refresh(_node: Node = null):
	%CallStackList.clear()
	for i in range(SceneManager._scene_stack.size() - 1, -1, -1):
		%CallStackList.add_item(get_scene_name(SceneManager._scene_stack[i]))
	%CurrentSceneLabel.text = get_scene_name(SceneManager.current_frame())
		
		
func get_scene_name(sf: SceneStackFrame) -> StringName:
	if not sf:
		return '<null>'
	for scene_name in SceneManager.scenes:
		if SceneManager.scenes[scene_name] == sf.scene_path:
			return scene_name
	return sf.scene_path
	
	
func top_scene() -> GameScene:
	return get_tree().current_scene


func get_input_scene_name() -> StringName:
	if %LineEdit.text:
		return %LineEdit.text
	return %LineEdit.placeholder_text
	

func call_scene(scene_id: StringName) -> void:
	if scene_id == 'winwinwin' and Battle.instance().is_running():
		if Battle.instance().player() == Battle.instance().attacker():
			Battle.instance().stop_battle(BattleResult.ATTACKER_VICTORY)
		else:
			Battle.instance().stop_battle(BattleResult.DEFENDER_VICTORY)
	else:
		top_scene().scene_call(scene_id)


func _on_line_edit_text_submitted(new_text):
	call_scene(new_text)
	
	
func _on_call_button_pressed():
	call_scene(get_input_scene_name())


func _on_load_button_pressed():
	# TODO GameScene doesn't have scene_load
	SceneManager.load_new_scene(SceneManager.scenes[get_input_scene_name()], 'fade_to_black')
		

func _on_return_button_pressed():
	top_scene().scene_return()


func _on_return_to_button_pressed():
	if SceneManager.scenes[get_input_scene_name()] == SceneManager._scene_stack.back().scene_path:
		return
	top_scene().scene_return_to(get_input_scene_name())


func _on_item_list_item_activated(index):
	if index == SceneManager._scene_stack.size() - 1:
		return
	top_scene().scene_return_to(%CallStackList.get_item_text(index))


func _on_item_list_item_selected(index):
	if not %LineEdit.text:
		%LineEdit.placeholder_text = %CallStackList.get_item_text(index)


