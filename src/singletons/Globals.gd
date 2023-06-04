extends Node
#var MENU_COLOR_BEIGE = Color(239/255,230/255,221/255,1.0)
var MENU_COLOR_BEIGE = Color(0.937, 0.902, 0.867)
var FINAL_BOSS_GOD = Gods.Sitri
enum Gods {
	Player,
	Maia_and_Menna,
	Zahra,
	Ishtar,
	Alara,
	Sutekh,
	Eirene,
	Nykara,
	Tali,
	Sitri
	}
const Gods_Array = [
"Player",
"Maia and Menna",
"Zahra",
"Ishtar",
"Alara",
"Sutekh",
"Eirene",
"Nykara",
"Tali",
"Sitri"]

const GRID_DIM := 8
const TILE_W := 311.0
const TILE_W_HALF := TILE_W * 0.5
const TILE_H := 180.0
const TILE_H_HALF := TILE_H * 0.5
const TILE_NUM := 64

var graph = { 
	# These describe the connections to other nodes, 
	# the first node is Zetennu and it is connected to 2 which is Neru-Khisi
	# There is a list of locations that is defined in Overworld.gd that connects the numbers to locations, this needs to be done there.
	1: [2], # Zetennu
	2: [1, 3, 7], # Neru-Khisi
	3: [2, 4], # Satayo
	4: [3, 5], # Khel-Et
	5: [4, 6], # ForsakenTemple
	6: [5, 7, 9], # Medjed'sBeacon
	7: [2, 6, 8], # FortZaka
	8: [7], # Nekhet'sRest
	9: [6] # RuinsOfAtesh
}
