extends Node


const CharacterImageList := preload('res://events/character_image_list.gd')
const StoryEventScene := preload('res://scenes/dialogue/story_event_scene.gd')
const ImageLibrary := preload('res://events/image_library.gd')


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

enum Mode {
	BUBBLE,
	SLIDES,
	CLASSIC,
}


## The background fill color.
var background_fill: Color = Color.BLACK:
	set(value):
		background_fill = value
		if not is_node_ready():
			await ready
		story_event_scene.background_fill.color = value
		
## The background texture.
var background: Texture = null:
	set(value):
		background = value
		if not is_node_ready():
			await ready
		story_event_scene.background.texture = value

var black_bars: bool:
	set(value):
		black_bars = value
		if not is_node_ready():
			await ready
		if black_bars:
			story_event_scene.show_black_bars()
		else:
			story_event_scene.hide_black_bars()

## A reference to the story event scene.
var story_event_scene: StoryEventScene

## A reference to the image library.
var image_library: ImageLibrary

## The visibility of the UI.
var ui_visible: bool:
	set(value):
		ui_visible = value
		if not is_node_ready():
			await ready
		story_event_scene.dialogue_scene.visible = value




func _ready() -> void:
	assert(story_event_scene, '`story_event_scene` should be set before adding to the scene tree.')
	assert(image_library, '`image_library` should be set before adding to the scene tree.')
	story_event_scene.dialogue_scene.dialogue_line_changed.connect(_on_dialogue_line_changed)


## Returns true if the character is shown.
func is_character_shown(chara: String) -> bool:
	return story_event_scene.has_image(chara)


## Returns the first image of character.
func get_shown_character_image(chara: String) -> Node2D:
	if is_character_shown(chara):
		return story_event_scene.get_character_images(chara)[0]
	return null


## Shows the character at position.
func show_character(chara: String, pos := KEEP_POSITION, tags := KEEP_TAGS, with := '') -> void:
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
	var image_name: String = image_library.get_image_name(chara, tags)

	# if the image is already shown, just update its position
	if shown_image and shown_image.name == image_name:
		if pos != shown_image.position:
			await show_image(shown_image, pos, with)
		return 
	
	if shown_image:
		# if there's already an image shown for the chara, cache it
		var replaced := story_event_scene.cache_and_remove_from_scene(shown_image)
		if replaced:
			push_warning('replacing cached image: %s' % replaced.name)
			replaced.queue_free()

	# try loading cached image
	var image := story_event_scene.retrieve_and_remove_from_cache(image_name)

	if not image:
		image = image_library.create_character_image(chara, tags)

	# add child
	story_event_scene.add_character_image(chara, image)
	await show_image(image, pos, with)


## Hides the character image.
func hide_character(chara: String, with := '') -> void:
	var image := get_shown_character_image(chara)
	if image:
		hide_image(image, with)


## Shows the image.
func show_image(image: Node2D, pos: Vector2, with: String) -> void:
	var tween := create_tween()
	image.show()
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
			image.modulate = Color.WHITE
			image.position = pos
			image.scale = Vector2.ONE
			tween.stop()
			tween = null
	if tween:
		await tween.finished


## Hides the image.
func hide_image(image: Node2D, _with: String) -> void:
	image.hide()



func replace_character(old_chara: String, new_chara: String, exit_with := '', enter_with := '') -> void:
	print('%s exits with %s; %s enters with %s' % [old_chara, exit_with, new_chara, enter_with])


## Applies a transition to the whole scene.
func transition(transition: String) -> void:
	print('transition ', transition)


func norm_to_pos(v: Vector2) -> Vector2:
	return Game.get_viewport_size() * v


func _on_dialogue_line_changed(dialogue_line: DialogueLine) -> void:
	# if character is shown, update it
	if dialogue_line.character and is_character_shown(dialogue_line.character):
		show_character(dialogue_line.character, KEEP_POSITION, dialogue_line.tags)