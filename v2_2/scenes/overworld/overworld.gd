class_name Overworld
extends CanvasLayer


@export_subgroup("Internal")
@export var empires: Array[Empire] = []
@export var territories: Array[Territory] = []


func _ready():
	empires.clear()
	territories.clear()
	var empire_id := 0
	for empire in $Empires.get_children():
		assert(empire is Empire)
		empires.append(empire)
		empire.id = empire_id
		empire_id += 1
	
	var territory_id := 0
	for i in get_child_count():
		var button := get_child(i) as TerritoryButton
		if button:
			territories.append(button.territory)
			button.territory.id = territory_id
			territory_id += 1
			
	for empire in $RandomEmpireSelection.get_children():
		assert(empire is Empire)
		# TODO distribute random empires to territories
