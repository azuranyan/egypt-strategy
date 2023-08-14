@tool
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

# TODO global space where all predefined data are accessible
@export_enum(
	# if adjusted, adjust everything with territory_names
	# grep territory_names
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
			if Engine.is_editor_hint():
				$Label.text = value
	
@export var mapscene: String

var _territory: Territory = null

func _ready():
	if Engine.is_editor_hint():
		print("[editor] ready: territory <%s> button" % territory)
	else:
		print("ready: territory <%s> button" % territory)
		_territory = Territory.get_territory(territory)
		$Label.text = territory
	
	# you can't do this here because we're initialized first before overworld
	# there should be a messagebus object or node that gets initialized before
	# everything else that gets loaded first
	# $Overworld.connect()

func _on_texture_button_toggled(button_pressed):
	var player_owned := _territory.owner.leader == God.Player
	if button_pressed:
		print("territory %s pressed" % territory)
		if player_owned:
			$ExtendedPlayerPanel.show()
		else:
			$ExtendedEnemyPanel.show()
			var adjacent: bool = Globals.empires[1].is_territory_adjacent(_territory)
			if adjacent:
				$ExtendedEnemyPanel/AttackButton.show()
			else:
				$ExtendedEnemyPanel/AttackButton.hide()
	else:
		print("territory %s released" % territory)
		$ExtendedPlayerPanel.hide()
		$ExtendedEnemyPanel.hide()
		
		
