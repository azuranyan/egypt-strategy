@tool
extends CanvasLayer


signal dialogue_started
signal dialogue_finished
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

const FADE_TO_BLACK := 'fade_to_black'
const FADE_FROM_BLACK := 'fade_from_black'
const FADE_IN := 'fade_in'
const FADE_OUT := 'fade_out'
const SLIDE_TO_LEFT := 'slide_to_left'
const SLIDE_TO_RIGHT := 'slide_to_right'
const SLIDE_FROM_LEFT := 'slide_from_left'
const SLIDE_FROM_RIGHT := 'slide_from_right'
const SLIDE_TO := 'slide_to'
const SCALE_IN := 'scale_in'
const SCALE_OUT := 'scale_out'

const LEFT := Vector2(0.25, 1.0)
const RIGHT := Vector2(0.75, 1.0)
const CENTER := Vector2(0.5, 1.0)
const OFFSCREEN_LEFT := Vector2(-0.5, 1.0)
const OFFSCREEN_RIGHT := Vector2(1.5, 1.0)

const KEEP_POSITION := Vector2(9102, 3121)
const KEEP_TAGS: PackedStringArray = []

const DEFAULT_POSITION := CENTER
const DEFAULT_TAGS := CharacterImageList.DEFAULT_TAGS
const DEFAULT_TRANSITION := FADE_IN


## The action used for skipping dialogue.
@export var skip_action: StringName = 'ui_cancel'

## The action used for continuing dialogue. Pressing with LMB also continues the action.
@export var continue_action: StringName = 'ui_accept'

## The action used for toggling ui.
@export var toggle_ui_action: StringName

## The offset of where the balloons should be spawned relative to the target.
@export var balloon_target_offset: Vector2 = Vector2(400, -300)

## The vertical spacing between the balloons.
@export var balloon_v_spacing: float = 20

## Auto-close balloon flags.
@export var auto_close := default_auto_close_flags()

## The image library.
##
## The image library contains all the character images and expressions.
var image_library: ImageLibrary

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

## Whether the ui should be visible or not.
var ui_visible: bool:
	set(value):
		ui_visible = value
		if not is_node_ready():
			await ready
			
		$UI.visible = value
		$Overlay.visible = value

## Whether to wait for the next input.
var wait_for_input: bool

## Whether to wait for the response to be selected.
var wait_for_response: bool

## An array containing all the open balloons.
var open_balloons: Array[Balloon]

## Determines whether to reuse the existing balloon or spawn a new one when the same
## character speaks a new line of dialogue.
##
## If set to `true`, the existing balloon will be reused for subsequent dialogue lines
## from the same character. If set to `false`, a new balloon will be spawned for each
## new line of dialogue.
var reuse_balloons: bool

var _resource: DialogueResource
var _temp_game_states: Array

var _dialogue_line: DialogueLine:
	set(value):
		if not value:
			dialogue_finished.emit()
			queue_free()
			return

		_dialogue_line = value
		update_dialogue()
		dialogue_line_changed.emit(_dialogue_line)
		
var _black_bars_tween: Tween
var _character_image_map: Dictionary = {}

var _previous_speaker: String
var _previous_speaker_on_scene: bool


@onready var _cached_images: Node2D = %CachedImages
@onready var _background_fill: ColorRect = %BackgroundFill
@onready var _background_texture: TextureRect = %BackgroundTexture
@onready var _black_bars: Array[ColorRect] = [%TopBar, %BottomBar]
@onready var _characters: Node2D = %Characters
@onready var _dialogue_box: Balloon = %ClassicDialogueBox
@onready var _responses_menu: DialogueResponsesMenu = %ResponsesMenu


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process_input(false)
		set_process_unhandled_input(false)
		return
		
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
		next(_dialogue_line.next_id)


func default_auto_close_flags() -> Dictionary:
	return {
		new_chapter = true,
		new_scene = true,
		solo = false,
		out_of_context = true,
		narration = false,
		full = true,
	}


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

	if is_new_chapter(_dialogue_line.id):
		if auto_close.new_chapter:
			await clear_balloons()

	if auto_close.out_of_context and not _previous_speaker_on_scene and _previous_speaker != _dialogue_line.character:
		await clear_balloons()

	if _dialogue_line.character:
		# update tags if they exist
		if is_character_shown(_dialogue_line.character):
			show_character(_dialogue_line.character, KEEP_POSITION, _dialogue_line.tags)

		_previous_speaker = _dialogue_line.character
		_previous_speaker_on_scene = is_character_shown(_dialogue_line.character)
	else:
		if auto_close.narration:
			await clear_balloons()

	# play dialogue line
	_dialogue_box.clear()
	var balloon := await _get_balloon_for(_dialogue_line)
	balloon.play_dialogue_line(_dialogue_line)


## Returns true if the given id is a new chapter.
func is_new_chapter(id: String) -> bool:
	return _resource.titles.find_key(id) != null


func _get_balloon_for(line: DialogueLine) -> Balloon:
	# find target character
	var target := _get_balloon_target(line.character)

	if line.character and target[0] and target[0].visible:
		if auto_close.solo and not open_balloons.is_empty() and open_balloons[-1]._current_line.character == line.character:
			return open_balloons[-1]
		
		var balloon := BalloonScene.instantiate()
		if target[0]:
			balloon.target = target[1]
			balloon.z_index = target[0].z_index + 1
		else:
			balloon.target = null
			balloon.z_index = 0
		%BalloonArea.add_child(balloon)

		if auto_close.full and will_overflow(balloon):
			await clear_balloons()
		return balloon
	else:
		return _dialogue_box


func _get_balloon_target(chara: String) -> Array[Node2D]:
	var main_target := get_shown_character_image(chara)
	var sub_target := main_target

	if main_target:
		var head := main_target.find_child("Head", true, false) # false because it may not be owned
		if head:
			sub_target = head
	return [main_target, sub_target]

	
## Returns true if we should skip typing.
func should_skip_typing(event: InputEvent) -> bool:
	var mouse_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
	var skip_pressed: bool = skip_action and event.is_action_pressed(skip_action)
	return (mouse_clicked or skip_pressed) and is_balloon_typing()


## Returns true if there's a balloon still typing.
func is_balloon_typing() -> bool:
	for balloon: Balloon in get_tree().get_nodes_in_group('balloons'):
		if balloon.is_typing():
			return true
	return false


## Skips all currently typing balloons.
func skip_typing() -> void:
	# balloons should check if they're actually typing so we can do this
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


## Clears the balloons.
func clear_balloons() -> void:
	if close_balloons(true):
		await balloons_cleared


## Closes all the balloons.
func close_balloons(free: bool = false) -> bool:
	if open_balloons.is_empty():
		return false

	for balloon: Balloon in open_balloons:
		if free:
			balloon.closed.connect(balloon.queue_free, CONNECT_ONE_SHOT)
		balloon.close()
	return true


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


## Returns true if adding this balloon will overflow the container.
func will_overflow(balloon: Balloon) -> bool:
	return not get_balloon_area().has_point(find_free_balloon_position(balloon, balloon.target, balloon_target_offset, balloon_v_spacing))


## Returns the balloon area.
func get_balloon_area() -> Rect2:
	return %BalloonArea.get_global_rect()


## Sets the balloon area.
func set_balloon_area(rect: Rect2) -> void:
	%BalloonArea.global_position = rect.position
	%BalloonArea.size = rect.size


## Shows the character image.
func show_character(chara: String, pos := KEEP_POSITION, tags := KEEP_TAGS, transition := DEFAULT_TRANSITION) -> void:
	# check if there's already a shown image
	var shown_image := get_shown_character_image(chara)
	
	if pos == KEEP_POSITION:
		if shown_image:
			pos = shown_image.position
		else:
			pos = DEFAULT_POSITION

	if tags == KEEP_TAGS:
		if shown_image:
			if not shown_image.has_meta('tags'):
				push_error('`tags` not found in image metadata: %s' % shown_image.name)
			tags = shown_image.get_meta('tags', DEFAULT_TAGS)
		else:
			tags = DEFAULT_TAGS
	elif not tags is PackedStringArray:
		tags = [tags]

	# this was working last time, now it can't fucking infer again
	var image_name := image_library.get_image_name(chara, tags)

	# if the image is already shown, just update its position
	if shown_image and shown_image.name == image_name:
		if pos != shown_image.position:
			await show_image(shown_image, pos, transition)
		return 

	if shown_image:
		# if there's already an image shown for the chara, cache it
		var replaced := cache_and_remove_from_scene(shown_image)
		if replaced:
			push_warning('replacing cached image: %s' % replaced.name)
			replaced.queue_free()

	# try loading cached image
	var image := retrieve_and_remove_from_cache(image_name)

	if not image:
		image = image_library.create_character_image(chara, tags)

	image.z_index = 'foreground' in tags

	# add child
	add_character_image(chara, image)
	await show_image(image, pos, transition)


## Hides the character image.
func hide_character(chara: String, transition := DEFAULT_TRANSITION) -> void:
	var image := get_shown_character_image(chara)
	if image:
		hide_image(image, transition)


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
	if not has_image(chara):
		_character_image_map[chara] = [] as Array[Node2D]
	_character_image_map[chara].append(image)

	# add to scene
	_characters.add_child(image)


## Removes an image for a character.
func remove_character_image(chara: String, image: Node2D) -> void:
	if not has_image(chara):
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


## Shows an image to the scene.
func show_image(image: Node2D, pos: Vector2, with: String) -> void:
	image.modulate = Color.WHITE
	image.scale = Vector2.ONE
	image.position = pos
	image.show()

	var tween := create_tween()
	match with:
		FADE_TO_BLACK:
			image.modulate = Color.WHITE
			tween.tween_property(image, 'modulate', Color(0.0, 0.0, 0.0, 0.0), 0.4)
		FADE_FROM_BLACK:
			image.modulate = Color(0.0, 0.0, 0.0, 0.0)
			tween.tween_property(image, 'modulate', Color.WHITE, 0.4)
		FADE_IN:
			image.modulate = Color.TRANSPARENT
			tween.tween_property(image, 'modulate', Color.WHITE, 0.4)
		FADE_OUT:
			image.modulate = Color.WHITE
			tween.tween_property(image, 'modulate', Color.TRANSPARENT, 0.4)
		SLIDE_FROM_LEFT:
			image.position = norm_to_pos(OFFSCREEN_LEFT)
			tween.tween_property(image, 'position', pos, 0.4)
		SLIDE_FROM_RIGHT:
			image.position = norm_to_pos(OFFSCREEN_RIGHT)
			tween.tween_property(image, 'position', pos, 0.4)
		SLIDE_TO_LEFT:
			image.position = pos
			tween.tween_property(image, 'position', OFFSCREEN_LEFT, 0.4)
		SLIDE_TO_RIGHT:
			image.position = pos
			tween.tween_property(image, 'position', OFFSCREEN_RIGHT, 0.4)
		SLIDE_TO:
			tween.tween_property(image, 'position', pos, 0.4)
		SCALE_IN:
			image.scale = Vector2.ZERO
			tween.tween_property(image, 'scale', Vector2.ONE, 0.4)
		SCALE_OUT:
			image.scale = Vector2.ONE
			tween.tween_property(image, 'scale', Vector2.ZERO, 0.4)
		_:
			tween.stop()
			tween = null
	if tween:
		await tween.finished


## Hides the image from the scene.
func hide_image(image: Node2D, _with: String) -> void:
	image.hide()


## Changes the scene.
func change_scene(scene_info: Dictionary, transition := DEFAULT_TRANSITION, duration := 1.0) -> void:
	if auto_close.new_scene:
		await clear_balloons()

	# TODO change scenes


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

	# stop ongoing progress
	if _black_bars_tween:
		duration = _black_bars_tween.get_total_elapsed_time()
		_black_bars_tween.kill()
	else:
		_black_bars[0].custom_minimum_size = Vector2.ZERO
		_black_bars[1].custom_minimum_size = Vector2.ZERO

	%BlackBars.show() # iffy, but this will do

	# setup tween
	var tween := _create_black_bars_tween(pixel_height, duration)
	tween.finished.connect(func():
		_black_bars_tween = null
	)
	
	_black_bars_tween = tween
	

## Hides the black bars.
func hide_black_bars(duration := 0.0) -> void:
	if not %BlackBars.visible:
		return

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
	return roundi(ProjectSettings.get_setting('display/window/size/viewport_height')/2 * height)


## Returns the screen position from given normalized value.
func norm_to_pos(v: Vector2) -> Vector2:
	return Game.get_viewport_size() * v


## Opens the pause menu.
func open_pause_menu() -> void:
	var pause_menu := PauseMenuScene.instantiate()
	$Overlay.add_child(pause_menu)


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