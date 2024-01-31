class_name Empire
extends Resource

enum Type {
	RANDOM,
	PLAYER,
	BOSS,
}

## The type of empire.
@export var type: Type = Type.RANDOM

## The leader character.
@export var leader: CharacterInfo

## The type of unit spawned as this empire's unique unit.
@export var hero_unit: UnitType

@export_group("Territory")

## This empire's home territory.
@export var home_territory: Territory

## This empires base aggression.
@export var base_aggression: float

@export_group("State")

## The list of territories owned by this empire.
@export var territories: Array[Territory]

## The list of units this empire owns.
@export var units: Array[Unit]

## This empires current level of aggression.
@export var aggression: float

## How much hp units have when battling.
@export var hp_multiplier: float = 1


## Kind of a hack to make everything simpler.
var _territories: WeakRef


## Returns true if empire is player owned.
func is_player_owned() -> bool:
	return type == Type.PLAYER


## Returns true if empire is boss.
func is_boss() -> bool:
	return type == Type.BOSS
	

## Returns true if empire is a random assigned empire.
func is_random() -> bool:
	return type == Type.RANDOM
	
	
## Returns true if empire is player owned.
func leader_name() -> String:
	return leader.name if leader else ""
	
	
## Returns true if empire has territory.
func has_territory(territory: Territory) -> bool:
	return territory in territories
	

## Returns true if territory is adjacent.
func is_adjacent_territory(territory: Territory) -> bool:
	if has_territory(territory):
		return false
		
	for t in territories:
		if t.is_adjacent(territory):
			return true
	return false


## Returns an array of adjacent territories.
func get_adjacent() -> Array[Territory]:
	return _territories.filter(is_adjacent_territory)


## Returns true if the empire is is_defeated.
func is_defeated() -> bool:
	return territories.is_empty()
