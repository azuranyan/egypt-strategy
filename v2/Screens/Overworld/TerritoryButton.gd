@tool
extends Button 

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

# TODO global space where all predefined data are accessible
@export_enum(
		"Zetennu",
		"Neru-Khisi",
		"Satayi",
		"Khel-Et",
		"Medjed's Beacon",
		"Fort Zaka",
		"Forsaken Temple",
		"Ruins of Atesh",
		"Nekhet's Rest",
		"Cursed Stronghold"
	) var territory: String:
		get:
			return territory
		set(value):
			territory = value
			$Label.text = value

@export var mapscene: String

var _territory: Territory = null

func _ready():
	print("ready: territory button")
	if Engine.is_editor_hint():
		pass
	else:
		_territory = Territory.get_territory(territory)
		$Label.text = territory
