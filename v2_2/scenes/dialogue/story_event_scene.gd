extends CanvasLayer


@export_group("Connections")

## The node containing the cached images.
@export var cached_images: Node2D 
 
## The background fill node.
@export var background_fill: ColorRect

## The background node.
@export var background: TextureRect

## The top and black bars.
@export var black_bars: Array[ColorRect]

## The node containing the character images.
@export var character_images: Node2D

## The dialogue scene.
@export var dialogue_scene: DialogueScene


var _character_image_map: Dictionary = {}


## Adds an image for a character.
func add_character_image(chara: String, image: Node2D) -> void:
	# add to array, creating array if needed
	if chara not in _character_image_map:
		_character_image_map[chara] = [] as Array[Node2D]
	_character_image_map[chara].append(image)

	# add to scene
	character_images.add_child(image)


## Removes an image for a character.
func remove_character_image(chara: String, image: Node2D) -> void:
	if chara not in _character_image_map:
		return

	# remove from array, erasing array if needed
	_character_image_map[chara].erase(image)
	if _character_image_map[chara].is_empty():
		_character_image_map.erase(chara)

	# remove from scene
	character_images.remove_child(image)


## Returns `true` if character has an image shown.
func has_image(chara: String) -> bool:
	return chara in _character_image_map


## Returns the first image of character.
func get_character_images(chara: String) -> Array[Node2D]:
	return _character_image_map[chara]
	

## Shows the black bars.
func show_black_bars(height: Variant = null, duration := 0.0) -> void:
	%TopBar.show()
	%BottomBar.show()
	var pixel_height: int
	if height is int:
		pixel_height = height
	elif height is float:
		pixel_height = roundi(ProjectSettings.get_setting('display/window/size/height')/2 * height)
	else:
		pixel_height = roundi(ProjectSettings.get_setting('display/window/size/height')/2 * 0.1)

	if duration <= 0: 
		%TopBar.custom_minimum_size.y = pixel_height
		%BottomBar.custom_minimum_size.y = pixel_height
	else:
		var tween := create_tween()
		tween.tween_property(%TopBar, 'custom_minimum_size', Vector2(0, pixel_height), duration)
		tween.tween_property(%BottomBar, 'custom_minimum_size', Vector2(0, pixel_height), duration)



## Hides the black bars.
func hide_black_bars(duration := 0.0) -> void:
	if duration <= 0: 
		%TopBar.custom_minimum_size.y = 0
		%BottomBar.custom_minimum_size.y = 0
	else:
		var tween := create_tween()
		tween.tween_property(%TopBar, 'custom_minimum_size', Vector2.ZERO, duration)
		tween.tween_property(%BottomBar, 'custom_minimum_size', Vector2.ZERO, duration)
		await tween.finished
	%TopBar.hide()
	%BottomBar.hide()


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

