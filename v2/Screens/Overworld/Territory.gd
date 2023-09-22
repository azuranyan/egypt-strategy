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

## List of unit names given to empire.
@export var units: PackedStringArray = []:
	set(value):
		units = value
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
			else:
				var validation_warnings := _validate_map_unit_list(instance)
				for ws in validation_warnings:
					warnings.append("Map %s: %s" % [i, ws])
			instance.free()
		else:
			warnings.append("Map %s is null" % i)
	
	return warnings


func _validate_map_unit_list(map: Map) -> PackedStringArray:
	var re := PackedStringArray()
	
	for name in map.get_spawn_units("ai"):
		match name:
			"*":
				pass
				
			_:
				if name not in units:
					re.append("spawn_unit '%s' not in units list" % name)
	
	return re
	

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
