@tool
class_name Balloon
extends PanelContainer
## Renders a line of dialogue.

## Emitted when the balloon is opened.
signal opened

## Emitted when the balloon is closed.
signal closed

## Emitted when the balloon is finished.
signal finished


const DEFAULT_ANIMATION_DURATION: float = 0.3

const DEFAULT_TARGET_OFFSET: Vector2 = Vector2(-69.420, -69.420)

const DEFAULT_SPACING: float = 30


## Whether to show the tail or not.
@export var show_tail: bool = true:
	set(value):
		show_tail = value
		if not is_node_ready():
			await ready
		if tail:
			tail.visible = target and show_tail

## The action to listen to to continue the dialogue.
@export var continue_action: StringName

## The action to listen to to skip the dialogue.
@export var skip_action: StringName

## Whether to automatically close when finished.
@export_flags("Close", "Free") var on_finish: int = (1 << 0) | (1 << 1)

## Whether the text should be centered.
@export var centered_text: bool

## The target node to attach to.
@export var target: Node2D:
	set(value):
		target = value
		if tail:
			tail.visible = target and show_tail

## Start opened.
@export var start_opened: bool


@export_group("Connections")

@export var character_label_path: NodePath:
	set(value):
		character_label_path = value
		character_label = get_node_or_null(value) as RichTextLabel

@export var dialogue_label_path: NodePath:
	set(value):
		dialogue_label_path = value
		dialogue_label = get_node_or_null(value) as DialogueLabel

@export var tail_path: NodePath:
	set(value):
		tail_path = value
		tail = get_node_or_null(value) as BalloonTail

var character_label: RichTextLabel
var dialogue_label: DialogueLabel
var tail: BalloonTail:
	set(value):
		tail = value
		if tail:
			tail.visible = target and show_tail


var _current_line: DialogueLine
var _tween: Tween
var _open: bool


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# does not get called when serialized, so force call them here
	character_label_path = character_label_path
	dialogue_label_path = dialogue_label_path
	tail_path = tail_path

	if start_opened:
		if character_label:
			character_label.text = ''
		if dialogue_label:
			dialogue_label.text = ''
		_open = true
	else:
		scale = Vector2.ZERO
		modulate = Color.TRANSPARENT
		hide()

	add_to_group('balloons')


## Types out the dialogue line.
func play_dialogue_line(dialogue_line: DialogueLine) -> void:
	if not is_node_ready():
		await ready
		
	# initialize state
	_current_line = dialogue_line
	_update_character(dialogue_line)
	_update_dialogue_label(dialogue_line)
	
	# type out
	if dialogue_line.text:
		dialogue_label.type_out()
		await dialogue_label.finished_typing
	
	finished.emit()
	get_tree().call_group("balloon_listeners", '_on_balloon_finished', self)


func _update_character(line: DialogueLine) -> void:
	if tail:
		tail.visible = show_tail and line.character != ''

	if line.character:
		if character_label:
			var chara_name := tr(line.character)
			var chara_info := Game.get_character_info(line.character)

			character_label.text = chara_name
			character_label.add_theme_color_override('default_color', chara_info.map_color)

	if character_label:
		character_label.visible = line.character != ''


func _update_dialogue_label(line: DialogueLine) -> void:
	if not dialogue_label:
		return
		
	dialogue_label.hide()
	dialogue_label.dialogue_line = line
	dialogue_label.show()

	if line.text == '':
		return

	# open balloon if not yet open
	if not is_open():
		# force update control, prevents flickering
		# https://github.com/godotengine/godot/issues/20623
		scale = Vector2.ZERO
		modulate = Color.TRANSPARENT
		show()

		# open balloon next frame
		var delayed_open := func():
			pivot_offset = Vector2(0.5, 0.5) * size
			open()
		get_tree().process_frame.connect(delayed_open, CONNECT_ONE_SHOT)

	if centered_text:
		line.text = '[center]%s[/center]' % line.text


## Clears balloon.
func clear() -> void:
	if dialogue_label:
		dialogue_label.hide()
	if character_label:
		character_label.hide()
	if tail:
		tail.hide()


## Returns true if typing.
func is_typing() -> bool:
	return dialogue_label.is_typing


## Skips typing.
func skip_typing() -> void:
	if dialogue_label.is_typing:
		dialogue_label.skip_typing()


## Opens the balloon.
func open(animation_duration := DEFAULT_ANIMATION_DURATION, show_again: bool = false) -> void:
	if _open:
		if show_again:
			await close()
		else:
			return
	
	get_tree().call_group("balloon_listeners", "_on_balloon_opened", self)
	opened.emit()
	if target:
		if tail:
			tail.set_target(target)
	show()
	if animation_duration > 0:
		# with animation
		_force_end_tween()

		_tween = create_tween()
		_tween.set_ease(Tween.EASE_OUT)
		_tween.set_trans(Tween.TRANS_BACK)
		_tween.set_parallel(true)

		_tween.tween_property(self, 'scale', Vector2.ONE, animation_duration)
		_tween.tween_property(self, 'modulate', Color.WHITE, animation_duration)
		await _tween.finished
	else:
		# no animation
		scale = Vector2.ONE
		modulate = Color.WHITE
	
	_open = true


## Closes the balloon.
func close(animation_duration := DEFAULT_ANIMATION_DURATION) -> void:
	if not _open:
		return

	if animation_duration > 0:
		# with animation
		_force_end_tween()

		scale = Vector2.ONE
		modulate = Color.WHITE

		_tween = create_tween()
		_tween.set_ease(Tween.EASE_IN)
		_tween.set_trans(Tween.TRANS_BACK)
		_tween.set_parallel(true)

		_tween.tween_property(self, 'scale', Vector2.ZERO, animation_duration)
		_tween.tween_property(self, 'modulate', Color.TRANSPARENT, animation_duration)
		await _tween.finished
	else:
		# no animation
		scale = Vector2.ZERO
		modulate = Color.TRANSPARENT

	get_tree().call_group("balloon_listeners", "_on_balloon_closed", self)
	closed.emit()
	hide()
	_open = false


func _force_end_tween() -> void:
	if _tween and _tween.is_running():
		_tween.pause()
		_tween.custom_step(9999)
		_tween.kill()
		_tween = null


## Returns true if the balloon is open.
func is_open() -> bool:
	return _open