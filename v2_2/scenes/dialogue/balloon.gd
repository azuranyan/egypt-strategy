extends PanelContainer


@export var show_tail: bool = true
@export var continue_action: StringName
@export var skip_action: StringName

@export_group("Animation")
@export_range(0, 1) var animation_duration: float

@export_group("Connections")
@export var character_label: RichTextLabel
@export var dialogue_label: DialogueLabel
@export var tail: TextureRect
@export var responses_menu: DialogueResponsesMenu
#@export var response


## The dialogue resource.
var _resource: DialogueResource

## List of game states passed to us.
var _temp_game_states: Array

## The current dialogue line.
var _current_line: DialogueLine:
	set(value):
		_waiting_for_input = false
		focus_mode = Control.FOCUS_ALL
		grab_focus()

		if not value:
			queue_free()
			#dialogue_finished.emit()
			return

		_current_line = value
		update_dialogue()
		#dialogue_line_changed.emit(_current_line)


var _waiting_for_input: bool


func _ready() -> void:
	update_visuals(0)

	visibility_changed.connect(_on_visibility_changed)


## Opens the dialogue balloon.
func open_balloonrt(dialogue_resource: DialogueResource, title: String, extra_game_states := []) -> void:
	_temp_game_states = extra_game_states.duplicate()
	_waiting_for_input = false
	_resource = dialogue_resource
	emit_signal.call_deferred('dialogue_started')
	next(title)


func close_balloon() -> void:
	if _current_line.character:
		character_label.text = tr(_current_line.character)
		character_label.show()
	else:
		character_label.hide()


	# setup dialogue label
	dialogue_label.hide()
	dialogue_label.dialogue_line = _current_line



## Shows the next dialogue line.
func next(next_id: String) -> void:
	_current_line = await DialogueManager.get_next_current_line(_resource, next_id, _temp_game_states)


## Called to update the dialogue.
func update_dialogue() -> void:
	if _current_line.character:
		character_label.text = tr(_current_line.character)
		character_label.show()
	else:
		character_label.hide()

	dialogue_label.hide()
	dialogue_label.dialogue_line = _current_line

	responses_menu.hide()
	responses_menu.responses = _current_line.responses

	# show_dialogue()
	# dialogue_label.show()
	# if _current_line.text:
	# 	dialogue_label.type_out()
	# 	await dialogue_label.finished_typing
	
	# if is_waiting_for_response():
	# 	balloon.focus_mode = Control.FOCUS_NONE
	# 	responses_menu.show()

	# elif _current_line.time:
	# 	var time: float
	# 	if _current_line.time.is_valid_float():
	# 		time = _current_line.time.to_float()
	# 	else:
	# 		time = _current_line.text.length() * 0.2

	# 	await get_tree().create_timer(time).timeout
	# 	next(_current_line.next_id)
	
	# else:
	# 	_waiting_for_input = true
	# 	balloon.focus_mode = Control.FOCUS_ALL
	# 	balloon.grab_focus()


func update_visuals(duration: float) -> void:
	# take the new pivot point
	pivot_offset = Vector2(0.5, 0.5) * size
	
	# animate the pop
	if duration > 0:
		var tween := create_tween()
		if visible:
			tween.tween_property(self, 'modulate', Color.WHITE, duration)
			tween.tween_property(self, 'scale', Vector2.ONE, duration)
		else:
			tween.tween_property(self, 'modulate', Color.TRANSPARENT, duration)
			tween.tween_property(self, 'scale', Vector2.ZERO, duration)
	else:
		if visible:
			modulate = Color.WHITE
			scale = Vector2.ONE
		else:
			modulate = Color.TRANSPARENT
			scale = Vector2.ZERO


func _on_visibility_changed() -> void:
	update_visuals(animation_duration)