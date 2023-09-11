extends Control

# Just the place to enter battle map scene, until we connect the whole game
# together

@export var map_scene: PackedScene

func _on_button_pressed():
	#Globals.battle.load_map_scene(map_scene
	add_child(Globals.battle)
	
	Globals.battle.start_battle(Globals.empires[1], Globals.empires[2], Territory.Neru_Khisi)
