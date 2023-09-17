extends Node

# Populated after Overworld._ready()
var empires: Array[Empire] = []

var territories: Array[Territory] = []
#var gods: Array[God] = []
var units: Array[Unit] = []
var hp_multiplier: float = 1.0

var battle: Battle = preload("res://Screens/Battle/Battle.tscn").instantiate()

const charas = {
	"Player" = preload("res://Screens/Battle/data/Chara_Lysandra.tres"),
	"Maia" = preload("res://Screens/Battle/data/Chara_Maia.tres"),
	"Zahra" = preload("res://Screens/Battle/data/Chara_Zahra.tres"),
	"Ishtar" = preload("res://Screens/Battle/data/Chara_Ishtar.tres"),
	"Alara" = preload("res://Screens/Battle/data/Chara_Alara.tres"),
	"Eirene" = preload("res://Screens/Battle/data/Chara_Eirene.tres"),
	"Sutekh" = preload("res://Screens/Battle/data/Chara_Sutekh.tres"),
	"Nyaraka" = preload("res://Screens/Battle/data/Chara_Nyaraka.tres"),
	"Tali" = preload("res://Screens/Battle/data/Chara_Tali.tres"),
	"Sitri" = preload("res://Screens/Battle/data/Chara_Sitri.tres"),
	"Hesra" = preload("res://Screens/Battle/data/Chara_Hesra.tres"),
	"Nebet" = preload("res://Screens/Battle/data/Chara_Nebet.tres"),
}

var prefs := {
	'defeat_if_home_territory_captured': true,
}

var chara := {}
var doodad_type := {}
var status_effect := {}
var unit_type := {}
var world := {}

var scene_queue: Array[String] = []

func _ready():
#	var dir := DirAccess.open("res://Screens/Battle/data/")
#	dir.list_dir_begin()
#	var filename := dir.get_next()
#	while filename != "":
#		if !dir.current_is_dir() and filename.begins_with("Chara_"):
#			var chara: Chara = load(filename)
#
#		filename = dir.get_next()

	#get_tree().root.add_child.call_deferred(battle)
	#print("battle added")
	pass
