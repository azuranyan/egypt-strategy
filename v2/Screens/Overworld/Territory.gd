@tool
extends Node

## Territory object that's also a component.
class_name Territory


## List of adjacent territories.
@export var adjacent: Array[Territory] = []

## List of map levels. [0] is the default level.
@export var maps: Array[PackedScene] = []:
	set(value):
		maps = value
		update_configuration_warnings()


## The empire this territory belongs to.
var empire: Empire


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if maps.is_empty():
		warnings.append("level (Map) is empty")
	
	for i in range(maps.size()):
		var ps := maps[i]
		if ps:
			var instance := ps.instantiate()
			if not instance is Map:
				warnings.append("%s is not a Map" % instance.name)
			instance.free()
		else:
			warnings.append("Map %s is null" % i)
	
	return warnings


## Returns a list of unit names that should be spawned.
func get_spawn_units(level: int = 0) -> PackedStringArray:
	return PackedStringArray()


## Returns true if player owned.
func is_player_owned() -> bool:
	return empire and empire.is_player_owned()
	
	
## Returns the leader if present.
func get_leader() -> Chara:
	return empire.leader if empire else null


## Returns a simple string describing the strength of occupying forces.
func get_force_strength() -> String:
	# TODO put in empire?
	# TODO get all spawn units -> unit instance and get their combined current hp * multiplier
	if empire == null:
		return ""
	elif empire.hp_multiplier <= 0.1:
		return "Critical"
	elif empire.hp_multiplier <= 0.3:
		return "Low"
	elif empire.hp_multiplier <= 0.6:
		return "Hurt"
	elif empire.hp_multiplier == 1.0:
		return "Full"
	else:
		return "Good"
		
		
## Returns true if this territory is the home territory.
func is_home_territory() -> bool:
	return empire and empire.home_territory == self