extends CanvasLayer


const CharacterImageList := preload('res://events/character_image_list.gd')

const KEEP_POSITION := Vector2(9102, 3121)

enum {
	FADE_TO_BLACK,
	FADE_FROM_BLACK,
	FADE_IN,
	FADE_OUT,
	SLIDE_FROM_LEFT,
	SLIDE_FROM_RIGHT,
	SCALE_IN,
	SCALE_OUT,
}


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


## Returns the first image of character.
func get_shown_character_image(chara: String) -> Sprite2D:
	for c in shown_images:
		if c.name.begins_with(chara + '_'):
			return c
	return null


## Shows the character at position.
func show_character(chara: String, pos: Vector2, tags: Variant = CharacterImageList.DEFAULT_TAGS, with := '') -> void:
	if not tags is PackedStringArray:
		tags = [tags]

	var image_name := ImageLibrary.get_image_name(chara, tags)
	var shown_image := get_shown_character_image(chara)

	if pos == KEEP_POSITION:
		pos = shown_image.position if shown_image else Vector2.ZERO

	# if the image is already shown, just update its position
	if shown_image and shown_image.name == image_name:
		show_image(shown_image, pos, with)
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
	show_image(image, pos, with)


## Hides the character image.
func hide_character(chara: String, with := '') -> void:
	var image := get_shown_character_image(chara)
	if image:
		hide_image(image, with)


## Shows the image.
func show_image(image: Node2D, pos: Vector2, _with: String) -> void:
	image.position = pos
	image.show()


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
func retrieve_and_remove_from_cache(image_name: String) -> Sprite2D:
	var image := cached_images.get_node_or_null(image_name)
	if image:
		cached_images.remove_child(image)
	return image


func replace_character(old_chara: String, new_chara: String, exit_with := '', enter_with := '') -> void:
	print('%s exits with %s; %s enters with %s' % [old_chara, exit_with, new_chara, enter_with])


## Applies a transition to the whole scene.
func transition(transition: String) -> void:
	print('transition ', transition)

   
func str_to_pos(s: String) -> Vector2:
	const STRVAL := {
		left = Vector2(0.25, 1.0),
		right = Vector2(0.75, 1.0),
		center = Vector2(0.5, 1.0),
		offscreen_left = Vector2(-0.5, 1.0),
		offscreen_right = Vector2(1.5, 1.0),
	}
	return norm_to_pos(STRVAL.get(s, Vector2(0.5, 1.0)))


func norm_to_pos(v: Vector2) -> Vector2:
	return Game.get_viewport_size() * v

