@tool
extends Node 

# TODO add icon if home territory

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
	OverworldEvents.connect("territory_owner_changed", _on_owner_change)
	
	OverworldEvents.connect("cycle_turn_start", _on_cycle_turn_start)
	
	OverworldEvents.connect("cycle_turn_end", _on_cycle_turn_end)


func _get_button_image(chara: Chara) -> Image:
	var image := Image.new()
	image.load("res://Screens/Overworld/ButtonImage/%s.png" % chara.name)
	#image.generate_mipmaps()
	return image
	
func _on_owner_change(old_owner: Empire, new_owner: Empire, territory: Territory):
	# everyone is subscribed to the event so we only proceed
	# if this event is actually about our territory
	if territory != _territory:
		return
	
	var image := _get_button_image(new_owner.leader)
	$TextureButton.texture_normal = ImageTexture.create_from_image(image)
	
	var mask := BitMap.new()
	mask.create_from_image_alpha(image)
	$TextureButton.texture_click_mask = mask
	
	if territory.is_player_owned():
		pass
	else:
		$ExtendedEnemyPanel/LeaderLabel.text = "Enemy Leader: %s" % new_owner.leader.name
		$ExtendedEnemyPanel/ForceLabel.text = "Force Strength: %s" % territory.get_force_strength()


func show_extended_enemy_panel(show_attack: bool):
	# no need to do hide the other panel, it's only there for formality
	$ExtendedEnemyPanel.show()
	$ExtendedPlayerPanel.hide() 
	if show_attack:
		$ExtendedEnemyPanel/Background1.hide()
		$ExtendedEnemyPanel/Background2.show()
		$ExtendedEnemyPanel/AttackButton.show()
	else:
		$ExtendedEnemyPanel/Background1.show()
		$ExtendedEnemyPanel/Background2.hide()
		$ExtendedEnemyPanel/AttackButton.hide()
		
	if _territory.owner.home_territory == _territory:
		$ExtendedEnemyPanel/Home.show()
	else:
		$ExtendedEnemyPanel/Home.hide()


func show_extended_player_panel():
	# no need to do hide the other panel, it's only there for formality
	$ExtendedEnemyPanel.hide()
	$ExtendedPlayerPanel.show()
	
	
func hide_extended_panel():
	$ExtendedPlayerPanel.hide()
	$ExtendedEnemyPanel.hide()


func _on_texture_button_toggled(button_pressed):
	var player_owned := self._territory.owner.is_player_owned()
	if button_pressed:
		# raise z so it is over all other buttons
		self.z_index += 1
		if player_owned:
			show_extended_player_panel()
		else:
			var adjacent: bool = Globals.empires[1].is_territory_adjacent(self._territory)
			show_extended_enemy_panel(adjacent)
	else:
		self.z_index -= 1
		hide_extended_panel()
		
		
func _on_attack_button_pressed():
	$TextureButton.button_pressed = false
	
	# this button should appear only for player and therefore is
	# always the player empire triggering this
	OverworldEvents.emit_signal("empire_attack", Globals.empires[1], _territory)
	OverworldEvents.emit_signal("cycle_turn_end", Globals.empires[1])


func _on_inspect_button_pressed():
	OverworldEvents.emit_signal("inspect")


func _on_rest_button_pressed():
	OverworldEvents.emit_signal("rest")


func _on_train_button_pressed():
	OverworldEvents.emit_signal("train")
	
	
func _on_cycle_turn_start(empire: Empire):
	if empire == _territory.owner:
		$ColorRect.show()
	else:
		$ColorRect.hide()
	
func _on_cycle_turn_end(empire: Empire):
	# hides all panels
	hide_extended_panel()
