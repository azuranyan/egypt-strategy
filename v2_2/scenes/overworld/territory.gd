class_name Territory
extends Resource


## The name of this territory.
@export var name: StringName

## Names of adjacent territories.
@export var adjacent: Array[StringName] = []

## List of [Map] to load in-battle.
@export var maps: Array[PackedScene] = []

## Dictionary of unit names and count.
@export var units: Dictionary


## Returns true if another territory is adjacent.
func is_adjacent(other: Territory) -> bool:
	return other.name in adjacent
	
	
