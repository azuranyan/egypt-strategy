class_name CharacterInfo
extends Resource

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


func _to_string() -> String:
	return name
