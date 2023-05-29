extends Control

export var LocationName = "LocationName"
export(Globals.Gods) var Owner = Globals.Gods.Alara
var home_turf_units = []
var owner_empire
export var adjacent_territories = []

signal Area_Klicked(location)
func I_have_been_klicked():
	emit_signal("Area_Klicked",self)
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	set_owner(Owner)
	$LocationNameBox/LocationName.text = LocationName
	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func get_owner():
	return Owner 
	
func set_owner(new_owner_enum_number):
	var new_owner = Globals.Gods_Array[new_owner_enum_number]
	$CharacterImage.play(new_owner)
