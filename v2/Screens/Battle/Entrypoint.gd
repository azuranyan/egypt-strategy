extends Control

# Just the place to enter battle map scene, until we connect the whole game
# together

@export var map_scene: PackedScene


@onready var label_attacker := $VBoxContainer/HBoxContainer/OptionButton
@onready var label_defender := $VBoxContainer/HBoxContainer/OptionButton2
@onready var label_territory := $VBoxContainer/HBoxContainer2/OptionButton3


func _ready():
	# Overworld starts before us and registers the empires and territories
	register_objects()
	register_maps()
	
	var post_ready := func():
		for empire in Globals.empires.values():
			if empire.is_player_owned():
				label_attacker.add_item(empire.leader.name)
			else:
				if empire.leader.get_meta("territory_selection", false):
					label_defender.add_item(empire.leader.name)
				
		for territory in Globals.territories.values():
			if not territory.maps.is_empty():
				label_territory.add_item(territory.name)
#		for map in Globals.maps.values():
#			label_territory.add_item(map.scene_file_path if map.scene_file_path != "" else map.name)
	
	# TODO overworld is waiting for us to finish, but the functions here require
	# overworld to have run. this is ugly and should be changed.
	post_ready.call_deferred()
	

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
				Globals.status_effect[res.short_name] = res
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
	var attacker: Empire = Globals.empires[label_attacker.get_item_text(label_attacker.get_selectable_item())]
	var defender: Empire = Globals.empires[label_defender.get_item_text(label_defender.get_selectable_item())]
	var territory: Territory = Globals.territories[label_territory.get_item_text(label_territory.get_selectable_item())]
	Globals.battle.start_battle(attacker, defender, territory)
#	Globals.battle.start_battle(Globals.empires["Lysandra"], Globals.empires["Lysandra"], Globals.territories["Neru-Khisi"])
