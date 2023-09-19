extends Control

# Just the place to enter battle map scene, until we connect the whole game
# together

@export var map_scene: PackedScene


func register_objects():
	var dir := DirAccess.open("res://Screens/Battle/data/")
	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if !dir.current_is_dir() and filename.ends_with(".tres"):
			var res = load("res://Screens/Battle/data/" + filename)
			if res is Chara:
				Globals.chara[res.name] = res
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


func _on_button_pressed():
	#Globals.battle.load_map_scene(map_scene
	add_child(Globals.battle)
	
	register_objects()
	
	
	#Globals.battle.start_battle(Globals.empires[1], Globals.empires[2], Territory.Neru_Khisi)
