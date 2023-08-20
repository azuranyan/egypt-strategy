extends Node

# Populated after Overworld._ready()
var empires: Array[Empire] = []

var territories: Array[Territory] = []
var gods: Array[God] = []
var units: Array[Unit] = []
var hp_multiplier: float = 1.0

var prefs := {
	'defeat_if_home_territory_captured': true,
}

var scene_queue: Array[String] = []

func _ready():
	pass
