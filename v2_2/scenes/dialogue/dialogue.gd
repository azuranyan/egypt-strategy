class_name Dialogue
extends Node


static func instance() -> Dialogue:
	return load("res://scenes/dialogue/dialogue.gd").new() # stub


## Returns true if this character has character events.
func has_character_events(chara: CharacterInfo) -> bool:
	return true
	

## Returns true if there are new character events.
func has_new_character_event(chara: CharacterInfo) -> bool:
	return false


## Returns the character event. Returns the latest event by default.
func get_character_event(chara: CharacterInfo, index := -1) -> StringName:
	return ''


func play_event(event_id: StringName) -> void:
	pass
