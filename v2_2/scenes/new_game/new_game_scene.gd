extends GameScene


func scene_enter(_kwargs := {}) -> void:
	Dialogue.instance().refresh_event_queue()
	Dialogue.instance().start_queue()
	
	DialogueEvents.queue_ended.connect(start_next_scene)


func start_next_scene() -> void:
	# the dialogue screen is immediately cleaned up so we need to capture it in a
	# dummy texture so we have something to show during the transition.
	$DummyDialogueScreen.texture = Game.capture_screenshot()

	SceneManager.load_new_scene(SceneManager.scenes.overworld, 'fade_to_black')

	
func scene_exit() -> void:
	DialogueEvents.queue_ended.disconnect(start_next_scene)

