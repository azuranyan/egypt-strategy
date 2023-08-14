class_name Empire

var leader: God = null
var territories: Array[Territory] = []

func get_adjacent() -> Array[Territory]:
	var re: Array[Territory] = []
	var tmp: Array[int] = []
	# append everything
	for e in territories:
		tmp.append_array(e.adjacent)
	# add unique
	for i in tmp:
		if Territory.all[i] not in re:
			re.append(Territory.all[i])
	return re
	
func is_territory_adjacent(territory: Territory) -> bool:
	# terrible efficiency lol
	return territory in get_adjacent()

func get_controlled_units() -> Array[String]: # TODO array string for now until we make class
	var controlled_units: Array[String] = []
	for territory in territories:
		controlled_units.append_array(territory.units)
	return controlled_units
	
func is_beaten() -> bool:
	return territories.is_empty()
	

