extends Node
#var MENU_COLOR_BEIGE = Color(239/255,230/255,221/255,1.0)
var MENU_COLOR_BEIGE = Color(0.937, 0.902, 0.867)

enum Gods {Player,Sutekh,NykaraM,Maia,IshtarM,Eirene,Alara}
const Gods_Array = ["Player","Sutekh","NykaraM","Maia","IshtarM","Eirene","Alara"]

var Empire_Idle_Chance ={ # This is the chance that CPUs will Idle their turn.
	1:0.1, # Idle chance of the God inhabiting Neru-Khisi
	2:0.2,# Idle chance of Satayi starter God
	3:0.2,# Khel-Et & Forsaken Temple
	4:0.5,# Medjed'sBeacon and Fort Zaka 
	5:0.5,#  RuinsOfAtesh and Nekhet's Rest
	6:0.5 # 1.0 is always 0.0 is never
}

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
