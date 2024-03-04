class_name DialogueScene
extends CanvasLayer


## Emitted when the dialogue is started.
signal dialogue_started

## Emitted when the dialogue is finished.
signal dialogue_finished

## Emitted when the dialogue box is shown or hidden.
signal shown(value: bool)

## Emitten when the menu button is pressed.
signal menu_button_pressed


const NEXT_ACTION := 'ui_accept'
const SKIP_ACTION := 'ui_cancel'


var _shown: bool
var _resource: DialogueResource
var _temp_game_states := []
var _waiting_for_input: bool
var _dialogue_line: DialogueLine:
	set(value):
		_waiting_for_input = false
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()

		if not value:
			queue_free()
			dialogue_finished.emit()
			return

		_dialogue_line = value
		update_dialogue()
		

@onready var balloon: Control = $Balloon
@onready var character_label: RichTextLabel = %CharacterLabel
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu


func _ready() -> void:
	$AnimationPlayer.play("RESET")

	balloon.gui_input.connect(_on_balloon_gui_input)
	responses_menu.response_selected.connect(func(response: DialogueResponse): next(response.next_id))
	DialogueManager.mutated.connect(_on_mutated)
	%MenuButton.pressed.connect(_on_menu_button_pressed)


func _exit_tree() -> void:
	request_ready()
	DialogueManager.mutated.disconnect(_on_mutated)


func _unhandled_input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	
	
## Shows the dialogue box.
func show_dialogue(reshow: bool = false) -> void:
	if _shown:
		if reshow:
			hide_dialogue()
			await shown
		else:
			return
	$AnimationPlayer.play("show")


## Hides the dialogue box.
func hide_dialogue() -> void:
	if _shown:
		$AnimationPlayer.play("hide")


## Toggles the dialogue box.
func toggle_dialogue_box(reshow: bool = false) -> void:
	if _shown:
		hide_dialogue()
	else:
		show_dialogue(reshow)


## Starts the dialogue.
func start(dialogue_resource: DialogueResource, title: String, extra_game_states := []) -> void:
	_temp_game_states = extra_game_states.duplicate()
	_waiting_for_input = false
	_resource = dialogue_resource
	emit_signal.call_deferred('dialogue_started')
	next(title)
	

## Shows the next dialogue line.
func next(next_id: String) -> void:
	_dialogue_line = await DialogueManager.get_next_dialogue_line(_resource, next_id, _temp_game_states)


## Updates the dialogue.
func update_dialogue() -> void:
	if not is_node_ready():
		await ready
	
	if _dialogue_line.character:
		if Director.is_character_shown(_dialogue_line.character):
			Director.show_character(_dialogue_line.character, Director.KEEP_POSITION, _dialogue_line.tags)
		character_label.text = tr(_dialogue_line.character)
		character_label.show()
	else:
		character_label.hide()

	dialogue_label.hide()
	dialogue_label.dialogue_line = _dialogue_line

	responses_menu.hide()
	responses_menu.responses = _dialogue_line.responses

	show_dialogue()
	dialogue_label.show()
	if _dialogue_line.text:
		dialogue_label.type_out()
		await dialogue_label.finished_typing
	
	if is_waiting_for_response():
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()

	elif _dialogue_line.time:
		var time: float
		if _dialogue_line.time.is_valid_float():
			time = _dialogue_line.time.to_float()
		else:
			time = _dialogue_line.text.length() * 0.2

		await get_tree().create_timer(time).timeout
		next(_dialogue_line.next_id)
	
	else:
		_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


## Returns true if we're waiting for input.
func is_waiting_for_input() -> bool:
	return _waiting_for_input

	
## Returns true if we're waiting for a response.
func is_waiting_for_response() -> bool:
	return _dialogue_line.responses.size() > 0


func _on_balloon_gui_input(event: InputEvent) -> void:
	if dialogue_label.is_typing:
		var mouse_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_pressed: bool = event.is_action_pressed(SKIP_ACTION)
		if mouse_clicked or skip_pressed:
			balloon.accept_event()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input():
		return
	if is_waiting_for_response():
		return

	balloon.accept_event()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(_dialogue_line.next_id)
	elif event.is_action_pressed(NEXT_ACTION) and get_viewport().gui_get_focus_owner() == balloon:
		next(_dialogue_line.next_id)
	

func _on_mutated(_mutation: Dictionary) -> void:
	_waiting_for_input = false
	#get_tree().create_timer(0.1).timeout.connect(hide_dialogue)


func _on_menu_button_pressed() -> void:
	%MenuButton.release_focus()
	menu_button_pressed.emit()