class_name Territory
extends Resource


@export var adjacent: Array[Territory] = []
@export var maps: Array[PackedScene] = []
@export var empire: Empire


## Returns true if empire is player owned.
func is_player_owned() -> bool:
	return empire.is_player_owned()


## Returns the name of the leader.
func leader_name() -> String:
	return empire.leader_name()
