extends Node2D

export(Globals.Gods) var FinalBoss = Globals.Gods.Sutekh

var locations = []
var Empires
var Gods
var current_turn = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	
	randomize()
	Gods = Globals.Gods.values()
	Gods.erase(FinalBoss)
	Gods.erase(Globals.Gods.Player)
	Gods.shuffle()
	Gods.append(Globals.Gods.Player)
	Gods.invert()
	Gods.append(FinalBoss)
	
	var Location_Group1 = [$Zetennu]
	var Location_Group2 = [$"Neru-Khisi"]
	var Location_Group3 = [$Satayi]
	var Location_Group4 = [$"Khel-Et",$ForsakenTemple]
	var Location_Group5 = [$"Medjed'sBeacon",$FortZaka]
	var Location_Group6 = [$"Nekhet'sRest",$RuinsOfAtesh]
	var Location_Group7 = [$CursedStronghold]
	var all_Location_Groups = [Location_Group1,Location_Group2,Location_Group3,Location_Group4,Location_Group5,Location_Group6,Location_Group7]
	
	var Player_Empire = $Player_Empire
	var AI_Empire_1 = $AI_Empire_1
	var AI_Empire_2 = $AI_Empire_2
	var AI_Empire_3 = $AI_Empire_3
	var AI_Empire_4 = $AI_Empire_4
	var AI_Empire_5 = $AI_Empire_5
	var BOSS_Empire = $BOSS_Empire
	
	Empires = [Player_Empire,AI_Empire_1,AI_Empire_2,AI_Empire_3,AI_Empire_4,AI_Empire_5,BOSS_Empire]
	
	for i in range(Gods.size()):
		Empires[i].leader = Gods[i]
	
	for i in range(Empires.size()):
		for each in all_Location_Groups[i]:
			Empires[i].win_territory(each)
			if(Empires[i].home_territory == null):
				Empires[i].home_territory = each
	
	
	$OverworldBattleManager.empires = [Player_Empire,AI_Empire_1,AI_Empire_2,AI_Empire_3,AI_Empire_4,AI_Empire_5]
	$OverworldBattleManager.start_turn()
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func check_entire_graph_for_attackable_nodes(owner):
	var graph = Globals.graph
	#locations
	var return_locations_vector = []
	for i in range(locations.size()):
		if(locations[i].get_owner() == owner):
			for each_node_int in graph[i]:
				if(locations[each_node_int].get_owner() == owner):
					pass
				else:
					return_locations_vector.append(locations[each_node_int])
	
	return return_locations_vector


func _on_Area_Klicked(location):
	pass # Replace with function body.


func _on_NeruKhisi_Area_Klicked(location):
	pass # Replace with function body.


func _on_Satayi_Area_Klicked(location):
	pass # Replace with function body.


func _on_KhelEt_Area_Klicked(location):
	pass # Replace with function body.


func _on_ForsakenTemple_Area_Klicked(location):
	pass # Replace with function body.
