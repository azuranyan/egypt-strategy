extends Node2D


const DEFAULT_TAGS: PackedStringArray = ['default']


## Default image to use if no matching tags were found.
@export var default: Sprite2D

@export_group("Tagged Images")

## List of tagged images.
@export var images: Array[Sprite2D]


## Returns the actual source sprite with the given tags.
func get_image_by_tags(tags: PackedStringArray) -> Sprite2D:
	if tags == DEFAULT_TAGS:
		return default
	
	for image in images:
		if not image.has_meta('tags'):
			push_warning('image %s has no tags' % image)
			continue
		var image_tags: PackedStringArray = image.get_meta('tags')
		if tags == image_tags:
			return image
		
	return default


## Returns a new image from given tags.
func create_image_from_tags(tags: PackedStringArray) -> Sprite2D:
	var source := get_image_by_tags(tags)

	var image := source.duplicate()
	image.position = source.position
	#image.offset = source.position/source.scale
	image.visible = true

	# add dummy parent for proper scaling
	var parent := Node2D.new()
	parent.add_child(image)
	return parent


	