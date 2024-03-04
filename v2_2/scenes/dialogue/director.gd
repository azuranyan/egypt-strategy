extends Node


const CharacterImageList := preload('res://events/character_image_list.gd')

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


var image_registry := {}

var ui_visible: bool

var auto_show_character: bool

var background: String:
	set(value):
		background = value
		print('background changed to ', value)


var shown_images: Array[Node2D] = []

var cached_images: Node2D

func _ready() -> void:
	cached_images = Node2D.new()
	cached_images.name = 'CachedImages'
	cached_images.hide()
	add_child(cached_images)

	DialogueEvents.queue_ended.connect(_cleanup)


func _cleanup(cache_images := true) -> void:
	if cache_images:
		for image in shown_images:
			cache_and_remove_from_scene(image)
	else:
		for image in shown_images:
			image.queue_free()


## Returns true if the character is shown.
func is_character_shown(chara: String) -> bool:
	return get_shown_character_image(chara) != null


## Returns the first image of character.
func get_shown_character_image(chara: String) -> Node2D:
	for c in shown_images:
		if c.name.begins_with(chara + '_'):
			return c
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
			tags = shown_image.get_meta('tags')
		else:
			tags = DEFAULT_TAGS
	elif not tags is PackedStringArray:
		tags = [tags]

	# this was working last time, now it can't fucking infer again
	var image_name: String = ImageLibrary.get_image_name(chara, tags)

	# if the image is already shown, just update its position
	if shown_image and shown_image.name == image_name:
		if pos != shown_image.position:
			await show_image(shown_image, pos, with)
		return 
	
	if shown_image:
		# if there's already an image shown for the chara, cache it
		var replaced := cache_and_remove_from_scene(shown_image)
		if replaced:
			push_warning('replacing cached image: %s' % replaced.name)
			replaced.queue_free()

		# then erase it from shown characters
		shown_images.erase(shown_image)
	
	# try loading cached image
	var image := retrieve_and_remove_from_cache(image_name)

	if not image:
		image = ImageLibrary.create_character_image(chara, tags)

	# add child
	add_child(image)
	shown_images.append(image)
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


## Caches the image. Returns replaced image if any.
func cache_and_remove_from_scene(image: Node2D) -> Node2D:
	for c in cached_images.get_children():
		if c.name == image.name:
			c.replace_by(image)
			return c
	
	# we do it this way so we dont get orphaned nodes
	if image.get_parent():
		image.get_parent().remove_child(image)
	cached_images.add_child(image)
	return null


## Returns the cached image or null if not found.
func retrieve_and_remove_from_cache(image_name: String) -> Node2D:
	var image := cached_images.get_node_or_null(image_name)
	if image:
		cached_images.remove_child(image)
	return image


func replace_character(old_chara: String, new_chara: String, exit_with := '', enter_with := '') -> void:
	print('%s exits with %s; %s enters with %s' % [old_chara, exit_with, new_chara, enter_with])


## Applies a transition to the whole scene.
func transition(transition: String) -> void:
	print('transition ', transition)


func norm_to_pos(v: Vector2) -> Vector2:
	return Game.get_viewport_size() * v

