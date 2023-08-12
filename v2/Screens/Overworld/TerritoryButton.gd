extends Node

# Editable from the interface are:
# 	territory name
# 	territory map
# 
# Fixed properties are
# 	territory names
# 	adjacency graph
#
# Per instance are
# 	owner
# 	pos
#	portrait


@export var territory_name: String:
	get:
		return territory_name
	set(value):
		_territory = Territory.new(value, "")
		territory_name = _territory.name
		$Label.text = territory_name
		
@export var territory_mapscene: String
		

var _territory: Territory = null

func _ready():
	print("ready: territorybutton " + territory_name)
