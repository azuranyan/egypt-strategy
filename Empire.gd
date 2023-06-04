extends Node

class_name Empire

# Exposed properties
export var leader: String = ""
export var leader_unit: NodePath
export var territories: Array = []
export var adjacent_territories: Array = []
var Units : Array = []


# Internal properties
var home_territory

# Update adjacent territories when gaining a territory
func update_adjacent_territories() -> void:
	adjacent_territories.clear()
	
	for territory_path in territories:
		var territory = get_node(territory_path)
		if territory != null and territory is Territory:
			for adjacent_territory in territory.adjacent_territories:
				if adjacent_territory.empire_owner != self and !adjacent_territories.find(adjacent_territory) == -1:
					adjacent_territories.append(adjacent_territory)
	
	# Remove duplicate entries
	adjacent_territories = remove_duplicates(adjacent_territories)
	
# Remove duplicates from an array
func remove_duplicates(array: Array) -> Array:
	var unique_array = []
	
	for item in array:
		if !unique_array.includes(item):
			unique_array.append(item)
	
	return unique_array

# Check if a territory is adjacent to the empire
func is_territory_adjacent(territory: Territory) -> bool:
	return true if adjacent_territories.find(territory) != -1 else false

# Get units of all controlled territories
func get_controlled_units() -> Array:
	var controlled_units = []
	
	for territory_path in territories:
		var territory = get_node(territory_path)
		if territory != null and territory is Territory:
			controlled_units += territory.units
	
	return controlled_units

func has_been_beaten() -> bool:
	return territories.empty()
	
func win_territory(territory):
	territories.append(territory)
	territory.change_owner(leader)
	territory.owner_empire = self
	
func lose_territory(territory):
	territories.remove(territory)

# Initialization
func _ready() -> void:
	
	# Update adjacent territories on startup
	update_adjacent_territories()
