class_name Empire

var leader: God = null
var territories: Array[Territory] = []
var base_aggression: float = 0.5 # this might have to be a God stat
var aggression: float = base_aggression
var hp_multiplier: float = 1.0
var home_territory: Territory = null

func _init():
	base_aggression = randf()/2
	
func get_adjacent() -> Array[Territory]:
	var re: Array[Territory] = []
	var tmp: Array[int] = []
	
	# append everything
	for e in territories:
		tmp.append_array(e.adjacent)
		
#	# add unique
#	for i in tmp:
#		if Territory.all[i] not in re and:
#			re.append(Territory.all[i])

	# add unique and not self owned
	for idx in tmp:
		var t: Territory = Territory.all[idx]
		if (t not in re) and (t.owner != self):
			re.append(t)
	
	return re

func is_player_owned() -> bool:
	return leader == God.Player
	
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
	

