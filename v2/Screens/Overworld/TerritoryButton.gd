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
			#if Engine.is_editor_hint():
			#	$Label.text = value
	
@export var mapscene: String

var _territory: Territory = null
var stored_z_index: int

func _ready():
	if Engine.is_editor_hint():
		print("[editor] ready: %s <%s> button" % [self, territory])
	else:
		print("ready: %s <%s> button" % [self, territory])
		_territory = Territory.get_territory(territory)
	$Label.text = territory
	
	# you can't do this here because we're initialized first before overworld
	# there should be a messagebus object or node that gets initialized before
	# everything else that gets loaded first
	# TODO we really shouldn't be messing with sibling nodes like this, so
	# maybe we can put the messagebus somewhere else
	$"../MessageBus".connect("territory_owner_changed", _on_owner_change)


func _on_owner_change(old_owner: Empire, new_owner: Empire, territory: Territory):
	if territory != _territory:
		return
		
	var image := Image.new()
	image.load(new_owner.leader.button_image)
	#image.generate_mipmaps()
	$TextureButton.texture_normal = ImageTexture.create_from_image(image)
	
	var mask := BitMap.new()
	mask.create_from_image_alpha(image)
	$TextureButton.texture_click_mask = mask
	
	
func _on_texture_button_toggled(button_pressed):
	var player_owned := self._territory.owner.leader == God.Player
	if button_pressed:
		print("territory %s pressed" % self.territory)
		# relative z ordering doesn't work when toggle is triggered via code trick
		# to hide the button again, try to fix later
		#self.z_index += 1
		if player_owned:
			$ExtendedPlayerPanel.show()
		else:
			$ExtendedEnemyPanel.show()
			var adjacent: bool = Globals.empires[1].is_territory_adjacent(self._territory)
			if adjacent:
				$ExtendedEnemyPanel/AttackButton.show()
			else:
				$ExtendedEnemyPanel/AttackButton.hide()
	else:
		print("territory %s released" % self.territory)
		#self.z_index -= 1
		$ExtendedPlayerPanel.hide()
		$ExtendedEnemyPanel.hide()
		
		
func _on_attack_button_pressed():
	# trick: toggle this button again to unpress, since we're in a buttongroup
	$TextureButton.emit_signal("toggled", false)
	
	# this button should appear only for player and therefore is
	# always the player empire triggering this
	$"../MessageBus".emit_signal("empire_attack", Globals.empires[1], _territory)
