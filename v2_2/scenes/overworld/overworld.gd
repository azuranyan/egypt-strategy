class_name Overworld
extends CanvasLayer

# Unlike battle, overworld is kept in memory.

var empires := []
var territories := []


func _ready():
	for empire in $Empires.get_children():
		assert(empire is Empire)
		empires.append(empire)
	
	for child in get_children():
		if child is TerritoryButton:
			territories.append(child)


