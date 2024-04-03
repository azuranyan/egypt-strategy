class_name Empire
extends Resource


@export var leader: CharacterInfo

@export var territories: Array[Territory]
@export var base_aggression: float
@export var aggression: float
@export var hp_multiplier: float
@export var home_territory: Territory



## Returns true if empire is player owned.
func is_player_owned() -> bool:
	return (leader != null) and leader.get_meta('player_owned', false)


## Returns true if empire is player owned.
func leader_name() -> String:
	return leader.name if leader else ""
	
	
## Returns true if empire has territory.
func has_territory(territory: Territory) -> bool:
	return territory.empire == self
	

## Returns true if territory is adjacent.
func is_adjacent_territory(territory: Territory) -> bool:
	if has_territory(territory):
		return false
		
	for t in territories:
		for adj in t.adjacent:
			if (not has_territory(adj)) and (adj == territory):
				return true
				
	return false


## Returns true if the empire is beaten.
func is_beaten() -> bool:
	return territories.is_empty()
