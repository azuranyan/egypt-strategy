class_name Empire

var leader: Chara = null
var territories: Array[Territory] = []
var base_aggression: float
var aggression: float = base_aggression
var hp_multiplier: float = 1.0
var home_territory: Territory = null

var units: Array[String] = []

func _init():
	base_aggression = randf()/2
	

## Internal function to build the initial unit list.
func build_unit_list():
	for t in territories:
		pass
		

## Returns all the adjacent territories.
func get_adjacent() -> Array[Territory]:
	var re: Array[Territory] = []
	var tmp: Array[Territory] = []
	
	# append all adjacent territories
	for t in territories:
		tmp.append_array(t.adjacent)
		
	# only append unique and not self owned
	for t in tmp:
		if (t not in re) and (t.empire != self):
			re.append(t)
	
	return re


## Returns true if player owned.
func is_player_owned() -> bool:
	return leader.get_meta("player", false)
	
	
## Returns true if territory is adjacent.
func is_territory_adjacent(territory: Territory) -> bool:
	if territory.empire == self:
		return false
		
	for t in territories:
		for adj in t.adjacent:
			if adj == territory:
				return true
				
	return false

	
## Returns true if the empire is beaten.
func is_beaten() -> bool:
	return territories.is_empty()
	

