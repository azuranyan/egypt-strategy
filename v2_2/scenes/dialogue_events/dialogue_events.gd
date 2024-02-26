class_name DialogueEvents
extends Node


signal new_event_unlocked(event_id: StringName)


static func instance() -> DialogueEvents:
	return load("res://scenes/dialogue_events/dialogue_events.gd").new() # stub


## Returns true if this character has character events.
func has_character_events(chara: CharacterInfo) -> bool:
	return true
	

## Returns true if there are new character events.
func has_new_character_event(chara: CharacterInfo) -> bool:
	return false


## Plays a character event. Plays the latest character event by default.
func play_character_event(chara: CharacterInfo, index := -1) -> void:
	pass


func play_event(event_id: StringName) -> void:
	pass