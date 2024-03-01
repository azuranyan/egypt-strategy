@tool
class_name EmpireNode
extends Node
## Serves as a marker for creating empires on the editor.


## The type of the empire.
@export var type: Empire.Type = Empire.Type.RANDOM

## Preset leader.
@export var leader_id: StringName:
	set(value):
		if leader_id == value:
			return
		leader_id = value
		leader = Game.get_character_info(leader_id)
		hero_unit = Game.get_unit_type(leader_id)
		update_configuration_warnings()
		

@export_group("Territory")

@export var base_aggression: float

@export var home_territory: TerritoryButton:
	set(value):
		# remove the old connection
		if home_territory:
			home_territory.empire_node = null

		# nullify existing connections
		if value and value.empire_node:
			value.empire_node.home_territory = null

		home_territory = value

		# update new connection
		if home_territory:
			home_territory.empire_node = self
			
@export_group("Internal")

@export var leader: CharacterInfo

@export var hero_unit: UnitType


## Returns the empire this node refers to.
func get_empire() -> Empire:
	assert(not Engine.is_editor_hint(), "can't use in editor")
	return Game.overworld.get_empire_by_leader(leader)


func _get_configuration_warnings() -> PackedStringArray:
	if leader.get_meta('placeholder', false):
		return ['leader_id not found.']
	return []
	