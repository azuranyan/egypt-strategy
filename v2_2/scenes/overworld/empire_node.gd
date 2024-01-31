@tool
class_name EmpireNode
extends Node
## Serves as a marker for creating empires on the editor.

@export var type: Empire.Type = Empire.Type.RANDOM
@export var leader: CharacterInfo
@export var hero_unit: UnitType

@export_group("Territory")

@export var base_aggression: float

@export var home_territory_node: TerritoryNode:
	set(value):
		if home_territory_node == value:
			return
		if home_territory_node and home_territory_node.empire_node:
			home_territory_node.empire_node = null
		home_territory_node = value
		if home_territory_node and home_territory_node.empire_node != self:
			home_territory_node.empire_node = self
		notify_property_list_changed()

@export var unit: Unit

## Returns the empire this node refers to.
func get_empire(ctx: OverworldContext) -> Empire:
	return ctx.get_empire_by_leader(leader)
