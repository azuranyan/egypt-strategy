@tool
class_name EmpireNode
extends Node
## Serves as a marker for creating empires on the editor.

@export var type: Empire.Type = Empire.Type.RANDOM

@export var leader_id: StringName:
	set(value):
		leader_id = value
		if not is_node_ready():
			await ready
		var dir := "res://units/".path_join(leader_id)
		leader = null
		hero_unit = null
		if leader_id and DirAccess.dir_exists_absolute(dir):
			leader = load(dir.path_join('chara.tres'))
			hero_unit = load(dir.path_join('unit_type.tres'))
		update_configuration_warnings()

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

@export_group("Internal")

@export var leader: CharacterInfo

@export var hero_unit: UnitType


## Returns the empire this node refers to.
func get_empire(ctx: OverworldContext) -> Empire:
	return ctx.get_empire_by_leader(leader)
	

func _get_configuration_warnings() -> PackedStringArray:
	var arr: PackedStringArray
	if not leader:
		arr.append('cannot find leader chara.tres')
	if not hero_unit:
		arr.append('cannot find leader unit_type.tres')
	return arr
