extends Resource
class_name Chara

## Proper name of the gods.
@export var name: String

## Flavor text from the game doc, unused.
@export_enum("F", "M") var gender: String = "F"

## Full avatar name.
@export var avatar: String

## Flavor text.
@export var title: String

## Will be set to actual colors later.
@export var map_color: Color

## The image portrait.
@export var portrait: Texture2D

# TODO animation

## Returns just the avatar name if Avatar or Princess.
func get_avatar_name() -> String:
	var split := avatar.rsplit(" ", true, 1)
	if split[0] == 'Avatar':# or split[0] == 'Priestess':
		return split[-1]
	return avatar
