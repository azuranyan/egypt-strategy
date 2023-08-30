class_name EGMap

## The battle map
var battlemap: String

## List of triggers
var triggers: Array[String]

## List of objectives
var objectives: Array[String]

## Record of all entities in the map
var entities := {
	"units": [],
	"doodads": [],
	"cameras": [],
	"projectiles": [],
	"emitters": [],
}

## List of players and alliances
var players: Array[String]
