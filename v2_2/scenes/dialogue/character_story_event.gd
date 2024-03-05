class_name CharacterStoryEvent
extends StoryEvent


## The id of the character associated with this story event.[br]
##
## Note that we only ever check for basic requirements like unit bond and player ownership.
## If `chara_id` is the player's hero unit, make sure that their bond is only increased
## when appropriate (story unlocks).
@export var chara_id: StringName

## The index of the story event, representing when they are available depending on the bond level.
@export_enum('Story Event 1', 'Story Event 2', 'Story Event 3') var event_index: int


func check_requirements(seen_events: Array[StringName]) -> bool:
	return check_prerequisite_event(seen_events) and super.check_requirements(seen_events)


func check_conditions() -> bool:
	var unit := Game.get_unit_by_chara_id(chara_id)

	return (unit != null # unit must exist
		and unit.is_player_owned() # be owned by player
		and unit.get_bond() > event_index # has enough bond
		and super.check_conditions()) # has special conditions fulfilled


func check_prerequisite_event(seen_events: Array[StringName]) -> bool:
	if event_index == 0:
		return true
	else:
		for id in seen_events:
			var event := Dialogue.instance().get_event(id) as CharacterStoryEvent
			if not event:
				continue
			if event.chara_id == chara_id and event.event_index == event_index - 1:
				return true

		return false
		