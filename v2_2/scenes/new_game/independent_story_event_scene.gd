extends GameScene


@export_file("*.tscn") var next_scene: String


func scene_enter(kwargs := {}) -> void:
	if 'next_scene' in kwargs:
		next_scene = kwargs['next_scene']
	Dialogue.instance().refresh_event_queue()
	Dialogue.instance().start_queue()
	DialogueEvents.queue_ended.connect(finish_scene)


func scene_exit() -> void:
	DialogueEvents.queue_ended.disconnect(finish_scene)


func finish_scene() -> void:
	# the dialogue screen is immediately cleaned up so we need to capture it in a
	# dummy texture so we have something to show during the transition.
	$DummyDialogueScreen.texture = Game.capture_screenshot()

	if next_scene:
		SceneManager.load_new_scene(next_scene, 'fade_to_black')
	else:
		SceneManager.scene_return('fade_to_black')