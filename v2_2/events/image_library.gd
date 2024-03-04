extends CanvasLayer


const CharacterImageList := preload('character_image_list.gd')


## Image to return when no [CharacterImageList] for given character is found.
@export var placeholder: Sprite2D


func _ready():
	hide()


## Returns the image name for the given character and tags.
func get_image_name(character: String, tags := CharacterImageList.DEFAULT_TAGS) -> String:
	return '%s_%s' % [character, '_'.join(tags)]


## Returns a new character image.
func create_character_image(character: String, tags := CharacterImageList.DEFAULT_TAGS) -> Sprite2D:
	for child in get_children():
		var image_list := child as CharacterImageList
		if not image_list:
			continue
		if image_list.name == character:
			var image := image_list.create_image_from_tags(tags)
			image.name = get_image_name(character, tags)
			return image
	return placeholder.duplicate()