@tool
class_name Territory
extends Node


signal state_loaded


@export var territory_name: String
@export var adjacent: Array[Territory] = []
@export var maps: Array[PackedScene] = []
@export var empire: Empire:
	set(value):
		empire = value
		if empire and Engine.is_editor_hint():
			empire.territories.clear()
			empire.territories.append(self)
			empire.home_territory = self
		
var id: int


## Returns true if empire is player owned.
func is_player_owned() -> bool:
	return empire.is_player_owned()


## Returns true if empire is boss.
func is_boss() -> bool:
	return empire.is_boss()
	
	
## Returns the name of the leader.
func leader_name() -> String:
	return empire.leader_name()


