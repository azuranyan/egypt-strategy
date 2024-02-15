@tool
class_name TerritoryNode
extends Node
## Serves as a marker for creating territories on the editor.

@export var adjacent: Array[TerritoryNode]
@export var maps: Array[PackedScene]:
	set(value):
		maps = value
		update_configuration_warnings()

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


func _ready():
	update_configuration_warnings()


## Returns the territory this node refers to.
func get_territory() -> Territory:
	assert(not Engine.is_editor_hint(), "can't use in editor")
	return Game.overworld.get_territory_by_name(name)
	
	
## Returns the unit entries.
func get_unit_entries() -> Dictionary:
	assert(not Engine.is_editor_hint(), "can't use in editor")
	var arr := {}
	for u in _unit_list:
		var split := u.rsplit(':', true, 1)
		var unit_name := split[0].strip_edges()
		var unit_count := split[1].to_int() if split.size() > 1 else 1
		arr[unit_name] = unit_count
	return arr


func _get_configuration_warnings() -> PackedStringArray:
	if maps.is_empty():
		return ['no maps assigned']
	return []
