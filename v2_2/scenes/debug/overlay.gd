class_name TestOverlay
extends CanvasLayer


var locked: bool


@onready var current_context_label = $CurrentContextState


func _ready():
	refresh_load_button()
	
	$Timer.timeout.connect(update)
	$Timer.start()

	visible = OS.is_debug_build()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ALT:
		visible = event.pressed or locked


func update():
	if get_tree().current_scene is OverworldScene:
		# cant use name because duplicates are garbled due to name mangling
		# e.g. when loading the same state
		current_context_label.key = 'Overworld' 
		current_context_label.value = Overworld.instance()._next_state
	elif get_tree().current_scene is BattleScene:
		current_context_label.key = 'Battle'
		var state_string: StringName = BattleImpl.State.find_key(BattleImpl.instance()._next_state)
		if BattleImpl.instance()._waiting_for:
			current_context_label.value = state_string + ' (' + BattleImpl.instance()._waiting_for + ')'
		else:
			current_context_label.value = state_string
	else:
		current_context_label.key = get_tree().current_scene.get_script().get_path()
		current_context_label.value = ''


func _on_load_button_pressed():
	Game.load_state(SaveManager.load_from_slot(save_slot()))
	

func _on_save_button_pressed():
	SaveManager.save_to_slot(Game.save_state(), save_slot())
	refresh_load_button()
	
	
func save_slot() -> int:
	if ($OptionButton.selected == 0) or (Persistent.newest_save_slot == -1):
		return 0
	return Persistent.newest_save_slot
	
	
func refresh_load_button():
	$HBoxContainer/LoadButton.disabled = not SaveManager.is_slot_in_use(save_slot())
	

func _on_quit_button_pressed():
	Game.quit_game()


func _on_button_pressed():
	CanvasLayer.print_orphan_nodes()


func _on_lock_button_toggled(toggled_on: bool) -> void:
	locked = toggled_on
	if not locked:
		$LockButton.release_focus()
		visible = Input.is_key_pressed(KEY_ALT)