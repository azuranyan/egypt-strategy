@tool
class_name TerritoryNode
extends Node
## Serves as a marker for creating territories on the editor.

@export var adjacent: Array[TerritoryNode]
@export var maps: Array[PackedScene]

## Unit names. Count is optional by doing [code]name:count[/code].
@export var _unit_list: PackedStringArray

@export_group("Empire")

@export var empire_node: EmpireNode:
	set(value):
		if empire_node == value:
			return
		if empire_node and empire_node.home_territory_node:
			empire_node.home_territory_node = null
		empire_node = value
		if empire_node and empire_node.home_territory_node != self:
			empire_node.home_territory_node = self
		notify_property_list_changed()


## Returns the territory this node refers to.
func get_territory(ctx: OverworldContext) -> Territory:
	return ctx.get_territory_by_name(name)
	
	
## Returns the unit entries.
func get_unit_entries() -> Dictionary:
	var arr := {}
	for u in _unit_list:
		var split := u.rsplit(':', true, 1)
		var unit_name := split[0].strip_edges()
		var unit_count := split[1].to_int() if split.size() > 1 else 1
		arr[unit_name] = unit_count
	return arr
