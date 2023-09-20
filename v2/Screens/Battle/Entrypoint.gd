extends Control

# Just the place to enter battle map scene, until we connect the whole game
# together

@export var map_scene: PackedScene


@onready var label_attacker := $VBoxContainer/HBoxContainer/OptionButton
@onready var label_defender := $VBoxContainer/HBoxContainer/OptionButton2
@onready var label_territory := $VBoxContainer/HBoxContainer2/OptionButton3


func _ready():
	register_objects()
	register_maps()
	
	
	for empire in Globals.empires.values():
		if empire.is_player_owned():
			label_attacker.add_item(empire.leader.name)
		else:
			label_defender.add_item(empire.leader.name)
			
	for map in Globals.maps.values():
		label_territory.add_item(map.scene_file_path if map.scene_file_path != "" else map.name)
	

func register_maps():
	Globals.maps["Starting Zone"] = preload("res://Screens/Battle/maps/StartingZone.tscn").instantiate()
	
	
func register_objects():
	var dir := DirAccess.open("res://Screens/Battle/data/")
	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if !dir.current_is_dir() and filename.ends_with(".tres"):
			var res = load("res://Screens/Battle/data/" + filename)
			if res is Chara:
				#Globals.chara[res.name] = res
				pass 
			elif res is DoodadType:
				Globals.doodad_type[res.resource_name] = res
			elif res is StatusEffect:
				Globals.status_effect[res.name] = res
			elif res is UnitType:
				Globals.unit_type[res.chara.name] = res
			elif res is World:
				Globals.world[res.resource_name] = res
			else:
				print("unrecognized resource file %s" % filename)
		filename = dir.get_next()
	
	Globals.chara = Globals.charas.duplicate()
	

func _on_button_pressed():
	add_child(Globals.battle)
	
	# TODO when starting battle, close all overworld interactions
	
	Globals.battle.start_battle(Globals.empires["Lysandra"], Globals.empires["Lysandra"], Globals.territories["Neru-Khisi"])
