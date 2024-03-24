
extends CanvasLayer


signal dialogue_started
signal dialogue_ended
signal dialogue_line_changed(dialogue_line: DialogueLine)

signal balloons_cleared


## A simple class holding all the images.
const ImageLibrary := preload('res://events/image_library.gd')

## A simple class holding a set of images for one character.
const CharacterImageList := preload('res://events/character_image_list.gd')

## The pause menu.
const PauseMenu := preload('dialogue_menu_scene.gd')

## The pause menu scene.
const PauseMenuScene := preload("dialogue_menu_scene.tscn")

## The balloon scene.
const BalloonScene := preload("balloon.tscn")

const LEFT := Vector2(0.25, 1.0)
const RIGHT := Vector2(0.75, 1.0)
const CENTER := Vector2(0.5, 1.0)
const OFFSCREEN_LEFT := Vector2(-0.5, 1.0)
const OFFSCREEN_RIGHT := Vector2(1.5, 1.0)

const KEEP_POSITION := Vector2(9102, 3121)
const KEEP_TAGS: PackedStringArray = []

const DEFAULT_POSITION := CENTER
const DEFAULT_TAGS := CharacterImageList.DEFAULT_TAGS
const DEFAULT_TRANSITION := 'fade'


@export var skip_action: StringName = 'ui_cancel'
@export var continue_action: StringName = 'ui_accept'
@export var balloon_target_offset: Vector2 = Vector2(400, -300)
@export var balloon_v_spacing: float = 20

## The color of the background fill.
var background_fill: Color = Color("#0e0e0e"): # mococo
	set(value):
		background_fill = value
		if not is_node_ready():
			await ready
		_background_fill.color = value

## The background texture.
var background: Texture = null:
	set(value):
		background = value
		if not is_node_ready():
			await ready
		_background_texture.texture = value

## The visibility of the UI.
var ui_visible: bool:
	set(value):
		ui_visible = value
		if not is_node_ready():
			await ready
		# TODO a different method of hiding
		# because visible, modulate are used for animation
		_dialogue_box.visible = value

## Whether to wait for the next input.
var wait_for_input: bool

## Whether to wait for the response to be selected.
var wait_for_response: bool

## An array containing all the open balloons.
var open_balloons: Array[Balloon]

var _resource: DialogueResource

var _dialogue_line: DialogueLine:
	set(value):
		if not value:
			dialogue_ended.emit()
			queue_free()
			return

		_dialogue_line = value
		update_dialogue()
		dialogue_line_changed.emit(_dialogue_line)
		
var _temp_game_states: Array

var _black_bars_tween: Tween
var _character_image_map: Dictionary = {}



@onready var _cached_images: Node2D = %CachedImages
@onready var _background_fill: ColorRect = %BackgroundFill
@onready var _background_texture: TextureRect = %BackgroundTexture
@onready var _black_bars: Array[ColorRect] = [%TopBar, %BottomBar]
@onready var _characters: Node2D = %Characters
@onready var _dialogue_box: Balloon = %ClassicDialogueBox
@onready var _responses_menu: DialogueResponsesMenu = %ResponsesMenu


func _ready() -> void:
	add_to_group("balloon_listeners")

	_responses_menu.response_selected.connect(
		func(response: DialogueResponse):
			skip_typing()
			next(response.next_id)
	)

	DialogueManager.mutated.connect(
		func(_mutation: Dictionary) -> void:
			wait_for_input = false
	)

	test.call_deferred()


func test() -> void:
	_character_image_map.nnivx = [$Characters/nnivx] as Array[Node2D]
	_character_image_map.Nathan = [$Characters/Nathan] as Array[Node2D]
	await get_tree().create_timer(1).timeout
	var resource := preload("data/test.dialogue")
	start(resource, 'start')


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		open_pause_menu()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if should_skip_typing(event):
		get_viewport().set_input_as_handled()
		skip_typing()
		return

	if not wait_for_input or wait_for_response:
		return

	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(_dialogue_line.next_id)

	elif continue_action and event.is_action_pressed(continue_action) and get_viewport().gui_get_focus_owner() == self:
		DialogueEvents.next_requested.emit(self)


## Starts the dialogue.
func start(dialogue_resource: DialogueResource, title: String, extra_game_states := []) -> void:
	_temp_game_states = [self] + extra_game_states
	wait_for_input = false
	wait_for_response = false
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
	# setup initial state
	close_responses_menu()
	wait_for_input = false

	# clear on balloons on title start
	if _resource.titles.find_key(_dialogue_line.id):
		if close_balloons(true):
			await balloons_cleared

	# play dialogue line
	_dialogue_box.clear()
	var balloon := await _get_balloon_for(_dialogue_line)
	balloon.play_dialogue_line(_dialogue_line)


func _get_balloon_for(line: DialogueLine) -> Balloon:
	# find target character
	var target := get_shown_character_image(line.character)
	if target:
		var head := target.find_child("Head")
		if head:
			target = head
	
	if line.character and target and target.visible:
		var balloon := BalloonScene.instantiate()
		balloon.target = target
		%BalloonArea.add_child(balloon)
		if will_overflow(balloon) and close_balloons(true):
			await balloons_cleared
		return balloon
	else:
		#_dialogue_box.character_label.set("theme_override_colors/font_outline_color")
		#Util.bb_big_caps(_dialogue_box.dialogue_label
			# # if no character label, do "Character: Text" (if we have text to show)
			# line.text = "[outline_size=%d][outline_color=#%s][color=#%s]%s:[/color][/outline_color][/outline_size] %s" % [
			# 	12,
			# 	chara_info.map_color.darkened(0.6).to_html(),
			# 	chara_info.map_color.to_html(),
			# 	chara_name,
			# 	line.text
			# ]

		return _dialogue_box

	
## Returns true if we should skip typing.
func should_skip_typing(event: InputEvent) -> bool:
	var mouse_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
	var skip_pressed: bool = skip_action and event.is_action_pressed(skip_action)
	return (mouse_clicked or skip_pressed) and is_balloon_typing()


## Returns true if there's a balloon typing.
func is_balloon_typing() -> bool:
	for balloon: Balloon in get_tree().get_nodes_in_group('balloons'):
		if balloon.is_typing():
			return true
	return false


## Skips all currently typing balloons.
func skip_typing() -> void:
	get_tree().call_group('balloons', 'skip_typing')


## Opens the responses menu.
func open_responses_menu(responses: Array[DialogueResponse]) -> void:
	if responses.is_empty():
		return
	_responses_menu.responses = responses
	wait_for_response = true
	_responses_menu.show()


## Closes the responses menu.
func close_responses_menu() -> void:
	wait_for_response = false
	_responses_menu.hide()


## Shows the dialogue box.
func show_dialogue_box() -> void:
	_dialogue_box.show()


## Hides the dialogue box.
func hide_dialogue_box() -> void:
	_dialogue_box.hide()


## Toggles the dialogue box.
func toggle_dialogue_box() -> void:
	if _dialogue_box.visible:
		hide_dialogue_box()
	else:
		show_dialogue_box()


## Closes all the balloons.
func close_balloons(free: bool = false) -> bool:
	if open_balloons.is_empty():
		return false

	for balloon: Balloon in open_balloons:
		if free:
			balloon.closed.connect(balloon.queue_free, CONNECT_ONE_SHOT)
		balloon.close()
	return true


## Returns true if adding this balloon will overflow the container.
func will_overflow(balloon: Balloon) -> bool:
	return not get_balloon_area().has_point(find_free_balloon_position(balloon, balloon.target, balloon_target_offset, balloon_v_spacing))


## Returns the next valid position for balloon.
func find_free_balloon_position(balloon: Balloon, target: Node2D, target_offset: Vector2, v_spacing: float) -> Vector2:
	var tpos := target.global_position

	# orient balloon to proper position
	if tpos.x <= Game.get_viewport_size().x/2:
		tpos.x += target_offset.x
	else:
		# otherwise put it to the left
		tpos.x -= target_offset.x

	# center balloon to the target position
	tpos.x -= balloon.size.x/2
	
	# position vertically
	if open_balloons.is_empty():
		tpos.y += target_offset.y
	else:
		tpos.y = open_balloons[-1].global_position.y + open_balloons[-1].size.y + v_spacing
		
	# clamp tpos to the container region
	var area := get_balloon_area()
	tpos.x = clamp(tpos.x, area.position.x, area.position.x + area.size.x)
	if tpos.y < area.position.y:
		tpos.y = area.position.y

	return tpos


## Returns the balloon area.
func get_balloon_area() -> Rect2:
	return %BalloonArea.get_global_rect()


## Sets the balloon area.
func set_balloon_area(rect: Rect2) -> void:
	%BalloonArea.global_position = rect.position
	%BalloonArea.size = rect.size


## Shows the character image.
func show_character(chara: String, pos := KEEP_POSITION, tags := KEEP_TAGS, transition := DEFAULT_TRANSITION) -> void:
	pass


## Hides the character image.
func hide_character(chara: String, transition := DEFAULT_TRANSITION) -> void:
	pass


## Returns true if the character is shown.
func is_character_shown(chara: String) -> bool:
	return has_image(chara)


## Returns the first shown image of the character.
func get_shown_character_image(chara: String) -> Node2D:
	if has_image(chara):
		return get_character_images(chara)[0]
	return null


## Adds an image for a character.
func add_character_image(chara: String, image: Node2D) -> void:
	# add to array, creating array if needed
	if chara not in _character_image_map:
		_character_image_map[chara] = [] as Array[Node2D]
	_character_image_map[chara].append(image)

	# add to scene
	_characters.add_child(image)


## Removes an image for a character.
func remove_character_image(chara: String, image: Node2D) -> void:
	if chara not in _character_image_map:
		return

	# remove from array, erasing array if needed
	_character_image_map[chara].erase(image)
	if _character_image_map[chara].is_empty():
		_character_image_map.erase(chara)

	# remove from scene
	_characters.remove_child(image)


## Returns `true` if character has an image shown.
func has_image(chara: String) -> bool:
	return chara in _character_image_map


## Returns a list of all the character images.
func get_character_images(chara: String) -> Array[Node2D]:
	return _character_image_map[chara]
	

## Caches the image. Returns previously cached image of the same name if any.
func cache_and_remove_from_scene(image: Node2D) -> Node2D:
	# find and replace existing entry
	for c in _cached_images.get_children():
		if c.name == image.name:
			c.replace_by(image)
			return c
	
	# reparent to cached_images
	if image.get_parent():
		image.get_parent().remove_child(image)
	_cached_images.add_child(image)
	return null


## Returns the cached image or null if not found.
func retrieve_and_remove_from_cache(image_name: String) -> Node2D:
	var image := _cached_images.get_node_or_null(image_name)
	if image:
		_cached_images.remove_child(image)
	return image


## Shows the black bars.
func show_black_bars(duration := 0.0, height: Variant = get_default_black_bars_height()) -> void:
	var pixel_height: int
	
	# get the actual pixel height
	if height is int:
		pixel_height = height
	elif height is float:
		pixel_height = black_bars_float_to_pixels(height)
	else:
		push_error('expected int or float for height')
		return

	%BlackBars.show() # iffy, but this will do

	# stop ongoing progress
	if _black_bars_tween:
		duration = _black_bars_tween.get_total_elapsed_time()
		_black_bars_tween.kill()

	# setup tween
	var tween := _create_black_bars_tween(pixel_height, duration)
	tween.finished.connect(func():
		_black_bars_tween = null
	)
	
	_black_bars_tween = tween
	

## Hides the black bars.
func hide_black_bars(duration := 0.0) -> void:
	# stop ongoing progress
	if _black_bars_tween:
		duration = _black_bars_tween.get_total_elapsed_time()
		_black_bars_tween.kill()

	# setup tween
	var tween := _create_black_bars_tween(0, duration)
	tween.finished.connect(func():
		_black_bars_tween = null
		%BlackBars.hide() # iffy, but this will do
	)
	
	_black_bars_tween = tween


func _create_black_bars_tween(height: int, duration: float) -> Tween:
	var tween := create_tween()
	tween.parallel().tween_property(_black_bars[0], 'custom_minimum_size', Vector2(0, height), duration)
	tween.parallel().tween_property(_black_bars[1], 'custom_minimum_size', Vector2(0, height), duration)
	return tween


## Returns the default black bars height.
func get_default_black_bars_height() -> int:
	return black_bars_float_to_pixels(0.1)


## Returns float height value to pixels.
func black_bars_float_to_pixels(height: float) -> int:
	return roundi(ProjectSettings.get_setting('display/window/size/height')/2 * height)


## Opens the pause menu.
func open_pause_menu() -> void:
	var pause_menu := PauseMenuScene.instantiate()
	add_child(pause_menu)


## Closes the pause menu.
func close_pause_menu() -> void:
	for child in get_children():
		if child is PauseMenu:
			child.close()


func _on_balloon_opened(balloon: Balloon) -> void:
	if balloon == _dialogue_box:
		return

	balloon.global_position = find_free_balloon_position(balloon, balloon.target, balloon_target_offset, balloon_v_spacing)
	open_balloons.append(balloon)
	

func _on_balloon_closed(balloon: Balloon) -> void:
	if balloon == _dialogue_box:
		return
	open_balloons.erase(balloon)
	if open_balloons.is_empty():
		balloons_cleared.emit()


func _on_balloon_finished(_balloon: Balloon) -> void:
	if _dialogue_line.responses:
		open_responses_menu(_dialogue_line.responses)
	elif _dialogue_line.time:
		var time: float
		if _dialogue_line.time.is_valid_float():
			time = _dialogue_line.time.to_float()
		else:
			time = _dialogue_line.text.length() * 0.2

		await get_tree().create_timer(time).timeout
		next(_dialogue_line.next_id)
	else:
		wait_for_input = true